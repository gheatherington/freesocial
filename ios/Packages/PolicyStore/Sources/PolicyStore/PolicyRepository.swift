import Foundation

/// Persists and reads policy state in the App Group shared UserDefaults container.
/// Extensions read escalation level and bypass events written by the main app.
public struct PolicyRepository {
    private let defaults: UserDefaults

    private enum Keys {
        static let escalationLevel = "com.freesocial.policy.escalationLevel"
        static let bypassEvents    = "com.freesocial.policy.bypassEvents"
    }

    /// Initializes with the shared App Group defaults.
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

    /// Designated initializer for tests — accepts an explicit suiteName.
    public init(suiteName: String) {
        if let shared = UserDefaults(suiteName: suiteName) {
            self.defaults = shared
        } else {
            assertionFailure("UserDefaults suiteName '\(suiteName)' is unavailable.")
            self.defaults = .standard
        }
    }

    // MARK: - Escalation level

    /// Returns the persisted escalation level, defaulting to `.baseline` on missing or corrupt data.
    public func currentEscalationLevel() -> EscalationLevel {
        guard let data = defaults.data(forKey: Keys.escalationLevel) else { return .baseline }
        do {
            return try JSONDecoder().decode(EscalationLevel.self, from: data)
        } catch {
            return .baseline
        }
    }

    /// Persists the given escalation level.
    public func setEscalationLevel(_ level: EscalationLevel) {
        if let data = try? JSONEncoder().encode(level) {
            defaults.set(data, forKey: Keys.escalationLevel)
        }
    }

    /// Records a bypass event by appending to the persisted event array.
    public func recordBypassEvent(_ event: BypassEvent) {
        var events = bypassEvents()
        events.append(event)
        if let data = try? JSONEncoder().encode(events) {
            defaults.set(data, forKey: Keys.bypassEvents)
        }
    }

    /// Returns all persisted bypass events in insertion order.
    /// Returns an empty array on missing or corrupt data.
    public func bypassEvents() -> [BypassEvent] {
        guard let data = defaults.data(forKey: Keys.bypassEvents) else { return [] }
        do {
            return try JSONDecoder().decode([BypassEvent].self, from: data)
        } catch {
            return []
        }
    }

    /// Resets escalation to `.baseline` and clears the bypass event history.
    public func resetToBaseline() {
        setEscalationLevel(.baseline)
        defaults.removeObject(forKey: Keys.bypassEvents)
    }
}
