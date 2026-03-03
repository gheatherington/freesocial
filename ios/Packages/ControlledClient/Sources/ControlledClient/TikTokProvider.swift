import Foundation

/// Phase 2 stub. Concrete implementation in future phase.
/// Conforms to SocialProvider with minimal stub behavior for TikTok content access.
public struct TikTokProvider: SocialProvider {
    public let name: String = "TikTok"

    public init() {}

    public var supportedPathways: [CommunicationPathway] {
        [.directMessage, .comment]
    }

    public func fetchBatch(after cursor: String?) async throws -> ContentBatch {
        ContentBatch(items: [], nextCursor: nil)
    }
}
