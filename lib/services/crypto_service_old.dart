import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:bip39/bip39.dart' as bip39;
import 'package:hex/hex.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Mercurio Cryptographic Service
/// Handles all cryptography operations including:
/// - Ed25519 keypair generation
/// - Session ID generation (66-char hex from public key)
/// - BIP39 recovery phrase (12 words)
/// - RSA-2048 encryption for key exchange
/// - AES-256-GCM message encryption
class CryptoService {
  static final CryptoService _instance = CryptoService._internal();
  factory CryptoService() => _instance;
  CryptoService._internal();

  final _secureStorage = const FlutterSecureStorage();
  final _algorithm = Ed25519();
  
  // Storage keys
  static const String _privateKeyKey = 'mercurio_private_key';
  static const String _publicKeyKey = 'mercurio_public_key';
  static const String _sessionIdKey = 'mercurio_session_id';
  static const String _recoveryPhraseKey = 'mercurio_recovery_phrase';

  /// Generate new Ed25519 keypair and Session ID
  /// Returns Session ID (66-char hex string)
  Future<String> generateIdentity() async {
    // Generate Ed25519 keypair
    final keyPair = await _algorithm.newKeyPair();
    
    // Extract public and private keys
    final publicKey = await keyPair.extractPublicKey();
    final privateKeyData = await keyPair.extractPrivateKeyBytes();
    
    // Convert public key to bytes
    final publicKeyBytes = publicKey.bytes;
    
    // Generate Session ID: "05" prefix + 64-char hex (32 bytes)
    final sessionId = '05${HEX.encode(publicKeyBytes)}';
    
    // Generate BIP39 recovery phrase (12 words)
    final recoveryPhrase = bip39.generateMnemonic();
    
    // Store keys securely
    await _secureStorage.write(
      key: _privateKeyKey,
      value: base64Encode(privateKeyData),
    );
    await _secureStorage.write(
      key: _publicKeyKey,
      value: base64Encode(publicKeyBytes),
    );
    await _secureStorage.write(
      key: _sessionIdKey,
      value: sessionId,
    );
    await _secureStorage.write(
      key: _recoveryPhraseKey,
      value: recoveryPhrase,
    );
    
    return sessionId;
  }

  /// Get current Session ID
  Future<String?> getSessionId() async {
    return await _secureStorage.read(key: _sessionIdKey);
  }

  /// Get recovery phrase
  Future<String?> getRecoveryPhrase() async {
    return await _secureStorage.read(key: _recoveryPhraseKey);
  }

  /// Check if identity exists
  Future<bool> hasIdentity() async {
    final sessionId = await getSessionId();
    return sessionId != null && sessionId.isNotEmpty;
  }

  /// Get public key as base64 string
  Future<String> getPublicKeyString() async {
    final publicKeyB64 = await _secureStorage.read(key: _publicKeyKey);
    if (publicKeyB64 == null) {
      throw Exception('No public key found');
    }
    return publicKeyB64;
  }

  /// Restore identity from recovery phrase
  Future<String> restoreFromPhrase(String recoveryPhrase) async {
    // Validate phrase
    if (!bip39.validateMnemonic(recoveryPhrase)) {
      throw Exception('Invalid recovery phrase');
    }

    // Derive seed from mnemonic
    final seed = bip39.mnemonicToSeed(recoveryPhrase);
    
    // Generate Ed25519 keypair from seed
    final keyPair = await _algorithm.newKeyPairFromSeed(seed.sublist(0, 32));
    
    // Extract keys
    final publicKey = await keyPair.extractPublicKey();
    final privateKeyData = await keyPair.extractPrivateKeyBytes();
    final publicKeyBytes = publicKey.bytes;
    
    // Generate Session ID
    final sessionId = '05${HEX.encode(publicKeyBytes)}';
    
    // Store restored identity
    await _secureStorage.write(
      key: _privateKeyKey,
      value: base64Encode(privateKeyData),
    );
    await _secureStorage.write(
      key: _publicKeyKey,
      value: base64Encode(publicKeyBytes),
    );
    await _secureStorage.write(
      key: _sessionIdKey,
      value: sessionId,
    );
    await _secureStorage.write(
      key: _recoveryPhraseKey,
      value: recoveryPhrase,
    );
    
    return sessionId;
  }

  /// Generate RSA-2048 keypair for message encryption
  Future<pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey>> generateRSAKeyPair() async {
    return Future(() {
      final keyGen = pc.RSAKeyGenerator();
      final secureRandom = _getSecureRandom();
      
      keyGen.init(
        pc.ParametersWithRandom(
          pc.RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
          secureRandom,
        ),
      );
      
      final keyPair = keyGen.generateKeyPair();
      return keyPair as pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey>;
    });
  }

  /// Encrypt message with AES-256-GCM
  Future<Map<String, dynamic>> encryptMessage(
    String plaintext,
    List<int> recipientPublicKey,
  ) async {
    // Generate random AES key (32 bytes for AES-256)
    final aesKey = _generateRandomBytes(32);
    
    // Generate random nonce (12 bytes for GCM)
    final nonce = _generateRandomBytes(12);
    
    // Encrypt message with AES-256-GCM
    final algorithm = AesGcm.with256bits();
    final secretKey = SecretKey(aesKey);
    
    final secretBox = await algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: nonce,
    );
    
    // Encrypt AES key with recipient's public key (RSA)
    // For now, we'll return the encrypted message and key
    // In production, you'd use RSA to encrypt the AES key
    
    return {
      'ciphertext': base64Encode(secretBox.cipherText),
      'nonce': base64Encode(secretBox.nonce),
      'mac': base64Encode(secretBox.mac.bytes),
      'aesKey': base64Encode(aesKey), // In production, encrypt this with RSA
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Decrypt message with AES-256-GCM
  Future<String> decryptMessage(Map<String, dynamic> encryptedData) async {
    try {
      final ciphertext = base64Decode(encryptedData['ciphertext'] as String);
      final nonceBytes = base64Decode(encryptedData['nonce'] as String);
      final macBytes = base64Decode(encryptedData['mac'] as String);
      final aesKey = base64Decode(encryptedData['aesKey'] as String);
      
      final algorithm = AesGcm.with256bits();
      final secretKey = SecretKey(aesKey);
      
      final secretBox = SecretBox(
        ciphertext,
        nonce: nonceBytes,
        mac: Mac(macBytes),
      );
      
      final decrypted = await algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );
      
      return utf8.decode(decrypted);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  /// Generate secure random bytes
  List<int> _generateRandomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  /// Get secure random number generator for RSA
  pc.SecureRandom _getSecureRandom() {
    final secureRandom = pc.FortunaRandom();
    final random = Random.secure();
    final seeds = List<int>.generate(32, (_) => random.nextInt(256));
    secureRandom.seed(pc.KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }

  /// Clear all stored keys (logout/delete account)
  Future<void> clearIdentity() async {
    await _secureStorage.deleteAll();
  }

  /// Get public key for sharing with contacts
  Future<String?> getPublicKey() async {
    return await _secureStorage.read(key: _publicKeyKey);
  }

  /// Verify Session ID format
  bool isValidSessionId(String sessionId) {
    // Session ID must be 66 characters: "05" + 64 hex chars
    if (sessionId.length != 66) return false;
    if (!sessionId.startsWith('05')) return false;
    
    // Check if remaining characters are valid hex
    try {
      HEX.decode(sessionId.substring(2));
      return true;
    } catch (e) {
      return false;
    }
  }
}
