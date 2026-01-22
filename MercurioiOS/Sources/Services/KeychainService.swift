import Foundation
import Security

actor KeychainService {
    static let shared = KeychainService()

    private let service = "com.mercurio.messenger"

    private enum Keys {
        static let ed25519PublicKey = "ed25519_public_key"
        static let ed25519PrivateKey = "ed25519_private_key"
        static let rsaPublicKey = "rsa_public_key"
        static let rsaPrivateKey = "rsa_private_key"
        static let mercurioId = "mercurio_id"
        static let recoveryPhrase = "recovery_phrase"
    }

    private init() {}

    func save(ed25519PublicKey: Data, ed25519PrivateKey: Data, mercurioId: String, recoveryPhrase: String, rsaPublicKey: RSAPublicKey, rsaPrivateKey: Data) async throws {
        try await saveData(ed25519PublicKey, for: Keys.ed25519PublicKey)
        try await saveData(ed25519PrivateKey, for: Keys.ed25519PrivateKey)
        try await saveString(mercurioId, for: Keys.mercurioId)
        try await saveString(recoveryPhrase, for: Keys.recoveryPhrase)

        let rsaPublicKeyData = try JSONEncoder().encode(rsaPublicKey)
        try await saveData(rsaPublicKeyData, for: Keys.rsaPublicKey)
        try await saveData(rsaPrivateKey, for: Keys.rsaPrivateKey)
    }

    func getMercurioId() async -> String? {
        return await getString(for: Keys.mercurioId)
    }

    func getRecoveryPhrase() async -> String? {
        return await getString(for: Keys.recoveryPhrase)
    }

    func getEd25519PublicKey() async -> Data? {
        return await getData(for: Keys.ed25519PublicKey)
    }

    func getEd25519PrivateKey() async -> Data? {
        return await getData(for: Keys.ed25519PrivateKey)
    }

    func getRSAPublicKey() async -> RSAPublicKey? {
        guard let data = await getData(for: Keys.rsaPublicKey) else { return nil }
        return try? JSONDecoder().decode(RSAPublicKey.self, from: data)
    }

    func getRSAPrivateKey() async -> Data? {
        return await getData(for: Keys.rsaPrivateKey)
    }

    func deleteAll() async throws {
        for key in [Keys.ed25519PublicKey, Keys.ed25519PrivateKey, Keys.rsaPublicKey, Keys.rsaPrivateKey, Keys.mercurioId, Keys.recoveryPhrase] {
            try await delete(key: key)
        }
    }

    private func saveData(_ data: Data, for key: String) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        try await delete(key: key)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    private func saveString(_ string: String, for key: String) async throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        try await saveData(data, for: key)
    }

    private func getData(for key: String) async -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return data
    }

    private func getString(for key: String) async -> String? {
        guard let data = await getData(for: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func delete(key: String) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

enum KeychainError: Error {
    case saveFailed(OSStatus)
    case deleteFailed(OSStatus)
    case invalidData
}
