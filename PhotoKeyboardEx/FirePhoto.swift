import Foundation
import PhotoKeyboardFramework

struct Photo: Codable, Equatable {
    var id: UUID
    var title: String
    var imageHeight: Int
    var imageWidth: Int
    var imageUrl: String
    var genre: String
    var totalSaveCount: Int
    var weeklySaveCount: Int
    var weekStartDay: String?
    var ownerId: UUID?
    var locale: String
    var isDebug: Bool
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, genre, locale
        case imageHeight = "image_height"
        case imageWidth = "image_width"
        case imageUrl = "image_url"
        case totalSaveCount = "total_save_count"
        case weeklySaveCount = "weekly_save_count"
        case weekStartDay = "week_start_day"
        case ownerId = "owner_id"
        case isDebug = "is_debug"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// OFirePhoto との互換用typealias
typealias OFirePhoto = Photo
