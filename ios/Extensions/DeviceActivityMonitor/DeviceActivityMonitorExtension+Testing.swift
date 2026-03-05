import ConsentManager

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
