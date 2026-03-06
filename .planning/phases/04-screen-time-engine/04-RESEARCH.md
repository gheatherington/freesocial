# Phase 4 Research: Screen Time Engine

**Date:** 2026-03-05  
**Phase:** 04-screen-time-engine  
**Objective:** What must be true to plan and execute ENFC-01 reliably

## Scope and Phase Boundaries

Phase 4 must deliver enforcement infrastructure, not onboarding UI polish and not feed UX.

In scope (must satisfy now):
- `ENFC-01`: native Instagram/TikTok blocking via Screen Time shield when limit is reached
- Real implementation of `AuthorizationManager`, `ActivityScheduler`, `ShieldManager`
- Extension callback wiring in `DeviceActivityMonitorExtension` to apply/clear shields
- Deauthorization cleanup chain required by roadmap success criteria (`clearAllSettings`)
- Defensive usage guard for iOS 26.2 premature `eventDidReachThreshold`

Out of scope (defer):
- Escalation policy transitions (`ENFC-02`, v1.2)
- Full recovery UI flows (Phase 6 onboarding/settings UX)
- DeviceActivityReport dashboard work (Phase 7)

## Current Code Reality

Starting point in repo:
- `AuthorizationManager.requestAuthorization()` is a stub
- `ActivityScheduler.scheduleActivity(name:schedule:)` is a stub with placeholder signature
- `ShieldManager.shieldApps(_:)` is a stub using `Set<String>`
- `DeviceActivityMonitorExtension.intervalDidStart/intervalDidEnd` are stubs
- `DeviceActivityMonitorExtension.eventDidReachThreshold` currently records bypass telemetry (DATA-02 already wired)
- `FamilyActivitySelectionStore` exists in `PolicyStore` and already persists `FamilyActivitySelection`

Implication for planning:
- Phase 4 is mostly API-shape correction and cross-target wiring, not net-new architecture.

## Requirement Mapping (ENFC-01)

To satisfy `ENFC-01`, the concrete runtime chain must exist:
1. User-authorized app tokens are persisted (`FamilyActivitySelectionStore`).
2. `ActivityScheduler` registers repeating daily monitoring with threshold event(s).
3. Threshold callback is delivered to `DeviceActivityMonitorExtension`.
4. Extension applies shields using `ManagedSettingsStore` for selected app tokens.
5. Native Instagram/TikTok becomes unavailable via system shield.

If any link is missing, ENFC-01 is not met.

## Standard Stack

Use only this stack for Phase 4:
- `FamilyControls`
- `DeviceActivity`
- `ManagedSettings`
- Existing modules: `PolicyStore`, `ConsentManager`

Primary APIs to plan around:
- `AuthorizationCenter.shared.requestAuthorization(for: .individual)`
- `AuthorizationCenter.shared.$authorizationStatus` (deauthorization observer)
- `DeviceActivityCenter.startMonitoring(_:during:events:)`
- `DeviceActivitySchedule(intervalStart:intervalEnd:repeats:)`
- `DeviceActivityEvent` with threshold `DateComponents`
- `ManagedSettingsStore(named:)` + `shield.applications`
- `ManagedSettingsStore().clearAllSettings()` for deauthorization cleanup

## Architecture Patterns

### 1) Main App Owns Scheduling and Authorization
- Authorization requests only from main app process.
- `ActivityScheduler` starts/stops monitoring only from main app.
- Extensions react to callbacks; they do not schedule.

### 2) App Group as Shared Control Plane
- Token selection comes from `FamilyActivitySelectionStore` in App Group storage.
- Continue using `AppGroup.suiteName` as single source of truth.

### 3) Named Store Consistency
- Define one shared store/activity namespace (example: `freesocial.daily`).
- Use the same logical name across scheduler and shield application code.

### 4) Defensive Threshold Handling
- Keep `eventDidReachThreshold` as trigger, not sole truth.
- Add minimum-elapsed-usage/time guard to suppress iOS 26.2 premature callbacks.

## Concrete Implementation Guidance

### AuthorizationManager
Plan for these responsibilities:
- `requestAuthorization()` calls FamilyControls async API.
- Expose current status (`approved/denied/notDetermined`) for app flow.
- Subscribe to status changes and invoke cleanup when deauthorized:
  - `ManagedSettingsStore().clearAllSettings()`
  - stop active monitoring (`ActivityScheduler.stopAllMonitoring()` equivalent)

Planning note:
- Keep FamilyControls imports guarded (`#if canImport(FamilyControls)`) in package code.

### ActivityScheduler
Current method signature is too abstract. Plan to replace with domain-specific API, e.g.:
- `startMonitoring(dailyLimitMinutes:) throws`
- `stopMonitoring()`

Implementation requirements:
- Validate input bounds (non-zero, sane upper limit).
- Build daily repeating schedule with time-only `DateComponents`.
- Register threshold event tied to selected application tokens from `FamilyActivitySelectionStore`.
- Ensure idempotent restart behavior (stop existing before start to avoid collisions).

### ShieldManager
Current `Set<String>` contract must be replaced with token-based API.
Plan to expose:
- `applyShield(to applicationTokens: Set<ApplicationToken>)`
- `clearShield()`

Implementation requirements:
- Use `ManagedSettingsStore` API directly.
- Handle empty token set as no-op with explicit log path (don’t silently “succeed”).

### DeviceActivityMonitorExtension
Planned behavior per callback:
- `intervalDidStart`: clear stale shields at start-of-day boundary.
- `eventDidReachThreshold`:
  - retain existing consent gate (`shouldRecordBypassEvent`)
  - apply usage/time guard for iOS 26.2 regression
  - apply shields for persisted selected tokens
  - record bypass event only if consent active (already done)
- `intervalDidEnd`: clear shields for next cycle (or keep if policy requires; pick one and test it)

## Don’t Hand-Roll

Avoid custom replacements for system primitives:
- Do not build custom app-blocking overlays; use `ManagedSettings` shields only.
- Do not build custom usage tracking to replace `DeviceActivity` for ENFC-01 gating.
- Do not bypass `FamilyActivitySelection` by persisting ad-hoc token strings.

## Common Pitfalls

1. Authorization requested from extension process.
- Result: sheet never appears / runtime failure.
- Mitigation: request only from main app flow.

2. iOS 26.2 premature `eventDidReachThreshold` firing.
- Result: immediate shielding at session start.
- Mitigation: enforce elapsed-usage/time guard before shield application.

3. Invalid `DeviceActivitySchedule` components.
- Result: callback never fires or monitoring fails.
- Mitigation: use time components only and validate before start.

4. Deauthorization leaves stale shields active.
- Result: user remains blocked after revocation.
- Mitigation: immediate `clearAllSettings()` + stop monitoring on deauth.

5. Name collisions in monitoring activities.
- Result: previous monitoring unexpectedly replaced.
- Mitigation: centralize names/constants and keep count minimal.

6. Simulator callback nondeterminism.
- Result: flaky enforcement tests.
- Mitigation: unit-test pure logic and run callback-dependent checks as integration/manual evidence.

## Test Strategy

Plan tests in 3 layers:

### A) Package Unit Tests (`ScreenTimeEngineTests`)
- Authorization manager status mapping and deauth cleanup trigger using protocol/mocked wrappers.
- Scheduler validation tests (invalid limits, invalid schedule config, idempotent restart behavior).
- Shield manager tests via wrapper protocol (`set shield`, `clear shield`).

### B) App/Extension Boundary Tests (`FreeSocialTests`)
- Extend current consent-gate pattern with threshold-guard tests (premature callback blocked).
- Verify extension helper chooses apply-vs-skip behavior based on:
  - no selection
  - revoked consent
  - active consent + valid elapsed usage

### C) Simulator Integration (`xcodebuild test`)
- Build/test all targets on `iPhone 17 / iOS 26.2`.
- Verify no skipped tests for newly implemented ENFC-01 paths.
- Keep callback timing assertions coarse (avoid brittle exact timing).

## Validation Architecture

Validation must prove the full enforcement chain, not isolated methods.

### Validation Layers
1. Static/compile validation
- `ScreenTimeEngine` compiles with guarded imports.
- Extension targets compile with token-based APIs.

2. Deterministic logic validation
- Pure helper tests for status transitions, threshold guard, and token presence decisions.

3. Cross-target contract validation
- App writes selection/schedule state; extension reads and applies shield path.
- Confirm no architecture violations (`ConsentManager` still independent; `AppGroup.suiteName` reused).

4. Runtime integration validation
- `xcodebuild test` passes on simulator target.
- Manual verification checklist captures known simulator limitations and expected evidence.

### Evidence Matrix (what plan tasks should produce)
- API evidence: concrete methods implemented in `AuthorizationManager`, `ActivityScheduler`, `ShieldManager`.
- Callback evidence: `DeviceActivityMonitorExtension` applies/clears shields with guard.
- Safety evidence: deauthorization cleanup path clears settings.
- Requirement evidence: ENFC-01 trace from token selection -> schedule -> threshold callback -> shield.

## Recommended Plan Slices

1. `04-01`: AuthorizationManager real implementation + deauthorization cleanup path.
2. `04-02`: ActivityScheduler API redesign + schedule/event registration + validation.
3. `04-03`: ShieldManager token-based implementation + extension callback wiring + usage guard.
4. `04-04`: ENFC-01 verification pass with unit/integration evidence and requirement traceability.

## Inputs Reviewed

Required:
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/ROADMAP.md`
- `AGENTS.md`

Implementation context:
- `ios/Packages/ScreenTimeEngine/Sources/ScreenTimeEngine/*`
- `ios/Extensions/DeviceActivityMonitor/DeviceActivityMonitorExtension.swift`
- `ios/Packages/PolicyStore/Sources/PolicyStore/FamilyActivitySelectionStore.swift`
- `ios/APP_REVIEW_PREFLIGHT.md`

## RESEARCH COMPLETE
