import Foundation

/// Persists and retrieves user consent records.
/// Phase 2 stub — concrete persistence via App Group UserDefaults implemented in future phase.
public final class ConsentStore {
    public init() {}

    /// Persists a consent record.
    public func save(_ record: ConsentRecord) { /* stub */ }

    /// Loads the most recent active consent record, or nil if none exists.
    public func loadCurrent() -> ConsentRecord? { return nil /* stub */ }

    /// Marks the current consent record as revoked.
    public func revoke() { /* stub */ }
}
