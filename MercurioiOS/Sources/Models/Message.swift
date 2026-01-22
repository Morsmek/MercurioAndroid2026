import Foundation

struct Message: Codable, Identifiable {
    let id: UUID
    let conversationId: String
    let senderMercurioId: String
    let recipientMercurioId: String
    let encryptedContent: String
    let encryptedAesKey: String
    let nonce: String
    let mac: String
    let createdAt: Date
    var readAt: Date?
    var status: MessageStatus

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case senderMercurioId = "sender_mercurio_id"
        case recipientMercurioId = "recipient_mercurio_id"
        case encryptedContent = "encrypted_content"
        case encryptedAesKey = "encrypted_aes_key"
        case nonce
        case mac
        case createdAt = "created_at"
        case readAt = "read_at"
        case status
    }

    init(id: UUID = UUID(), conversationId: String, senderMercurioId: String, recipientMercurioId: String, encryptedContent: String, encryptedAesKey: String, nonce: String, mac: String, createdAt: Date = Date(), readAt: Date? = nil, status: MessageStatus = .sent) {
        self.id = id
        self.conversationId = conversationId
        self.senderMercurioId = senderMercurioId
        self.recipientMercurioId = recipientMercurioId
        self.encryptedContent = encryptedContent
        self.encryptedAesKey = encryptedAesKey
        self.nonce = nonce
        self.mac = mac
        self.createdAt = createdAt
        self.readAt = readAt
        self.status = status
    }
}

enum MessageStatus: String, Codable {
    case sending
    case sent
    case delivered
    case read
    case failed
}

struct DecryptedMessage: Identifiable {
    let id: UUID
    let conversationId: String
    let senderMercurioId: String
    let content: String
    let createdAt: Date
    var readAt: Date?
    var status: MessageStatus
}
