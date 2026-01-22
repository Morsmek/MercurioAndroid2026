import Foundation

struct Conversation: Codable, Identifiable {
    let id: String
    let participant1Id: String
    let participant2Id: String
    var lastMessage: String?
    var lastMessageAt: Date?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case participant1Id = "participant1_id"
        case participant2Id = "participant2_id"
        case lastMessage = "last_message"
        case lastMessageAt = "last_message_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func otherParticipantId(myId: String) -> String {
        return participant1Id == myId ? participant2Id : participant1Id
    }

    static func generateId(participant1: String, participant2: String) -> String {
        let sorted = [participant1, participant2].sorted()
        return "\(sorted[0])_\(sorted[1])"
    }
}
