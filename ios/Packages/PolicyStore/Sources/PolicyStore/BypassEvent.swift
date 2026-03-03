import Foundation

/// Records a single user bypass of an intervention prompt.
/// Used to track escalation history for cooldown policy enforcement.
public struct BypassEvent: Codable {
    public let id: UUID
    public let occurredAt: Date
    public let escalationLevelAtTime: EscalationLevel

    public init(id: UUID = UUID(), occurredAt: Date = Date(), escalationLevelAtTime: EscalationLevel) {
        self.id = id
        self.occurredAt = occurredAt
        self.escalationLevelAtTime = escalationLevelAtTime
    }
}
