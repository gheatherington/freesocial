---
phase: 04-screen-time-engine
plan: "02"
subsystem: screen-time
tags: [DeviceActivity, FamilyControls, PolicyStore, ActivityScheduler, threshold-events]

# Dependency graph
requires:
  - phase: 04-01
    provides: "ScreenTimeEngineNamespace constants, AuthorizationManager implementation"
  - phase: 03-02
    provides: "FamilyActivitySelectionStore with hasSelection guard and suiteName init"
provides:
  - "ActivityScheduler domain API: startMonitoring/stopMonitoring/buildMonitoringConfiguration"
  - "Per-platform threshold event mapping: instagram -> instagramDailyLimit, tiktok -> tiktokDailyLimit"
  - "ScreenTimeEngine.EventName namespace constants for instagramDailyLimit and tiktokDailyLimit"
  - "PolicyStore dependency wired into ScreenTimeEngine Package.swift"
  - "8 deterministic ActivitySchedulerTests covering threshold mapping, validation, idempotency"
affects:
  - 04-03-shield-manager
  - 04-04-verification
  - DeviceActivityMonitorExtension (shared event name constants)

# Tech tracking
tech-stack:
  added: ["PolicyStore as local package dependency of ScreenTimeEngine"]
  patterns:
    - "buildMonitoringConfiguration() pure helper separates DeviceActivity API calls from testable logic"
    - "MonitoredPlatform enum as dictionary key type for type-safe per-platform limit maps"
    - "MonitoringStartResult enum (started/noTokensSelected) as explicit return type instead of throws-or-void"
    - "stop-then-start idempotency pattern for DeviceActivityCenter registration"

key-files:
  created:
    - ios/Packages/ScreenTimeEngine/Tests/ScreenTimeEngineTests/ActivitySchedulerTests.swift
  modified:
    - ios/Packages/ScreenTimeEngine/Package.swift
    - ios/Packages/ScreenTimeEngine/Sources/ScreenTimeEngine/ActivityScheduler.swift
    - ios/Packages/ScreenTimeEngine/Sources/ScreenTimeEngine/ScreenTimeEngineNamespace.swift

key-decisions:
  - "buildMonitoringConfiguration() returns pure MonitoringConfiguration value type — allows threshold mapping assertions without DeviceActivity runtime"
  - "MonitoringStartResult.noTokensSelected returned (not thrown) for missing token selection — consistent with soft guard semantics"
  - "ScreenTimeEngine.EventName sub-enum added to existing namespace (not a new ScreenTimeEngineNamespace type) — least-change evolution of 04-01 output"
  - "macOS(.v13) added to Package.swift platforms — same host-testability pattern as ConsentManager and ControlledClient"

patterns-established:
  - "Platform-guard with #if os(iOS) for all DeviceActivity API calls inside package targets"
  - "suiteName-injectable init for testability alongside convenience init() using AppGroup.suiteName"

requirements-completed: [ENFC-01]

# Metrics
duration: 4min
completed: 2026-03-05
---

# Phase 4 Plan 02: ActivityScheduler Scheduling Implementation Summary

**ActivityScheduler with daily per-platform threshold event registration, explicit instagram/tiktok mapping via ScreenTimeEngine.EventName constants, and 8 deterministic host-side tests**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-05T21:39:37Z
- **Completed:** 2026-03-05T21:42:57Z
- **Tasks:** 2 (implemented in one TDD cycle)
- **Files modified:** 4

## Accomplishments

- Replaced generic `scheduleActivity(name:schedule:)` stub with enforcement-oriented `startMonitoring(platformLimits:)` and `stopMonitoring()` APIs
- Added `buildMonitoringConfiguration()` pure helper for deterministic threshold-mapping assertions without DeviceActivity runtime
- Wired PolicyStore as a package dependency so FamilyActivitySelectionStore is consumable from ActivityScheduler
- Extended ScreenTimeEngineNamespace with `EventName.instagramDailyLimit` and `EventName.tiktokDailyLimit` constants
- Implemented stop-then-start idempotency and `noTokensSelected` guard
- All 8 ActivitySchedulerTests pass on macOS host (swift test)

## Task Commits

1. **Tasks 1+2: ActivityScheduler API redesign, threshold mapping, and tests** - `348c567` (feat)

## Files Created/Modified

- `ios/Packages/ScreenTimeEngine/Package.swift` - Added PolicyStore dependency and macOS(.v13) platform
- `ios/Packages/ScreenTimeEngine/Sources/ScreenTimeEngine/ActivityScheduler.swift` - Full rewrite: MonitoredPlatform, ActivitySchedulerError, MonitoringStartResult, MonitoringConfiguration types + ActivityScheduler implementation
- `ios/Packages/ScreenTimeEngine/Sources/ScreenTimeEngine/ScreenTimeEngineNamespace.swift` - Added EventName sub-enum with instagramDailyLimit and tiktokDailyLimit constants
- `ios/Packages/ScreenTimeEngine/Tests/ScreenTimeEngineTests/ActivitySchedulerTests.swift` - 8 tests: threshold mapping, distinct event names, zero/negative/missing limits, daily schedule properties, noTokensSelected guard, idempotency

## Decisions Made

- `buildMonitoringConfiguration()` returns a pure value type (`MonitoringConfiguration`) rather than directly constructing DeviceActivity types, so threshold-mapping assertions can run on macOS without the DeviceActivity framework available.
- `MonitoringStartResult` is returned (not thrown) for soft-guard cases like `noTokensSelected` — throws are reserved for programmer errors (invalid input), not expected runtime states.
- EventName constants were added as a sub-enum inside the existing `ScreenTimeEngine` enum (established by 04-01), not as a separate `ScreenTimeEngineNamespace` type — least-change evolution of 04-01's namespace structure.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added macOS(.v13) to ScreenTimeEngine Package.swift**
- **Found during:** Task 1 setup
- **Issue:** Package.swift had only `[.iOS(.v16)]` — same missing platform that required the ConsentManager/ControlledClient fixes in Phase 3. Without it, `swift test` on macOS host fails with Combine/Cancellable availability errors on iOS-only Combine types pulled in by AuthorizationManager.
- **Fix:** Added `.macOS(.v13)` to platforms array.
- **Files modified:** ios/Packages/ScreenTimeEngine/Package.swift
- **Verification:** `swift test` passes (15 tests, 1 skip)
- **Committed in:** 348c567 (task commit)

**2. [Rule 3 - Blocking] Extended ScreenTimeEngineNamespace with EventName constants**
- **Found during:** Task 1 (RED phase — tests reference ScreenTimeEngine.EventName which didn't exist)
- **Issue:** 04-01 created the namespace file with `dailyActivityName` and `managedStoreIdentifier` but no per-platform event name constants. 04-02 requires these constants for the threshold mapping API.
- **Fix:** Added `EventName` sub-enum with `instagramDailyLimit` and `tiktokDailyLimit` raw value strings.
- **Files modified:** ios/Packages/ScreenTimeEngine/Sources/ScreenTimeEngine/ScreenTimeEngineNamespace.swift
- **Verification:** Tests assert exact constant values via `ScreenTimeEngine.EventName.instagramDailyLimit`
- **Committed in:** 348c567 (task commit)

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** Both fixes unblocked compilation; no scope creep.

## Issues Encountered

None beyond the auto-fixed blockers above.

## Next Phase Readiness

- ActivityScheduler provides `startMonitoring/stopMonitoring` callable from 04-03's ShieldManager integration
- `ScreenTimeEngine.EventName` constants are now stable — 04-03 DeviceActivityMonitorExtension callback routing can match on these strings
- `MonitoringConfiguration` type available for 04-04 verification assertions
- All 15 ScreenTimeEngine tests pass; no regressions to previous 04-01 work

---
*Phase: 04-screen-time-engine*
*Completed: 2026-03-05*
