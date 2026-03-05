import Foundation

/// Persists and retrieves user consent records via the App Group shared container.
///
/// The `suiteName` parameter must be `AppGroup.suiteName` (from PolicyStore) at all
/// production call sites. It is a parameter rather than a direct import so that
/// ConsentManager remains independent of PolicyStore.
public final class ConsentStore {
    private let defaults: UserDefaults

    /// Stable namespaced key for the stored consent record payload.
    private let consentRecordKey = "com.freesocial.consent.currentRecord"

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

    /// Persists a consent record using JSONEncoder into the App Group shared container.
    public func save(_ record: ConsentRecord) {
        guard let data = try? JSONEncoder().encode(record) else { return }
        defaults.set(data, forKey: consentRecordKey)
    }

    /// Loads the most recent consent record, or nil if none exists or decode fails.
    ///
    /// Revoked records are returned unchanged — callers must check `record.isRevoked`.
    /// Returning nil is reserved for "never consented" state only.
    public func loadCurrent() -> ConsentRecord? {
        guard let data = defaults.data(forKey: consentRecordKey) else { return nil }
        return try? JSONDecoder().decode(ConsentRecord.self, from: data)
    }

    /// Marks the current consent record as revoked.
    ///
    /// No-ops when no record exists. Sets `isRevoked = true` and `revokedAt = Date()`,
    /// then persists the mutated record.
    public func revoke() {
        guard var record = loadCurrent() else { return }
        record.isRevoked = true
        record.revokedAt = Date()
        save(record)
    }
}
