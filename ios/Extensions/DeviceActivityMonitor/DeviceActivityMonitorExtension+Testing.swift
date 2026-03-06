import ConsentManager
import Foundation
import PolicyStore

// MARK: - Consent gate (DATA-02)

/// Pure consent-gate logic extracted from DeviceActivityMonitorExtension for testability.
///
/// This function is the canonical decision point for whether a bypass telemetry
/// event should be recorded. It is extracted from the extension callback so that
/// unit tests in FreeSocialTests can assert DATA-02 boundary behavior without
/// requiring a live DeviceActivity runtime.
///
/// DATA-02: Bypass telemetry is written only when active consent exists.
/// - nil loadCurrent()  → consent never granted → return false (do not record)
/// - isRevoked == true  → consent revoked       → return false (do not record)
/// - isRevoked == false → consent active         → return true  (record event)
func shouldRecordBypassEvent(for store: ConsentStore) -> Bool {
    guard let record = store.loadCurrent() else { return false }
    return record.isRevoked == false
}

// MARK: - Shield apply guard (ENFC-01)

/// Pure shield-apply guard logic extracted from DeviceActivityMonitorExtension for testability.
///
/// This function is the canonical decision point for whether the threshold callback
/// should invoke shield enforcement. It is extracted so that unit tests in FreeSocialTests
/// can assert ENFC-01 guard matrix behavior without requiring a live DeviceActivity runtime.
///
/// ENFC-01: Shields are applied only when ALL of the following conditions are met:
/// 1. Consent is active (not nil, not revoked).
/// 2. A token selection exists in FamilyActivitySelectionStore.
/// 3. The elapsed time since interval start exceeds `guardWindow` (suppresses
///    premature iOS 26.2 `eventDidReachThreshold` callbacks).
///
/// - Parameters:
///   - store: The ConsentStore to read the current consent record from.
///   - selectionStore: The FamilyActivitySelectionStore to check for persisted tokens.
///   - elapsedSeconds: Time elapsed since the monitoring interval started, in seconds.
///     Passed by the caller so tests can inject arbitrary values without real-time.
///   - guardWindow: Minimum elapsed seconds required before a threshold event is treated
///     as legitimate. Default production value: 30 seconds (suppresses iOS 26.2 artifacts).
/// - Returns: `true` when all guard conditions pass; `false` when any condition fails.
func shouldApplyShields(
    for store: ConsentStore,
    selectionStore: FamilyActivitySelectionStore,
    elapsedSeconds: TimeInterval,
    guardWindow: TimeInterval
) -> Bool {
    // Gate 1: Active consent required.
    guard let record = store.loadCurrent(), record.isRevoked == false else {
        return false
    }

    // Gate 2: Persisted token selection required.
    guard selectionStore.hasSelection else {
        return false
    }

    // Gate 3: Premature event suppression.
    // iOS 26.2 fires eventDidReachThreshold immediately on interval start in some
    // configurations. Require elapsed >= guardWindow before treating as legitimate.
    guard elapsedSeconds >= guardWindow else {
        return false
    }

    return true
}
