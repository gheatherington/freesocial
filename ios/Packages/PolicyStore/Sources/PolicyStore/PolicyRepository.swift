import Foundation

/// Stub repository for persisting and reading policy state.
/// Uses the App Group shared UserDefaults container so extensions can read policy state.
/// Phase 2 stub: concrete read/write logic implemented in future phase.
public struct PolicyRepository {
    private let defaults: UserDefaults

    public init() {
        self.defaults = UserDefaults(suiteName: AppGroup.suiteName) ?? .standard
    }

    /// Returns the current escalation level. Stub always returns baseline.
    public func currentEscalationLevel() -> EscalationLevel { .baseline }

    /// Records a bypass event for escalation tracking.
    public func recordBypassEvent(_ event: BypassEvent) { /* stub */ }

    /// Resets escalation level to baseline.
    public func resetToBaseline() { /* stub */ }
}
