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
        // Consent gate: only record bypass events when the user has granted consent.
        // Phase 2 stub — ConsentStore wiring deferred to Phase 3 (requires resolving
        // the ConsentManager/AppGroup architecture decision). Defaults to true so
        // stub behavior is preserved until the real gate is wired.
        let consentIsGranted: Bool = true // TODO(Phase 3): replace with ConsentStore.loadCurrent() != nil
        guard consentIsGranted else { return }

        let bypassEvent = BypassEvent(
            id: UUID(),
            occurredAt: Date(),
            escalationLevelAtTime: policyRepository.currentEscalationLevel()
        )
        policyRepository.recordBypassEvent(bypassEvent)
        super.eventDidReachThreshold(event, activity: activity)
    }
}
