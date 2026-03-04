import Foundation

/// Persists and retrieves user consent records via the App Group shared container.
/// Phase 2 stub — concrete persistence logic implemented in Phase 3.
///
/// The `suiteName` parameter must be `AppGroup.suiteName` (from PolicyStore) at all
/// production call sites. It is a parameter rather than a direct import so that
/// ConsentManager remains independent of PolicyStore.
public final class ConsentStore {
    private let defaults: UserDefaults

    /// - Parameter suiteName: The App Group identifier for the shared UserDefaults container.
    ///   Pass `AppGroup.suiteName` from PolicyStore at all production call sites.
    public init(suiteName: String) {
        if let shared = UserDefaults(suiteName: suiteName) {
            self.defaults = shared
        } else {
            assertionFailure(
                "App Group '\(suiteName)' is unavailable — " +
                "consent state will not be visible to extensions. " +
                "Verify the App Group entitlement is configured in both app and extension targets."
            )
            self.defaults = .standard
        }
    }

    /// Persists a consent record.
    public func save(_ record: ConsentRecord) { /* stub */ }

    /// Loads the most recent active consent record, or nil if none exists.
    public func loadCurrent() -> ConsentRecord? { return nil /* stub */ }

    /// Marks the current consent record as revoked.
    public func revoke() { /* stub */ }
}
