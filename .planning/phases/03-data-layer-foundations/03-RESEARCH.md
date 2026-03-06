# Phase 3 Research: Data Layer Foundations

**Date:** 2026-03-05  
**Phase:** 03-data-layer-foundations  
**Objective:** What the planner must know to plan this phase well

## 1. Scope and Fixed Boundaries

Phase 3 is infrastructure-only. It must implement persistence and consent gating needed by downstream phases, without expanding into UI, escalation policy behavior, or scheduling logic.

In-scope (must satisfy now):
- `ConsentStore.save/loadCurrent/revoke` persistence in App Group-backed `UserDefaults` (DATA-01, DATA-02)
- `DeviceActivityMonitorExtension` consent gate wired to real persisted consent state (DATA-02)
- `PolicyRepository` persistence for `EscalationLevel` + `BypassEvent` via `JSONEncoder` in App Group `UserDefaults` (DATA-03)
- New `FamilyActivitySelectionStore` in `PolicyStore` for selected platform tokens
- `AuditLog` persistence to `UserDefaults` encoded array (decision already locked in context)

Out-of-scope (explicitly deferred):
- Escalation progression logic (`cooldown1/cooldown2/lockdown`) behavior changes (v1.2)
- DeviceActivityReport extension and dashboard integrations
- Onboarding UI wiring beyond persistence contract

## 2. Locked Decisions (Do Not Re-decide)

From `03-CONTEXT.md` and `STATE.md`:
- `FamilyActivitySelectionStore` lives in `PolicyStore`
- `ConsentStore.loadCurrent()` returns last record even if revoked; callers use `?.isRevoked == false`
- `ConsentStore.revoke()` mutates existing record: `isRevoked = true`, `revokedAt = Date()`, then persists
- `AuditLog` uses App Group `UserDefaults` + JSON-encoded array (not file append)
- `BypassEvent` schema is unchanged (`id`, `occurredAt`, `escalationLevelAtTime`)
- App Group fallback pattern is already established: `assertionFailure` + `.standard`
- `AppGroup.suiteName` in `PolicyStore` remains the only Swift source of truth for app group identifier

## 3. Current Code Reality (Implementation Starting Point)

Implemented stubs today:
- `ConsentStore` has `suiteName` injection and fallback wiring, but methods are stubbed
- `PolicyRepository` has fallback wiring, but all persistence methods are stubbed
- `AuditLog.append` is stubbed
- `DeviceActivityMonitorExtension` still uses `let consentIsGranted = true`
- No `FamilyActivitySelectionStore` type exists yet

Code-level integration constraint discovered:
- `DeviceActivityMonitor` target currently depends on `PolicyStore` only in `project.pbxproj`; it does **not** include `ConsentManager` package product dependency yet.
- To use `ConsentStore` in extension code, Phase 3 must add `ConsentManager` to that target's package dependencies/frameworks.

## 4. Requirement-to-Implementation Mapping

### DATA-01 — Consent status persisted cross-process
Need:
- JSON encode/decode `ConsentRecord` in `ConsentStore`
- Stable namespaced key(s)
- Use provided `suiteName` at call sites (`AppGroup.suiteName` in production)
- Read/write semantics must be extension-compatible (shared `UserDefaults` suite)

### DATA-02 — Revocation blocks bypass telemetry writes
Need:
- `revoke()` sets revoked state on current record and persists
- `DeviceActivityMonitorExtension.eventDidReachThreshold` checks:
  - `ConsentStore(suiteName: AppGroup.suiteName).loadCurrent()?.isRevoked == false`
  - guard-return before `recordBypassEvent` when revoked or missing

### DATA-03 — Policy persistence for escalation + bypass events
Need:
- Persist current escalation level in `PolicyRepository`
- Persist appendable array of `BypassEvent` in `PolicyRepository`
- Encode/decode with `JSONEncoder`/`JSONDecoder`
- Return `.baseline` on missing/corrupt state (non-crashing fallback)
- Ensure behavior is testable via `swift test` on macOS

## 5. FamilyActivitySelectionStore Research Findings

Placement and coupling:
- Must be in `PolicyStore` (already decided), because it is shared persistence used by app flow and ScreenTime pipeline.

API shape needed for downstream phases:
- Store/load/clear selection
- Contract should be minimal and persistence-focused (no scheduling logic)

Platform compatibility risk:
- `FamilyActivitySelection` and token types come from `FamilyControls`.
- `PolicyStore` package tests currently run on macOS; introducing unconditional `import FamilyControls` can break mac-hosted package workflows.
- Planning should explicitly choose one compatibility strategy:
  1. `#if canImport(FamilyControls)`-guarded implementation with fallback no-op/placeholder types for non-import environments, or
  2. isolate FamilyControls-dependent code to iOS-only files while preserving package compilation/tests on macOS.

## 6. Testing Reality and Planning Implications

Observed baseline (2026-03-05):
- `swift test` passes for both `ios/Packages/PolicyStore` and `ios/Packages/ConsentManager` on macOS, with UAT stubs skipped.

What planner should include in Phase 3 plans:
- Replace/augment package tests with concrete persistence assertions for Phase 3 behaviors (at least DATA-01/02/03 coverage)
- Keep tests deterministic by clearing relevant `UserDefaults` keys/suites in setup/teardown
- Add extension-facing integration test strategy at app target level where package tests cannot validate real extension process behavior

Important nuance:
- True entitlement-backed cross-process validation is best exercised in simulator integration (`xcodebuild test` app scheme), not only package-level `swift test`.

## 7. Key Risks and Mitigations

1. **Extension dependency gap** (`DeviceActivityMonitor` missing `ConsentManager` dependency)
- Mitigation: include explicit pbxproj dependency update task early in phase.

2. **FamilyControls type availability in SPM/macOS test runs**
- Mitigation: plan compile-guard strategy before implementing `FamilyActivitySelectionStore`.

3. **Corrupt/missing persisted JSON causing runtime regressions**
- Mitigation: decode defensively; fallback to safe defaults (`nil` consent, `.baseline`, empty events/log).

4. **State leakage between tests through shared defaults keys**
- Mitigation: namespaced keys + explicit cleanup helper in tests.

5. **Accidental architecture violation (ConsentManager importing PolicyStore)**
- Mitigation: keep `ConsentStore` suite injection pattern; wire `AppGroup.suiteName` only at call sites outside ConsentManager.

## 8. Recommended Plan Slices

A plan that is likely to execute cleanly should separate concerns:

1. **Persistence Core (Consent + Policy + Audit)**
- Implement `ConsentStore`, `PolicyRepository`, `AuditLog` persistence and key constants.

2. **Selection Store**
- Add `FamilyActivitySelectionStore` with chosen `FamilyControls` compatibility approach.

3. **Extension Integration**
- Add `ConsentManager` dependency to `DeviceActivityMonitor` target.
- Replace consent gate stub with real revoked-state check.

4. **Tests and Verification**
- Add/replace tests for DATA-01/02/03 in package targets and scheme-level verification commands.

## 9. Verification Checklist for Planner

Planner should require all of the following evidence in execution plans:
- `ConsentStore.save/loadCurrent/revoke` tested with revoked/non-revoked semantics
- `DeviceActivityMonitorExtension` path confirmed to no-op telemetry write when consent revoked
- `PolicyRepository` reads/writes escalation + bypass events via encoded payloads
- `FamilyActivitySelectionStore` round-trip persistence demonstrated
- `swift test` for touched packages passes on macOS
- `xcodebuild test` on `iPhone 17 / iOS 26.2` passes for project scheme

## 10. Inputs Reviewed

Required files:
- `.planning/phases/03-data-layer-foundations/03-CONTEXT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`

Additional context reviewed:
- `CLAUDE.md`
- Relevant code in:
  - `ios/Packages/ConsentManager/*`
  - `ios/Packages/PolicyStore/*`
  - `ios/Extensions/DeviceActivityMonitor/DeviceActivityMonitorExtension.swift`
  - `ios/FreeSocial.xcodeproj/project.pbxproj`
- Skill directories check:
  - `.claude/skills/` not present
  - `.agents/skills/` not present
