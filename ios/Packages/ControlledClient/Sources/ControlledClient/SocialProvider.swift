import Foundation

/// The canonical protocol defining the finite surface area for controlled social content access.
/// Both Instagram and TikTok providers must conform to this protocol.
/// This surface area is intentionally narrow — only fetch and communication pathways are exposed.
public protocol SocialProvider {
    var name: String { get }
    func fetchBatch(after cursor: String?) async throws -> ContentBatch
    var supportedPathways: [CommunicationPathway] { get }
}

/// A paginated batch of content items returned by a social provider fetch.
public struct ContentBatch {
    public let items: [ContentItem]
    public let nextCursor: String?

    public init(items: [ContentItem], nextCursor: String?) {
        self.items = items
        self.nextCursor = nextCursor
    }
}

/// A single content item in a feed batch.
public struct ContentItem: Identifiable {
    public let id: String
    public let body: String

    public init(id: String, body: String) {
        self.id = id
        self.body = body
    }
}

/// The finite set of communication pathways a social provider can support.
/// Keeping this enum explicit ensures no unapproved pathways are added silently.
public enum CommunicationPathway {
    case directMessage
    case story
    case comment
}
