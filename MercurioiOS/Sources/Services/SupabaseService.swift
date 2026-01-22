import Foundation
import Supabase

actor SupabaseService {
    static let shared = SupabaseService()

    private let supabase: SupabaseClient

    private init() {
        guard let supabaseURL = ProcessInfo.processInfo.environment["VITE_SUPABASE_URL"],
              let supabaseKey = ProcessInfo.processInfo.environment["VITE_SUPABASE_ANON_KEY"],
              let url = URL(string: supabaseURL) else {
            fatalError("Supabase configuration missing")
        }

        self.supabase = SupabaseClient(supabaseURL: url, supabaseKey: supabaseKey)
    }

    func uploadUserPublicKeys(user: User) async throws {
        try await supabase.from("users").upsert([
            "mercurio_id": user.mercurioId,
            "ed25519_public_key": user.ed25519PublicKey,
            "rsa_public_key_modulus": user.rsaPublicKeyModulus,
            "rsa_public_key_exponent": user.rsaPublicKeyExponent,
            "is_online": true,
            "last_seen": ISO8601DateFormatter().string(from: Date())
        ]).execute()
    }

    func fetchUserPublicKeys(mercurioId: String) async throws -> User? {
        let response: [User] = try await supabase.from("users")
            .select()
            .eq("mercurio_id", value: mercurioId)
            .execute()
            .value

        return response.first
    }

    func addContact(_ contact: Contact) async throws {
        try await supabase.from("contacts").insert([
            "user_mercurio_id": contact.userMercurioId,
            "contact_mercurio_id": contact.contactMercurioId,
            "display_name": contact.displayName,
            "verified": contact.verified
        ]).execute()
    }

    func fetchContacts(for mercurioId: String) async throws -> [Contact] {
        let response: [Contact] = try await supabase.from("contacts")
            .select()
            .eq("user_mercurio_id", value: mercurioId)
            .order("created_at", ascending: false)
            .execute()
            .value

        return response
    }

    func deleteContact(id: UUID) async throws {
        try await supabase.from("contacts")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    func sendMessage(_ message: Message) async throws {
        try await supabase.from("messages").insert([
            "conversation_id": message.conversationId,
            "sender_mercurio_id": message.senderMercurioId,
            "recipient_mercurio_id": message.recipientMercurioId,
            "encrypted_content": message.encryptedContent,
            "encrypted_aes_key": message.encryptedAesKey,
            "nonce": message.nonce,
            "mac": message.mac,
            "status": message.status.rawValue
        ]).execute()

        try await updateConversation(
            conversationId: message.conversationId,
            lastMessage: "Encrypted message",
            participant1: message.senderMercurioId,
            participant2: message.recipientMercurioId
        )
    }

    func fetchMessages(for conversationId: String) async throws -> [Message] {
        let response: [Message] = try await supabase.from("messages")
            .select()
            .eq("conversation_id", value: conversationId)
            .order("created_at", ascending: true)
            .execute()
            .value

        return response
    }

    func markMessageAsRead(messageId: UUID) async throws {
        try await supabase.from("messages")
            .update([
                "read_at": ISO8601DateFormatter().string(from: Date()),
                "status": MessageStatus.read.rawValue
            ])
            .eq("id", value: messageId.uuidString)
            .execute()
    }

    func updateConversation(conversationId: String, lastMessage: String, participant1: String, participant2: String) async throws {
        let sorted = [participant1, participant2].sorted()
        try await supabase.from("conversations").upsert([
            "id": conversationId,
            "participant1_id": sorted[0],
            "participant2_id": sorted[1],
            "last_message": lastMessage,
            "last_message_at": ISO8601DateFormatter().string(from: Date()),
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]).execute()
    }

    func fetchConversations(for mercurioId: String) async throws -> [Conversation] {
        let response: [Conversation] = try await supabase.from("conversations")
            .select()
            .or("participant1_id.eq.\(mercurioId),participant2_id.eq.\(mercurioId)")
            .order("updated_at", ascending: false)
            .execute()
            .value

        return response
    }

    func subscribeToMessages(conversationId: String, callback: @escaping (Message) -> Void) -> Task<Void, Never> {
        return Task {
            let channel = await supabase.realtime.channel("messages:\(conversationId)")

            await channel.on("postgres_changes", filter: ChannelFilter(
                event: "INSERT",
                schema: "public",
                table: "messages",
                filter: "conversation_id=eq.\(conversationId)"
            )) { message in
                if let payload = message.payload as? [String: Any],
                   let jsonData = try? JSONSerialization.data(withJSONObject: payload),
                   let newMessage = try? JSONDecoder().decode(Message.self, from: jsonData) {
                    callback(newMessage)
                }
            }

            await channel.subscribe()
        }
    }
}
