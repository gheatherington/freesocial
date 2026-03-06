# Repository Guidelines

## Project Structure & Module Organization

v1.0 milestone shipped. Repository now contains planning archives and iOS skeleton code.

- `.planning/` — primary project artifacts.
  - `PROJECT.md`, `ROADMAP.md`, `MILESTONES.md`, `STATE.md`, `RETROSPECTIVE.md`
  - `milestones/v1.0-ROADMAP.md`, `milestones/v1.0-REQUIREMENTS.md`, `milestones/v1.0-MILESTONE-AUDIT.md`
  - `milestones/v1.0-phases/` — archived Phase 1 and Phase 2 execution artifacts
- iOS skeleton code:
  - `ios/FreeSocial.xcodeproj` — hand-written pbxproj, iOS 16.0 deployment target, dark-first SwiftUI
  - `ios/Packages/ControlledClient/` — SocialProvider protocol, FeedView, InterventionView, FallbackRouter stubs
  - `ios/Packages/ScreenTimeEngine/` — AuthorizationManager, ShieldManager, ActivityScheduler stubs
  - `ios/Packages/PolicyStore/` — AppGroup (single suiteName), EscalationLevel (4 states), PolicyRepository, BypassEvent
  - `ios/Packages/ConsentManager/` — ConsentRecord, ConsentStore, AuditLog stubs
  - `ios/Extensions/DeviceActivityMonitor/` — DeviceActivityMonitor subclass with recordBypassEvent chain
  - `ios/Extensions/ShieldConfiguration/` — ShieldConfigurationDataSource, UIKit struct API only
  - `ios/Extensions/ShieldAction/` — ShieldActionDelegate stub
  - `ios/APP_REVIEW_PREFLIGHT.md` — canonical stop-ship gate (8 claims, 7 blocking conditions, POL-01/02/03 traced)

## Build, Test, and Development Commands

**Requires Xcode.app.** Installed and verified working 2026-03-04.

Installed simulator runtime: **iOS 26.2**. Use `iPhone 17` as the target device.

```bash
# Build
xcodebuild -project ios/FreeSocial.xcodeproj -scheme FreeSocial \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' build

# Test (current baseline: FreeSocialTests passes; UI test target present but empty)
xcodebuild test -project ios/FreeSocial.xcodeproj -scheme FreeSocial \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2'

# Run on simulator (raw app install works as of 2026-03-04 after plist metadata fixes)
DERIVED="/Users/gavin/Library/Developer/Xcode/DerivedData/FreeSocial-gjbgihqsoeillafxqsdobzpijlbm"
APP_SRC="$DERIVED/Build/Products/Debug-iphonesimulator/FreeSocial.app"
xcrun simctl boot 15796420-57AA-4732-BE47-5AB2F98B7626  # iPhone 17
open -a Simulator
xcrun simctl install booted "$APP_SRC"
xcrun simctl launch booted com.freesocial.app
```

Planning/GSD commands:
```bash
rg --files .planning                                          # list planning artifacts
node "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" roadmap analyze   # phase completion status
```

## Coding Style & Naming Conventions

For iOS code:
- Swift 5.9, SwiftUI, iOS 16.0 minimum deployment target.
- Module dependency rule: `ControlledClient` may import `PolicyStore`; `ScreenTimeEngine` and `ConsentManager` are independent of each other and of `ControlledClient`.
- `AppGroup.suiteName` is the single source of truth for `group.com.freesocial.app` — never hardcode this string elsewhere in Swift.
- Use `#if canImport(FamilyControls)` guards where FamilyControls/DeviceActivity APIs would break non-Xcode builds.
- Extension targets use UIKit only in ShieldConfiguration; DeviceActivityMonitor and ShieldAction are UIKit-free.
- `project.pbxproj` is hand-written — no Tuist or XcodeGen.

For planning artifacts:
- Use Markdown with short sections, explicit requirement IDs (`CC-01`, `NB-02`, `POL-03`), and clear acceptance criteria.
- Phase files follow `NN-xx-NAME.md` patterns (example: `03-01-feed-implementation.md`).

## Testing Guidelines

XCTest targets exist with UAT stubs (Phase 3 fills them in):
- `ControlledClientTests` — CC-01, CC-02, CC-03, POL-03 stubs
- `ScreenTimeEngineTests` — NB-01 stub
- `PolicyStoreTests` — NB-02, NB-03 stubs
- `ConsentManagerTests` — POL-02 stub
- `FreeSocialTests` — `AppReviewPreflightTests.testPublicClaimsMatchCapabilityMatrix` (active, not a stub — verifies `ios/APP_REVIEW_PREFLIGHT.md` exists)
- `FreeSocialUITests` — empty placeholder for Phase 3+ UI automation

Stub pattern: `func testName() throws { throw XCTSkip("UAT stub: REQ-ID — pending Module implementation") }`

When implementing tests in Phase 3:
- Replace XCTSkip with real assertions.
- Name tests by behavior: `testCooldownEscalatesAfterRepeatedBypass`.
- Keep requirement ID in test name or doc comment for traceability.

## Commit & Pull Request Guidelines

Git repo is live at `github.com/gheatherington/freesocial`.

- Scoped conventional commits: `feat(controlled-client): implement SocialProvider fetch`, `fix(policy-store): correct escalation reset logic`.
- Keep commits atomic — one plan task per commit.
- Never hardcode `group.com.freesocial.app` in Swift; always use `AppGroup.suiteName`.
- PRs should include: requirement IDs impacted, verification evidence, screenshots for UI changes.

## iOS 26 SDK Compatibility Notes

The skeleton was written targeting iOS 16.0 but the available simulator runtime is iOS 26.2. Several fixes were required:

- **`project.pbxproj`**: Added `SDKROOT = iphoneos` to project-level Debug and Release configs — without it xcodebuild defaults to macOS and shows no iOS simulator destinations.
- **`ShieldActionExtension.swift`**: Updated `handle(for:)` overrides from `Application`/`WebDomain` to `ApplicationToken`/`WebDomainToken` — iOS 26 SDK changed `ShieldActionDelegate` to use opaque token types.
- **`DeviceActivityMonitorExtension.swift`**: Added `import Foundation` — `UUID` and `Date` are not implicitly available without it.
- **`InterventionView.swift`**: Inlined the default string in the public `init` — Swift 5.9+ disallows `private` (or `internal`) static properties as default argument values in `public` initializers across module boundaries.
- **Extension `Info.plist` files** (all 3): Added required metadata keys for simulator install compatibility: `CFBundleIdentifier`, `CFBundleExecutable`, `CFBundleName`, `CFBundleVersion`, `CFBundleShortVersionString`, plus standard bundle keys. Without these, simulator install fails with `Invalid placeholder attributes`, `MissingBundleExecutable`, or `MissingBundleNameString`.
- **Simulator status (updated 2026-03-04)**: After plist normalization, raw simulator install/launch of the full app bundle (including `.appex`) succeeds and `xcodebuild test` passes.

## Session Updates (2026-03-04)

- Fixed `FreeSocialTests` target path wiring in `project.pbxproj`:
  - `Tests (FreeSocial)` group path changed from `Tests` to `FreeSocial/Tests`.
  - Resolved missing file error for `AppReviewPreflightTests.swift`.
- Restored testability for simulator and package workflows:
  - `xcodebuild test` now succeeds on `iPhone 17 / iOS 26.2`.
  - `swift test` for `ios/Packages/ControlledClient` now succeeds after adding `.macOS(.v13)` to `Package.swift` platforms.
- GitHub issue lifecycle from this session:
  - Closed: `#1` (test path miswire), `#2` (extension plist metadata), `#5` (ControlledClient host testability).
  - Closed (2026-03-04, follow-up): `#3`, `#4`, `#6`, `#7` — see Session Updates below.

## Session Updates (2026-03-04, follow-up)

Closed all remaining open GitHub issues (#3, #4, #6, #7). Resolved ConsentManager AppGroup architecture decision. All pre-Phase-3 blockers cleared.

**Issue fixes (commit `7f21b92`):**
- **#7 — FallbackRouter failure contract**: Changed `routeToNativeApp(for:)` return type from `Void` to `@discardableResult Bool`. Stub returns `false` until URL routing is implemented.
- **#6 — Background color asset warning**: Replaced `Color("Background")` asset lookup with programmatic `Color(red: 0.039, green: 0.039, blue: 0.039)` in `FeedView` and `InterventionView`. Also added universal (light-mode) fallback entry to `Background.colorset`.
- **#4 — PolicyRepository .standard fallback**: Replaced silent `?? .standard` with `assertionFailure` — fires in debug builds when App Group is unavailable. `.standard` fallback retained for release builds.
- **#3 — Consent gate stub**: Added consent guard to `eventDidReachThreshold` in `DeviceActivityMonitorExtension`. Defaults to `true` pending Phase 3 `ConsentStore` wiring.

**ConsentManager AppGroup decision (commit `a0b248b`):**
- Resolved: inject `suiteName: String` via `ConsentStore.init`. ConsentManager stays independent of PolicyStore.
- `ConsentStore` now wires shared `UserDefaults` and uses the same `assertionFailure` pattern as `PolicyRepository`.
- Phase 3 call pattern: `ConsentStore(suiteName: AppGroup.suiteName).loadCurrent()`.

## Session Updates (2026-03-04, Phase 3 planning)

Created Phase 3 planning artifacts. All architectural decisions for the data layer captured.

**Phase 3 context decisions (commit `1a5d174`):**
- **FamilyActivitySelectionStore placement**: Lives in `PolicyStore` package — co-located with all UserDefaults-backed persistence (PolicyRepository, BypassEvent, EscalationLevel). ControlledClient may import PolicyStore per module rules.
- **Revocation semantics**: `loadCurrent()` returns the `ConsentRecord` even when revoked — callers check `?.isRevoked == false`. Returning nil is reserved for "never consented." `revoke()` sets `isRevoked = true` and `revokedAt = Date()` and persists. DeviceActivityMonitor TODO updated to check `isRevoked` flag, not nil-ness.
- **AuditLog storage**: UserDefaults with JSONEncoder'd array of `AuditEntry` — consistent with ConsentStore and PolicyRepository. File-based append deferred (would require NSFileCoordinator for cross-process safety).
- **BypassEvent schema**: Keep as-is (`id`, `occurredAt`, `escalationLevelAtTime`). "Phase 1 telemetry spec" undefined in codebase; escalation deferred to v1.2. No expansion needed now.

**Artifacts created:**
- `.planning/phases/03-data-layer-foundations/` — phase directory
- `.planning/phases/03-data-layer-foundations/03-CONTEXT.md` — implementation decisions

## Session Updates (2026-03-05, Phase 3 planned)

Planned Phase 3 end-to-end using the plan-phase workflow with research and verification loop.

**Planning outputs:**
- `.planning/phases/03-data-layer-foundations/03-RESEARCH.md` — technical implementation research for DATA-01/02/03
- `.planning/phases/03-data-layer-foundations/03-01-PLAN.md` — ConsentStore + AuditLog persistence and tests
- `.planning/phases/03-data-layer-foundations/03-02-PLAN.md` — PolicyRepository + FamilyActivitySelectionStore persistence
- `.planning/phases/03-data-layer-foundations/03-03-PLAN.md` — DeviceActivityMonitor consent-gate integration and boundary tests
- `.planning/phases/03-data-layer-foundations/03-04-PLAN.md` — verification matrix and evidence artifact generation

**Verification loop result:**
- Initial checker pass reported 2 gaps (DATA-02 extension-boundary verification, DATA-01 cross-process verification detail).
- Plans 03-03 and 03-04 were revised to add explicit boundary and cross-process verification requirements.
- Final checker pass: `## VERIFICATION PASSED`.

## Security & Configuration Tips

- Do not claim unsupported platform capabilities in docs or UI copy — see `ios/APP_REVIEW_PREFLIGHT.md` Section 3 (prohibited copy) and Section 2 (cannot-claim rows).
- Use official iOS APIs only (FamilyControls, DeviceActivity, ManagedSettings) — no private/reverse-engineered integrations.
- Treat consent, revocation, and data minimization as release blockers — `APP_REVIEW_PREFLIGHT.md` Section 6 stop-ship checklist must pass before any submission.
- `ConsentStore` must gate `PolicyRepository.recordBypassEvent` on consent state — stub guard added in `DeviceActivityMonitorExtension` (defaults `true`); real wiring is a Phase 3 entry condition. Use `ConsentStore(suiteName: AppGroup.suiteName)` — architecture decision resolved 2026-03-04.

## Session Updates (2026-03-05, Phase 3 executed)

Executed Phase 3 end-to-end. All 4 plans complete, verification passed 14/14.

**Plans executed:**
- `03-01` — ConsentStore + AuditLog App Group persistence; revocation semantics; 16 tests (6 ConsentStorePersistenceTests, 5 AuditLogPersistenceTests, 4 ConsentManagerUATStubs, 1 placeholder)
- `03-02` — PolicyRepository escalation/bypass persistence; FamilyActivitySelectionStore with `#if os(iOS)` guards for macOS `swift test` compatibility; 16 PolicyStore tests
- `03-03` — DeviceActivityMonitor consent gate wired to real `ConsentStore(suiteName: AppGroup.suiteName)`; `shouldRecordBypassEvent(for:)` extracted to testable helper in `DeviceActivityMonitorExtension+Testing.swift`; 3 DATA-02 boundary tests (nil blocks, revoked blocks, active allows)
- `03-04` — Negative-path UAT assertions added; `03-VERIFICATION.md` published with full DATA-01/02/03 evidence

**Fix applied during execution:**
- `ios/Packages/ConsentManager/Package.swift`: Added `.macOS(.v13)` to platforms — same host-testability fix as ControlledClient. SourceKit and `swift test` both require macOS in platforms when running tests on the host machine.

**Verification:** `03-VERIFICATION.md` — passed, 14/14 must-haves. DATA-01, DATA-02, DATA-03 all satisfied.

**Deferred (noted in VERIFICATION.md):** FAS `hasSelection == true` path (requires real device + FamilyControls authorization); real-device cross-process coverage.

## Session Updates (2026-03-05, Phase 4 planned)

Planned Phase 4 end-to-end using the plan-phase workflow with research and verification loop.

**Phase:** `04-screen-time-engine` (`ENFC-01`)

**Context gate decision:**
- No `04-CONTEXT.md` existed at planning time.
- Chose to continue without discuss-phase context and plan from requirements + research.

**Artifacts created:**
- `.planning/phases/04-screen-time-engine/04-RESEARCH.md`
- `.planning/phases/04-screen-time-engine/04-VALIDATION.md`
- `.planning/phases/04-screen-time-engine/04-01-PLAN.md`
- `.planning/phases/04-screen-time-engine/04-02-PLAN.md`
- `.planning/phases/04-screen-time-engine/04-03-PLAN.md`
- `.planning/phases/04-screen-time-engine/04-04-PLAN.md`

**Verification loop result:**
- Initial checker pass reported 2 gaps:
  - wave-1 file ownership conflicts between `04-01` and `04-02`
  - missing explicit per-platform threshold enforcement in `04-02`
- Revision pass fixed file ownership and made Instagram/TikTok threshold mapping explicit.
- Second checker pass reported 2 additional gaps:
  - missing `PolicyStore` dependency wiring in `ios/Packages/ScreenTimeEngine/Package.swift`
  - dependency sequencing conflict (`04-02` consuming `04-01` namespace outputs without `depends_on`)
- Final revision added package-manifest wiring scope and set `04-02 depends_on: ["04-01"]`.
- Final checker pass: `## VERIFICATION PASSED`.

## Session Updates (2026-03-06, Phase 4 executed)

Executed Phase 4 end-to-end. All 4 plans complete, verification 4/4 must-haves (2 real-device items deferred per v1.1 scope).

**Plans executed:**
- `04-01` — `AuthorizationManager` rewritten with real `FamilyControls` auth request/deauth flow; `ScreenTimeEngineNamespace.swift` added (centralized constants + platform-agnostic types); 5 deterministic tests
- `04-02` — `ActivityScheduler` fully implemented with per-platform threshold mapping (Instagram/TikTok → named `DeviceActivityEvent`s); `PolicyStore` added as package dependency to `ScreenTimeEngine/Package.swift`; 8 tests
- `04-03` — `ShieldManager` rewritten with `Set<ApplicationToken>` + named `ManagedSettingsStore`; `shouldApplyShields()` 3-gate guard (consent + tokens + 30s premature-event window) wired into `eventDidReachThreshold`; 5 boundary tests
- `04-04` — 9 ENFC-01 assertion tests replacing `XCTSkip` placeholder; `04-VALIDATION.md` marked `nyquist_compliant: true`; `04-VERIFICATION.md` + `04-PHASE-VERIFICATION.md` with 4-link evidence chain published

**Fixes applied during execution:**
- `#if os(iOS)` guards used throughout `ScreenTimeEngine` (replacing `canImport(FamilyControls)` which was insufficient — APIs marked `@available unavailable` on macOS even when importable)
- `ScreenTimeEngine/Package.swift`: Added `.macOS(.v13)` to platforms for host testability
- `ApplicationToken` aliased to `AnyHashable` on macOS in `ShieldManager` to allow package host compilation

**Verification:** `04-PHASE-VERIFICATION.md` — `human_needed`, 4/4 must-haves. Two real-device items (FamilyControls auth sheet appearance, real-token shield overlay) explicitly deferred to v1.2 per REQUIREMENTS.md out-of-scope.

## Current Project Status (GSD)

- **Milestone:** v1.1 Implementation — IN PROGRESS
- **Stage:** Phase 4 complete — ready to execute Phase 5
- **Git tag:** `v1.0` (last shipped)
- **Phase 3 artifacts:** `.planning/phases/03-data-layer-foundations/` — 4 SUMMARYs + VERIFICATION.md
- **Phase 4 artifacts:** `.planning/phases/04-screen-time-engine/` — 4 SUMMARYs + VERIFICATION.md + PHASE-VERIFICATION.md

## What To Do Next

**Execute Phase 5:**
```
/gsd:execute-phase 5
```
`/clear` first for a fresh context window.

**Phase 5 scope:** WKWebView Controlled Feed — live Instagram/TikTok feed, session timer, InterventionView trigger. Requirements: FEED-01, FEED-02, FEED-03, FEED-04, DASH-02.
