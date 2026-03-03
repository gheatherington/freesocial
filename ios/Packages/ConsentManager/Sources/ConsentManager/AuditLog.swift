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
/// Phase 2 stub — writes to App Group shared container implemented in future phase.
public final class AuditLog {
    public init() {}

    /// Appends an audit entry to the persistent log.
    public func append(_ entry: AuditEntry) {
        // stub: write to App Group shared container
        // Phase 3 implementation: encode entry as JSON and append to shared file
    }
}
