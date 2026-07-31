import Foundation

struct Report: Codable, Equatable {
    var id: UUID?
    var userId: UUID?
    var ownerId: String
    var contentId: UUID?
    var reason: String
    var imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, reason
        case userId = "user_id"
        case ownerId = "owner_id"
        case contentId = "content_id"
        case imageUrl = "image_url"
    }
}
