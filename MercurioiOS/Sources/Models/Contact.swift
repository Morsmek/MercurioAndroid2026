import Foundation

struct Contact: Codable, Identifiable {
    let id: UUID
    let userMercurioId: String
    let contactMercurioId: String
    var displayName: String
    var verified: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userMercurioId = "user_mercurio_id"
        case contactMercurioId = "contact_mercurio_id"
        case displayName = "display_name"
        case verified
        case createdAt = "created_at"
    }

    init(id: UUID = UUID(), userMercurioId: String, contactMercurioId: String, displayName: String, verified: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.userMercurioId = userMercurioId
        self.contactMercurioId = contactMercurioId
        self.displayName = displayName
        self.verified = verified
        self.createdAt = createdAt
    }
}
