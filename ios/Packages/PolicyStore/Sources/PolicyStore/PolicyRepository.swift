import Foundation

/// Stub repository for persisting and reading policy state.
/// Uses the App Group shared UserDefaults container so extensions can read policy state.
/// Phase 2 stub: concrete read/write logic implemented in future phase.
public struct PolicyRepository {
    private let defaults: UserDefaults

    public init() {
        if let shared = UserDefaults(suiteName: AppGroup.suiteName) {
            self.defaults = shared
        } else {
            assertionFailure(
                "App Group '\(AppGroup.suiteName)' is unavailable — " +
                "policy sync between app and extensions will fail. " +
                "Verify the App Group entitlement is configured in both app and extension targets."
            )
            self.defaults = .standard
        }
    }

    /// Returns the current escalation level. Stub always returns baseline.
    public func currentEscalationLevel() -> EscalationLevel { .baseline }

    /// Records a bypass event for escalation tracking.
    public func recordBypassEvent(_ event: BypassEvent) { /* stub */ }

    /// Resets escalation level to baseline.
    public func resetToBaseline() { /* stub */ }
}
