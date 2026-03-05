---
phase: 03-data-layer-foundations
plan: "02"
subsystem: database
tags: [swift, xctest, userdefaults, json, policystore, familycontrols, appgroup]

# Dependency graph
requires:
  - phase: v1.0-skeleton
    provides: PolicyRepository stub, BypassEvent, EscalationLevel, AppGroup.suiteName
  - phase: 03-01
    provides: Namespaced key pattern, suiteName injection pattern, test cleanup pattern

provides:
  - PolicyRepository real escalation + bypass telemetry persistence via JSONEncoder to App Group UserDefaults
  - FamilyActivitySelectionStore with hasSelection/clear (cross-platform) and save/load (iOS-only)
  - PolicyStore swift test macOS compatibility via .macOS(.v13) platform entry
  - DATA-03 assertion coverage in PolicyStore tests (10 new + 2 UAT stub replacements)

affects:
  - 03-03-DeviceActivityMonitor (reads PolicyRepository for escalation state in bypass recording)
  - 03-04-VerificationMatrix (includes PolicyStore persistence in evidence)
  - Phase 4 (ScreenTimeEngine reads escalation level for shield activation decisions)
  - Phase 6 (FamilyActivitySelectionStore.save called after FamilyActivityPicker dismissal)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "os(iOS) guard for FamilyControls import — more reliable than canImport(FamilyControls) on macOS"
    - "suiteName injection in PolicyRepository init — test isolation with deterministic cleanup"
    - "read-modify-write bypass event append via bypassEvents() + append + encode"
    - "Corrupt-payload resilience: decode failure returns .baseline / empty [] never crashes"

key-files:
  created:
    - ios/Packages/PolicyStore/Sources/PolicyStore/FamilyActivitySelectionStore.swift
    - ios/Packages/PolicyStore/Tests/PolicyStoreTests/PolicyRepositoryPersistenceTests.swift
    - ios/Packages/PolicyStore/Tests/PolicyStoreTests/FamilyActivitySelectionStoreTests.swift
  modified:
    - ios/Packages/PolicyStore/Sources/PolicyStore/PolicyRepository.swift
    - ios/Packages/PolicyStore/Tests/PolicyStoreTests/PolicyStoreUATStubs.swift
    - ios/Packages/PolicyStore/Package.swift

key-decisions:
  - "Used os(iOS) guard instead of canImport(FamilyControls) — canImport failed to exclude on macOS swift test"
  - "PolicyRepository suiteName init added — test isolation parallel to ConsentStore pattern"
  - "setEscalationLevel added as public API — required for test assertions and Phase 4 escalation transitions"
  - "FamilyActivitySelectionStore.save/load use FamilyControls.FamilyActivitySelection fully-qualified to avoid scope ambiguity"

patterns-established:
  - "PolicyRepository keys: com.freesocial.policy.escalationLevel and com.freesocial.policy.bypassEvents"
  - "FamilyActivitySelectionStore key: com.freesocial.policy.familyActivitySelection"
  - "os(iOS) compile guard: use for FamilyControls, DeviceActivity, ManagedSettings imports"

requirements-completed: [DATA-01, DATA-02, DATA-03]

# Metrics
duration: 4min
completed: 2026-03-05
---

# Phase 3 Plan 02: PolicyStore Persistence Summary

**PolicyRepository wired to App Group UserDefaults with JSONEncoder escalation/bypass persistence and FamilyActivitySelectionStore added with os(iOS) guard — 16 tests pass, 0 skips**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-03-05T15:19:29Z
- **Completed:** 2026-03-05T15:23:00Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- PolicyRepository.setEscalationLevel/currentEscalationLevel with JSONEncoder and .baseline fallback on corrupt data
- PolicyRepository.recordBypassEvent appends to persisted [BypassEvent] array with read-modify-write
- PolicyRepository.bypassEvents() returns ordered events, empty array fallback on corrupt data
- PolicyRepository.resetToBaseline clears both escalation and bypass event history atomically
- FamilyActivitySelectionStore with cross-platform hasSelection/clear and iOS-only save/load
- Package.swift extended with .macOS(.v13) for swift test compatibility
- NB-02 and NB-03 UAT skips replaced with real assertions; 16 tests pass, 0 skips

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: PolicyRepository failing tests** - `ca2e4e4` (test)
2. **Task 1 GREEN: PolicyRepository persistence implementation** - `157409e` (feat)
3. **Task 2 RED: FamilyActivitySelectionStore failing tests** - `f452fe5` (test)
4. **Task 2 GREEN: FamilyActivitySelectionStore + UAT stubs** - `e02c95d` (feat)

## Files Created/Modified

- `ios/Packages/PolicyStore/Sources/PolicyStore/PolicyRepository.swift` — Real setEscalationLevel/currentEscalationLevel/recordBypassEvent/bypassEvents/resetToBaseline with suiteName init; keys com.freesocial.policy.escalationLevel and com.freesocial.policy.bypassEvents
- `ios/Packages/PolicyStore/Sources/PolicyStore/FamilyActivitySelectionStore.swift` — New file: hasSelection/clear (cross-platform), save/load (iOS-only with os(iOS) guard); key com.freesocial.policy.familyActivitySelection
- `ios/Packages/PolicyStore/Tests/PolicyStoreTests/PolicyRepositoryPersistenceTests.swift` — 10 tests: escalation defaults, round-trip, reset, corrupt fallback, bypass events empty/append/durable/reset/corrupt
- `ios/Packages/PolicyStore/Tests/PolicyStoreTests/FamilyActivitySelectionStoreTests.swift` — 3 tests: hasSelection false when empty, clear removes selection, clear idempotent
- `ios/Packages/PolicyStore/Tests/PolicyStoreTests/PolicyStoreUATStubs.swift` — Replaced NB-02/NB-03 XCTSkip stubs with real escalation and bypass telemetry assertions
- `ios/Packages/PolicyStore/Package.swift` — Added .macOS(.v13) platform for swift test macOS compatibility

## Decisions Made

- `os(iOS)` guard chosen over `canImport(FamilyControls)`: `canImport` does not reliably exclude FamilyControls on macOS during swift test compilation — the `os(iOS)` conditional is explicit and deterministic.
- `setEscalationLevel` added as a public API method: the stub had only `currentEscalationLevel()` and the test plan requires assertions against all escalation levels; the setter is required by Phase 4 escalation transitions anyway.
- `suiteName` init added to `PolicyRepository`: consistent with ConsentStore pattern established in Plan 03-01; test isolation requires per-test suite names with deterministic cleanup.

## Deviations from Plan

None — plan executed exactly as written. The `os(iOS)` guard choice (over `canImport`) was an implementation detail required to make `swift test` work on macOS, not a scope change.

## Issues Encountered

- `canImport(FamilyControls)` did not exclude the FamilyControls types from macOS compilation during `swift test` — the block still compiled FamilyControls symbols, causing "cannot find type" errors. Resolved by switching to `#if os(iOS)` which is OS-conditional and reliable.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- PolicyRepository persistence is complete and tested — Plan 03-03 can use `PolicyRepository().recordBypassEvent` with consent gate wiring
- `PolicyRepository(suiteName: AppGroup.suiteName)` is the production call pattern (zero-arg init also works)
- `FamilyActivitySelectionStore` ready for Phase 6 FamilyActivityPicker integration
- All 16 PolicyStore tests pass; 03-03 can proceed without any PolicyStore blockers

## Self-Check: PASSED

- FOUND: ios/Packages/PolicyStore/Sources/PolicyStore/PolicyRepository.swift
- FOUND: ios/Packages/PolicyStore/Sources/PolicyStore/FamilyActivitySelectionStore.swift
- FOUND: ios/Packages/PolicyStore/Tests/PolicyStoreTests/PolicyRepositoryPersistenceTests.swift
- FOUND: ios/Packages/PolicyStore/Tests/PolicyStoreTests/FamilyActivitySelectionStoreTests.swift
- FOUND commit: ca2e4e4 (test RED PolicyRepository)
- FOUND commit: 157409e (feat GREEN PolicyRepository)
- FOUND commit: f452fe5 (test RED FamilyActivitySelectionStore)
- FOUND commit: e02c95d (feat GREEN FamilyActivitySelectionStore + UAT stubs)
- All 16 tests pass, 0 failures, 0 skips

---
*Phase: 03-data-layer-foundations*
*Completed: 2026-03-05*
