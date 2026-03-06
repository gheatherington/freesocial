import ConsentManager
import DeviceActivity
import Foundation
import ManagedSettings
import PolicyStore
import ScreenTimeEngine

final class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    // MARK: - Dependencies

    private let policyRepository = PolicyRepository()
    private let shieldManager    = ShieldManager()

    /// Timestamp recorded when the daily monitoring interval starts.
    /// Used by the premature-event guard in eventDidReachThreshold.
    private var intervalStartTime: Date?

    /// Production guard window: 30 seconds.
    /// Suppresses iOS 26.2 false-positive eventDidReachThreshold callbacks that fire
    /// immediately on interval registration before any real usage has occurred.
    private let shieldGuardWindow: TimeInterval = 30

    // MARK: - DeviceActivityMonitor overrides

    override func intervalDidStart(for activity: DeviceActivityName) {
        // Record interval start time for the premature-event guard.
        intervalStartTime = Date()
        super.intervalDidStart(for: activity)
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        // Clear shields when the daily interval ends (midnight reset).
        shieldManager.clearAllShields()
        intervalStartTime = nil
        super.intervalDidEnd(for: activity)
    }

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        // ENFC-01: Apply shields only when all guard conditions pass.
        // Uses shouldApplyShields() from +Testing.swift — same seam as DATA-02.
        let consentStore   = ConsentStore(suiteName: AppGroup.suiteName)
        let selectionStore = FamilyActivitySelectionStore(suiteName: AppGroup.suiteName)

        // Compute elapsed seconds since interval start.
        // If intervalStartTime is nil (unlikely in production), use a large value
        // so the guard does not suppress a legitimate event.
        let elapsed = intervalStartTime.map { Date().timeIntervalSince($0) } ?? shieldGuardWindow

        if shouldApplyShields(
            for: consentStore,
            selectionStore: selectionStore,
            elapsedSeconds: elapsed,
            guardWindow: shieldGuardWindow
        ) {
            // Retrieve persisted token selection and apply shields.
            // On iOS, load() returns the FamilyActivitySelection if present.
            // We derive ApplicationToken set from the selection's applicationTokens.
            #if os(iOS)
            if let selection = selectionStore.load() {
                Task {
                    await shieldManager.shieldApps(selection.applicationTokens)
                }
            }
            #endif
        }

        // DATA-02: Only record bypass events when the user has active consent.
        // Reads persisted ConsentRecord from App Group shared container.
        // nil → never consented; isRevoked == true → consent revoked.
        // Both cases skip bypass telemetry to honor revocation semantics.
        guard shouldRecordBypassEvent(for: consentStore) else {
            super.eventDidReachThreshold(event, activity: activity)
            return
        }

        let bypassEvent = BypassEvent(
            id: UUID(),
            occurredAt: Date(),
            escalationLevelAtTime: policyRepository.currentEscalationLevel()
        )
        policyRepository.recordBypassEvent(bypassEvent)
        super.eventDidReachThreshold(event, activity: activity)
    }
}
