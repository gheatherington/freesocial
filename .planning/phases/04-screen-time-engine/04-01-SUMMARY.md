---
phase: 04-screen-time-engine
plan: "01"
subsystem: ScreenTimeEngine
tags: [authorization, family-controls, deauthorization, cleanup, tdd]
dependency_graph:
  requires: []
  provides: [AuthorizationManager-real-impl, AuthorizationStatus-type, AuthorizationCleanupHandler-protocol, ScreenTimeEngineNamespace-constants]
  affects: [04-02, 04-03, 04-04]
tech_stack:
  added: [FamilyControls (os(iOS) guarded), ManagedSettings (os(iOS) guarded), DeviceActivity (os(iOS) guarded), Combine (os(iOS) guarded)]
  patterns: [os(iOS)-compile-guard, protocol-seam-injection, test-simulate-seam]
key_files:
  created:
    - ios/Packages/ScreenTimeEngine/Sources/ScreenTimeEngine/ScreenTimeEngineNamespace.swift
    - ios/Packages/ScreenTimeEngine/Tests/ScreenTimeEngineTests/AuthorizationManagerTests.swift
  modified:
    - ios/Packages/ScreenTimeEngine/Sources/ScreenTimeEngine/AuthorizationManager.swift
decisions:
  - "os(iOS) guard chosen over canImport(FamilyControls) for ScreenTimeEngine — same pattern as PolicyStore Phase 3 (canImport insufficient; ManagedSettingsStore/DeviceActivityCenter marked unavailable on macOS even when importable)"
  - "simulateStatusChange(to:) test seam added to AuthorizationManager — enables deterministic deauth cleanup tests without FamilyControls runtime"
  - "AuthorizationCleanupHandler protocol seam — injected in tests, production path calls ManagedSettingsStore/DeviceActivityCenter directly inside os(iOS) guard"
metrics:
  duration_minutes: 2
  completed_date: "2026-03-05"
  tasks_completed: 2
  files_changed: 3
requirements:
  - ENFC-01
---

# Phase 4 Plan 01: AuthorizationManager Real Implementation Summary

**One-liner:** Real FamilyControls authorization with `os(iOS)` guarded imports, deauthorization observer triggering `clearAllSettings` + `stopMonitoring`, and deterministic test seam via `simulateStatusChange(to:)`.

## What Was Built

### ScreenTimeEngineNamespace.swift (new)
Centralized string constants to prevent drift across scheduler and extension shield code:
- `ScreenTimeEngine.dailyActivityName = "freesocial.daily"`
- `ScreenTimeEngine.managedStoreIdentifier = "freesocial.shields"`

Platform-agnostic types needed for host-testable code:
- `AuthorizationStatus` enum: `notDetermined`, `approved`, `denied`
- `AuthorizationError` enum: `familyControlsUnavailable`, `denied`
- `AuthorizationCleanupHandler` protocol: `clearAllSettings()`, `stopAllMonitoring()`

### AuthorizationManager.swift (rewritten from stub)
- `requestAuthorization()` calls `AuthorizationCenter.shared.requestAuthorization(for: .individual)` on iOS; throws `AuthorizationError.familyControlsUnavailable` on macOS host
- `currentStatus: AuthorizationStatus` property for app-layer branching
- `setupDeauthorizationObserver()` subscribes to `AuthorizationCenter.shared.$authorizationStatus` on iOS (Combine sink) — on deauth calls cleanup chain
- `triggerDeauthorizationCleanup()` dispatches to injected handler (tests) or real `ManagedSettingsStore().clearAllSettings()` + `DeviceActivityCenter().stopMonitoring()` (production)
- `simulateStatusChange(to:)` — test seam; triggers cleanup when status is `.denied`
- All FamilyControls/ManagedSettings/DeviceActivity/Combine APIs guarded with `#if os(iOS)`

### AuthorizationManagerTests.swift (new — 5 tests)
| Test | Behavior |
|------|----------|
| `testRequestAuthorizationDoesNotThrowOnHostPlatform` | requestAuthorization() does not crash on macOS host; error (if any) is AuthorizationError type |
| `testCurrentStatusIsReadable` | currentStatus defaults to .notDetermined on non-iOS host |
| `testDeauthorizationTriggersCleaner` | simulateStatusChange(.denied) → clearAllSettings + stopAllMonitoring called on mock handler |
| `testNonDeauthTransitionDoesNotTriggerCleaner` | simulateStatusChange(.approved) → cleanup NOT triggered |
| `testCleanupIsIdempotent` | three .denied transitions → no crash; cleanup handler called |

## Verification

```
swift test (ios/Packages/ScreenTimeEngine)
→ Executed 7 tests, with 1 test skipped and 0 failures
```

Results:
- 5 AuthorizationManagerTests — all pass
- 1 ScreenTimeEngineTests.testPlaceholder — pass
- 1 ScreenTimeEngineUATStubs.testNativeAppRestrictionConfiguredViaTokenSelection — XCTSkip (NB-01, will be cleared in 04-04)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] canImport guard insufficient for ManagedSettings/DeviceActivity on macOS**
- **Found during:** Task 1 GREEN — swift test compile errors
- **Issue:** `canImport(FamilyControls)` lets the import proceed but `ManagedSettingsStore` and `DeviceActivityCenter` are still marked `@available unavailable` on macOS, causing build errors in the body
- **Fix:** Changed all guards from `#if canImport(FamilyControls)` / `#if canImport(ManagedSettings)` to `#if os(iOS)` — consistent with PolicyStore Phase 3 pattern
- **Files modified:** `AuthorizationManager.swift`
- **Commit:** cff15a0

## Self-Check

Files created/modified:
- [x] `ios/Packages/ScreenTimeEngine/Sources/ScreenTimeEngine/ScreenTimeEngineNamespace.swift` — FOUND
- [x] `ios/Packages/ScreenTimeEngine/Sources/ScreenTimeEngine/AuthorizationManager.swift` — FOUND
- [x] `ios/Packages/ScreenTimeEngine/Tests/ScreenTimeEngineTests/AuthorizationManagerTests.swift` — FOUND

Commits:
- b742d76 — test(04-01): failing tests RED
- cff15a0 — feat(04-01): implementation GREEN

Must-haves satisfied:
- [x] AuthorizationManager.requestAuthorization invokes FamilyControls AuthorizationCenter from main-app callable code (os(iOS) guarded)
- [x] AuthorizationManager observes deauthorization transitions and triggers immediate cleanup (Combine publisher on iOS; simulateStatusChange test seam on host)
- [x] Deauthorization cleanup calls ManagedSettingsStore().clearAllSettings() and stops active monitoring (DeviceActivityCenter().stopMonitoring())
- [x] FamilyControls-dependent logic remains compile-guarded for host test compatibility (#if os(iOS) throughout)
- [x] ScreenTimeEngine tests contain real assertions for authorization and deauthorization behavior (5 AuthorizationManagerTests)

## Self-Check: PASSED
