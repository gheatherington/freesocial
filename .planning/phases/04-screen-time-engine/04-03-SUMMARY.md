---
phase: 04-screen-time-engine
plan: "03"
subsystem: ios
tags: [swift, managed-settings, device-activity, family-controls, application-token, xcode]

requires:
  - phase: 04-01
    provides: AuthorizationManager real impl and managedStoreIdentifier namespace constant
  - phase: 04-02
    provides: ActivityScheduler with FamilyActivitySelectionStore integration and EventName constants
  - phase: 03-03
    provides: shouldRecordBypassEvent seam pattern and DeviceActivityMonitorExtension+Testing.swift

provides:
  - ShieldManager token-based apply/clear using ManagedSettingsStore (named store)
  - shouldApplyShields() pure helper covering 3-gate guard matrix in +Testing.swift
  - DeviceActivityMonitorExtension threshold callback wired to full ENFC-01 enforcement chain
  - 5 DeviceActivityThresholdGuardTests proving nil/revoked/no-selection/premature/valid matrix
  - 2 ShieldManagerTokenAPITests proving empty-set no-op and clearAllShields idempotency

affects: [04-04, phase-05-controlled-client, verification]

tech-stack:
  added: [ManagedSettings (ShieldManager named store), ScreenTimeEngine (DAM extension dependency)]
  patterns:
    - Named ManagedSettingsStore keyed by ScreenTimeEngine.managedStoreIdentifier
    - shouldApplyShields() pure helper seam (parallel to shouldRecordBypassEvent from 03-03)
    - intervalStartTime tracking in intervalDidStart for premature-event guard
    - ApplicationToken typealias (AnyHashable) for macOS package test host compatibility

key-files:
  created:
    - ios/FreeSocial/Tests/FreeSocialTests/ShieldManagerTokenAPITests.swift
    - ios/FreeSocial/Tests/FreeSocialTests/DeviceActivityThresholdGuardTests.swift
  modified:
    - ios/Packages/ScreenTimeEngine/Sources/ScreenTimeEngine/ShieldManager.swift
    - ios/Extensions/DeviceActivityMonitor/DeviceActivityMonitorExtension.swift
    - ios/Extensions/DeviceActivityMonitor/DeviceActivityMonitorExtension+Testing.swift
    - ios/FreeSocial.xcodeproj/project.pbxproj

key-decisions:
  - "ShieldManager returns Bool from shieldApps: true=shields written, false=empty set no-op (observable to callers)"
  - "shouldApplyShields seam uses TimeInterval elapsedSeconds param — caller injects value, tests inject arbitrary values"
  - "30s shieldGuardWindow hardcoded in production extension; test cases use same constant via guardWindow param"
  - "ApplicationToken typealias (AnyHashable) used for macOS package test host — real ApplicationToken on iOS"
  - "ScreenTimeEngine added as package dependency to DAM extension and FreeSocialTests in pbxproj"
  - "PolicyStore added as package dependency to FreeSocialTests in pbxproj for FamilyActivitySelectionStore"

patterns-established:
  - "Pure helper seam pattern: extract guard logic to +Testing.swift shared source file for DAM + FreeSocialTests"
  - "intervalStartTime tracking: record start time in intervalDidStart, use in threshold callback for elapsed guard"
  - "Named ManagedSettingsStore: always use ScreenTimeEngine.managedStoreIdentifier, never hardcode store name"

requirements-completed: [ENFC-01]

duration: ~25min
completed: 2026-03-06
---

# Phase 4 Plan 03: Shield Enforcement and Threshold Guard Summary

**Token-based ManagedSettings shield enforcement wired to threshold callbacks with 3-gate guard matrix suppressing iOS 26.2 premature events**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-03-05T21:49:00Z
- **Completed:** 2026-03-06T...Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- ShieldManager replaced string-based stub with `Set<ApplicationToken>` + named `ManagedSettingsStore` apply/clear — returns Bool so callers can observe no-op vs. write
- `shouldApplyShields()` pure helper added to `+Testing.swift` covering 3-gate matrix: consent gate + token selection gate + 30s premature-event guard
- `eventDidReachThreshold` wired to full ENFC-01 chain: loads consent + selection, calls guard helper, then applies shields via `ShieldManager.shieldApps(selection.applicationTokens)` on valid path
- 7 new boundary tests (2 ShieldManager + 5 threshold guard) pass on iPhone 17 / iOS 26.2 — full test suite 13/13

## Task Commits

1. **Task 1: Token-based ShieldManager with ManagedSettings** - `c31ee69` (feat)
2. **Task 2: Threshold callback wired to guarded shield enforcement** - `172d555` (feat)

## Files Created/Modified

- `ios/Packages/ScreenTimeEngine/Sources/ScreenTimeEngine/ShieldManager.swift` — Token-based apply/clear using named ManagedSettingsStore; ApplicationToken typealias for macOS host
- `ios/Extensions/DeviceActivityMonitor/DeviceActivityMonitorExtension.swift` — Full ENFC-01 threshold callback with shield enforcement, bypass telemetry, and guard chain
- `ios/Extensions/DeviceActivityMonitor/DeviceActivityMonitorExtension+Testing.swift` — Added shouldApplyShields() 3-gate pure helper alongside existing shouldRecordBypassEvent()
- `ios/FreeSocial/Tests/FreeSocialTests/ShieldManagerTokenAPITests.swift` — Empty-set no-op and clearAllShields idempotency tests
- `ios/FreeSocial/Tests/FreeSocialTests/DeviceActivityThresholdGuardTests.swift` — 5 ENFC-01 boundary tests covering nil/revoked/no-selection/premature/valid matrix
- `ios/FreeSocial.xcodeproj/project.pbxproj` — ScreenTimeEngine + PolicyStore added to FreeSocialTests; ScreenTimeEngine added to DAM extension target

## Decisions Made

- `shieldApps` returns `Bool` (true=shields applied, false=empty set no-op). Explicit return enables callers and tests to observe which path was taken without mocking.
- `shouldApplyShields` takes `elapsedSeconds: TimeInterval` as a parameter rather than reading `Date()` internally — matches the test-seam pattern from 03-03, making the guard deterministically testable.
- 30-second guard window (`shieldGuardWindow`) hardcoded in the extension as a named constant; injected as parameter in the pure helper. Research flag in STATE.md documented this iOS 26.2 behavior.
- `ApplicationToken` is `typealias AnyHashable` on macOS so `ShieldManager` compiles in the SPM package test host. Real `ManagedSettings.ApplicationToken` is used on iOS. Consistent with `#if os(iOS)` pattern established in 03-02/04-02.
- `ScreenTimeEngine` added as explicit package product dependency to both DAM extension target and FreeSocialTests in pbxproj — required for `ShieldManager` and namespace constants.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added Foundation import to DeviceActivityMonitorExtension+Testing.swift**
- **Found during:** Task 2 (GREEN phase compilation)
- **Issue:** `TimeInterval` not in scope — +Testing.swift compiled in DAM extension which had no Foundation import
- **Fix:** Added `import Foundation` at top of +Testing.swift
- **Files modified:** ios/Extensions/DeviceActivityMonitor/DeviceActivityMonitorExtension+Testing.swift
- **Verification:** Build and test pass after fix
- **Committed in:** `172d555` (part of Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - bug)
**Impact on plan:** Required for compilation; no scope change.

## Issues Encountered

None beyond the auto-fixed Foundation import.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- ENFC-01 enforcement chain complete: authorization (04-01) → scheduling (04-02) → shielding (04-03)
- Plan 04-04 (verification matrix + evidence artifact) can now generate ENFC-01 evidence
- Real-device verification of `selection.applicationTokens` shield path deferred (requires FamilyControls authorization grant on device)

## Self-Check: PASSED

- SUMMARY.md: FOUND at `.planning/phases/04-screen-time-engine/04-03-SUMMARY.md`
- Commit c31ee69: FOUND (feat: ShieldManager token API)
- Commit 172d555: FOUND (feat: threshold callback enforcement)
- ShieldManager.swift: FOUND
- DeviceActivityThresholdGuardTests.swift: FOUND

---
*Phase: 04-screen-time-engine*
*Completed: 2026-03-06*
