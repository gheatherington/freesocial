import ConsentManager
import DeviceActivity
import Foundation
import ManagedSettings
import PolicyStore

final class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    private let policyRepository = PolicyRepository()

    override func intervalDidStart(for activity: DeviceActivityName) {
        // Stub: apply baseline shields via PolicyStore
        super.intervalDidStart(for: activity)
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        // Stub: remove or adjust shields when monitored interval ends
        super.intervalDidEnd(for: activity)
    }

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        // DATA-02: Only record bypass events when the user has active consent.
        // Reads persisted ConsentRecord from App Group shared container.
        // nil → never consented; isRevoked == true → consent revoked.
        // Both cases skip bypass telemetry to honor revocation semantics.
        let store = ConsentStore(suiteName: AppGroup.suiteName)
        guard shouldRecordBypassEvent(for: store) else { return }

        let bypassEvent = BypassEvent(
            id: UUID(),
            occurredAt: Date(),
            escalationLevelAtTime: policyRepository.currentEscalationLevel()
        )
        policyRepository.recordBypassEvent(bypassEvent)
        super.eventDidReachThreshold(event, activity: activity)
    }
}
