import Foundation

/// A value type capturing a single user consent grant or revocation event.
/// Implements Codable for persistence in the App Group shared container.
/// Implements Identifiable for SwiftUI list rendering and diffing.
public struct ConsentRecord: Codable, Identifiable {
    public let id: UUID
    public let grantedAt: Date
    public var isRevoked: Bool
    public var revokedAt: Date?

    public init(
        id: UUID = UUID(),
        grantedAt: Date = Date(),
        isRevoked: Bool = false,
        revokedAt: Date? = nil
    ) {
        self.id = id
        self.grantedAt = grantedAt
        self.isRevoked = isRevoked
        self.revokedAt = revokedAt
    }
}
