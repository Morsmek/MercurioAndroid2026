import Foundation

struct User: Codable, Identifiable {
    let mercurioId: String
    let ed25519PublicKey: String
    let rsaPublicKeyModulus: String
    let rsaPublicKeyExponent: String
    let createdAt: Date
    var lastSeen: Date
    var isOnline: Bool

    var id: String { mercurioId }

    enum CodingKeys: String, CodingKey {
        case mercurioId = "mercurio_id"
        case ed25519PublicKey = "ed25519_public_key"
        case rsaPublicKeyModulus = "rsa_public_key_modulus"
        case rsaPublicKeyExponent = "rsa_public_key_exponent"
        case createdAt = "created_at"
        case lastSeen = "last_seen"
        case isOnline = "is_online"
    }
}
