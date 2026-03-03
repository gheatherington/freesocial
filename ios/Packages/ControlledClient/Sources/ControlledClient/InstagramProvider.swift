import Foundation

/// Phase 2 stub. Concrete implementation in future phase.
/// Conforms to SocialProvider with minimal stub behavior for Instagram content access.
public struct InstagramProvider: SocialProvider {
    public let name: String = "Instagram"

    public init() {}

    public var supportedPathways: [CommunicationPathway] {
        [.directMessage, .story, .comment]
    }

    public func fetchBatch(after cursor: String?) async throws -> ContentBatch {
        ContentBatch(items: [], nextCursor: nil)
    }
}
