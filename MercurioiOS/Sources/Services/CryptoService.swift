import Foundation
import CryptoKit
import Security
import CryptoSwift
import BIP39

actor CryptoService {
    static let shared = CryptoService()

    private let keychain = KeychainService.shared

    private init() {}

    func generateIdentity() async throws -> String {
        print("🔐 Starting identity generation...")

        let ed25519KeyPair = Curve25519.Signing.PrivateKey()
        let publicKeyData = ed25519KeyPair.publicKey.rawRepresentation
        let privateKeyData = ed25519KeyPair.rawRepresentation

        let mercurioId = "05" + publicKeyData.hexEncodedString()
        print("✅ Session ID generated: \(mercurioId.prefix(20))...")

        let recoveryPhrase = try BIP39.generateMnemonics(strength: 128)
        print("✅ Recovery phrase generated (12 words)")

        let rsaKeyPair = try generateRSAKeyPair()
        print("✅ RSA keypair generated")

        try await keychain.save(ed25519PublicKey: publicKeyData, ed25519PrivateKey: privateKeyData, mercurioId: mercurioId, recoveryPhrase: recoveryPhrase, rsaPublicKey: rsaKeyPair.publicKey, rsaPrivateKey: rsaKeyPair.privateKey)
        print("✅ Keys stored securely")

        return mercurioId
    }

    func restoreFromPhrase(_ phrase: String) async throws -> String {
        guard BIP39.isValid(phrase: phrase) else {
            throw CryptoError.invalidRecoveryPhrase
        }

        let seed = try BIP39.deriveSeed(phrase: phrase)
        let seedData = Data(seed.prefix(32))

        var privateKeyBytes = seedData
        privateKeyBytes[0] &= 248
        privateKeyBytes[31] &= 127
        privateKeyBytes[31] |= 64

        let ed25519KeyPair = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKeyBytes)
        let publicKeyData = ed25519KeyPair.publicKey.rawRepresentation
        let privateKeyData = ed25519KeyPair.rawRepresentation

        let mercurioId = "05" + publicKeyData.hexEncodedString()

        let rsaKeyPair = try generateRSAKeyPair()

        try await keychain.save(ed25519PublicKey: publicKeyData, ed25519PrivateKey: privateKeyData, mercurioId: mercurioId, recoveryPhrase: phrase, rsaPublicKey: rsaKeyPair.publicKey, rsaPrivateKey: rsaKeyPair.privateKey)

        return mercurioId
    }

    func hasIdentity() async -> Bool {
        return await keychain.getMercurioId() != nil
    }

    func getMercurioId() async -> String? {
        return await keychain.getMercurioId()
    }

    func getRecoveryPhrase() async -> String? {
        return await keychain.getRecoveryPhrase()
    }

    func getPublicKeys() async throws -> (ed25519: Data, rsa: RSAPublicKey) {
        guard let ed25519 = await keychain.getEd25519PublicKey(),
              let rsa = await keychain.getRSAPublicKey() else {
            throw CryptoError.keysNotFound
        }
        return (ed25519, rsa)
    }

    func encryptMessage(_ plaintext: String, recipientRSAPublicKey: RSAPublicKey) async throws -> EncryptedMessage {
        let aesKey = AES.randomKey(size: 32)
        let nonce = AES.randomNonce()

        let aes = try AES(key: aesKey, blockMode: GCM(iv: nonce, mode: .combined), padding: .noPadding)
        let ciphertext = try aes.encrypt(Array(plaintext.utf8))

        let encryptedAESKey = try encryptWithRSA(data: Data(aesKey), publicKey: recipientRSAPublicKey)

        let ciphertextData = Data(ciphertext.prefix(ciphertext.count - 16))
        let macData = Data(ciphertext.suffix(16))

        return EncryptedMessage(
            encryptedContent: ciphertextData.base64EncodedString(),
            encryptedAesKey: encryptedAESKey.base64EncodedString(),
            nonce: Data(nonce).base64EncodedString(),
            mac: macData.base64EncodedString()
        )
    }

    func decryptMessage(_ encryptedMessage: EncryptedMessage) async throws -> String {
        guard let privateKey = await keychain.getRSAPrivateKey() else {
            throw CryptoError.keysNotFound
        }

        guard let encryptedAESKeyData = Data(base64Encoded: encryptedMessage.encryptedAesKey),
              let ciphertextData = Data(base64Encoded: encryptedMessage.encryptedContent),
              let nonceData = Data(base64Encoded: encryptedMessage.nonce),
              let macData = Data(base64Encoded: encryptedMessage.mac) else {
            throw CryptoError.invalidEncryptedData
        }

        let aesKey = try decryptWithRSA(data: encryptedAESKeyData, privateKey: privateKey)

        var combinedData = Array(ciphertextData)
        combinedData.append(contentsOf: macData)

        let aes = try AES(key: Array(aesKey), blockMode: GCM(iv: Array(nonceData), mode: .combined), padding: .noPadding)
        let decrypted = try aes.decrypt(combinedData)

        guard let plaintext = String(bytes: decrypted, encoding: .utf8) else {
            throw CryptoError.decryptionFailed
        }

        return plaintext
    }

    func clearAllKeys() async throws {
        try await keychain.deleteAll()
    }

    private func generateRSAKeyPair() throws -> RSAKeyPair {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: 2048
        ]

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw error!.takeRetainedValue() as Error
        }

        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw CryptoError.rsaKeyGenerationFailed
        }

        let privateKeyData = SecKeyCopyExternalRepresentation(privateKey, nil)! as Data
        let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil)! as Data

        let publicKeyComponents = try parseRSAPublicKey(publicKeyData)

        return RSAKeyPair(publicKey: publicKeyComponents, privateKey: privateKeyData)
    }

    private func parseRSAPublicKey(_ data: Data) throws -> RSAPublicKey {
        let bytes = [UInt8](data)
        var index = 0

        func readLength() throws -> Int {
            guard index < bytes.count else { throw CryptoError.invalidRSAKey }
            let firstByte = bytes[index]
            index += 1

            if firstByte & 0x80 == 0 {
                return Int(firstByte)
            }

            let lengthBytes = Int(firstByte & 0x7F)
            var length = 0
            for _ in 0..<lengthBytes {
                guard index < bytes.count else { throw CryptoError.invalidRSAKey }
                length = (length << 8) | Int(bytes[index])
                index += 1
            }
            return length
        }

        func readInteger() throws -> Data {
            guard index < bytes.count, bytes[index] == 0x02 else {
                throw CryptoError.invalidRSAKey
            }
            index += 1

            let length = try readLength()
            guard index + length <= bytes.count else { throw CryptoError.invalidRSAKey }

            let intData = Data(bytes[index..<index + length])
            index += length
            return intData
        }

        guard bytes[index] == 0x30 else { throw CryptoError.invalidRSAKey }
        index += 1
        _ = try readLength()

        let modulus = try readInteger()
        let exponent = try readInteger()

        return RSAPublicKey(modulus: modulus.base64EncodedString(), exponent: exponent.base64EncodedString())
    }

    private func encryptWithRSA(data: Data, publicKey: RSAPublicKey) throws -> Data {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits as String: 2048
        ]

        guard let modulusData = Data(base64Encoded: publicKey.modulus),
              let exponentData = Data(base64Encoded: publicKey.exponent) else {
            throw CryptoError.invalidRSAKey
        }

        let publicKeyData = buildRSAPublicKey(modulus: modulusData, exponent: exponentData)

        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(publicKeyData as CFData, attributes as CFDictionary, &error) else {
            throw error!.takeRetainedValue() as Error
        }

        guard let encrypted = SecKeyCreateEncryptedData(secKey, .rsaEncryptionOAEPSHA256, data as CFData, &error) else {
            throw error!.takeRetainedValue() as Error
        }

        return encrypted as Data
    }

    private func decryptWithRSA(data: Data, privateKey: Data) throws -> Data {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrKeySizeInBits as String: 2048
        ]

        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(privateKey as CFData, attributes as CFDictionary, &error) else {
            throw error!.takeRetainedValue() as Error
        }

        guard let decrypted = SecKeyCreateDecryptedData(secKey, .rsaEncryptionOAEPSHA256, data as CFData, &error) else {
            throw error!.takeRetainedValue() as Error
        }

        return decrypted as Data
    }

    private func buildRSAPublicKey(modulus: Data, exponent: Data) -> Data {
        func encodeLength(_ length: Int) -> [UInt8] {
            if length < 128 {
                return [UInt8(length)]
            }

            var lengthBytes: [UInt8] = []
            var len = length
            while len > 0 {
                lengthBytes.insert(UInt8(len & 0xFF), at: 0)
                len >>= 8
            }

            return [UInt8(0x80 | lengthBytes.count)] + lengthBytes
        }

        func encodeInteger(_ data: Data) -> [UInt8] {
            var bytes = [UInt8](data)
            if bytes[0] & 0x80 != 0 {
                bytes.insert(0x00, at: 0)
            }
            return [0x02] + encodeLength(bytes.count) + bytes
        }

        let modulusBytes = encodeInteger(modulus)
        let exponentBytes = encodeInteger(exponent)
        let sequenceBytes = modulusBytes + exponentBytes

        let result = [0x30] + encodeLength(sequenceBytes.count) + sequenceBytes
        return Data(result)
    }
}

struct RSAKeyPair {
    let publicKey: RSAPublicKey
    let privateKey: Data
}

struct RSAPublicKey: Codable {
    let modulus: String
    let exponent: String
}

struct EncryptedMessage {
    let encryptedContent: String
    let encryptedAesKey: String
    let nonce: String
    let mac: String
}

enum CryptoError: Error {
    case invalidRecoveryPhrase
    case keysNotFound
    case rsaKeyGenerationFailed
    case invalidRSAKey
    case invalidEncryptedData
    case decryptionFailed
}

extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02x", $0) }.joined()
    }
}

extension AES {
    static func randomKey(size: Int) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: size)
        _ = SecRandomCopyBytes(kSecRandomDefault, size, &bytes)
        return bytes
    }

    static func randomNonce() -> [UInt8] {
        return randomKey(size: 12)
    }
}
