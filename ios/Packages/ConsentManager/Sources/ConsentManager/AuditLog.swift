import Foundation

/// A single entry in the consent audit log.
public struct AuditEntry: Codable {
    public let timestamp: Date
    public let action: String

    public init(timestamp: Date = Date(), action: String) {
        self.timestamp = timestamp
        self.action = action
    }
}

/// Append-only log of consent-related actions for compliance auditing.
///
/// Persists entries as a JSONEncoder'd array in the App Group shared container.
/// Decode failures are treated as an empty log — entries are never lost due to a
/// corrupt payload preventing future appends.
public final class AuditLog {
    private let defaults: UserDefaults

    /// Stable namespaced key for the stored audit entry array.
    private let auditLogKey = "com.freesocial.consent.auditLog"

    /// - Parameter suiteName: The App Group identifier for the shared UserDefaults container.
    ///   Pass `AppGroup.suiteName` from PolicyStore at all production call sites.
    public init(suiteName: String) {
        if let shared = UserDefaults(suiteName: suiteName) {
            self.defaults = shared
        } else {
            assertionFailure(
                "App Group '\(suiteName)' is unavailable — " +
                "audit log will not be visible to extensions. " +
                "Verify the App Group entitlement is configured in both app and extension targets."
            )
            self.defaults = .standard
        }
    }

    /// Appends an audit entry to the persistent log.
    ///
    /// Reads existing entries (empty if none or corrupt), appends the new entry,
    /// and writes back the full encoded array.
    public func append(_ entry: AuditEntry) {
        var entries = allEntries()
        entries.append(entry)
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: auditLogKey)
    }

    /// Returns all persisted audit entries in insertion order.
    ///
    /// Returns an empty array when no entries exist or if the stored payload is corrupt.
    public func allEntries() -> [AuditEntry] {
        guard let data = defaults.data(forKey: auditLogKey) else { return [] }
        return (try? JSONDecoder().decode([AuditEntry].self, from: data)) ?? []
    }
}
