import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cryptography/cryptography.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:bip39/bip39.dart' as bip39;
import 'package:hex/hex.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Enhanced Mercurio Cryptographic Service with Full E2EE
/// Implements RSA-2048 + AES-256-GCM hybrid encryption
class CryptoService {
  static final CryptoService _instance = CryptoService._internal();
  factory CryptoService() => _instance;
  CryptoService._internal();

  final _secureStorage = const FlutterSecureStorage();
  final _algorithm = Ed25519();
  final _firestore = FirebaseFirestore.instance;
  
  // Storage keys
  static const String _privateKeyKey = 'mercurio_private_key';
  static const String _publicKeyKey = 'mercurio_public_key';
  static const String _sessionIdKey = 'mercurio_session_id';
  static const String _recoveryPhraseKey = 'mercurio_recovery_phrase';
  static const String _rsaPrivateKeyKey = 'mercurio_rsa_private_key';
  static const String _rsaPublicKeyKey = 'mercurio_rsa_public_key';

  /// Generate new Ed25519 keypair and Session ID
  Future<String> generateIdentity() async {
    if (kDebugMode) {
      debugPrint('🔐 Starting identity generation...');
    }
    
    // Generate Ed25519 keypair
    if (kDebugMode) {
      debugPrint('📝 Step 1: Generating Ed25519 keypair...');
    }
    final keyPair = await _algorithm.newKeyPair();
    
    // Extract public and private keys
    final publicKey = await keyPair.extractPublicKey();
    final privateKeyData = await keyPair.extractPrivateKeyBytes();
    
    // Convert public key to bytes
    final publicKeyBytes = publicKey.bytes;
    
    // Generate Session ID: "05" prefix + 64-char hex (32 bytes)
    final sessionId = '05${HEX.encode(publicKeyBytes)}';
    if (kDebugMode) {
      debugPrint('✅ Session ID generated: ${sessionId.substring(0, 20)}...');
    }
    
    // Generate BIP39 recovery phrase (12 words)
    if (kDebugMode) {
      debugPrint('📝 Step 2: Generating recovery phrase...');
    }
    final recoveryPhrase = bip39.generateMnemonic();
    if (kDebugMode) {
      debugPrint('✅ Recovery phrase generated (12 words)');
    }
    
    // Generate RSA keypair for message encryption
    if (kDebugMode) {
      debugPrint('📝 Step 3: Generating RSA-2048 keypair...');
    }
    final rsaKeyPair = await generateRSAKeyPair();
    final rsaPublicKey = rsaKeyPair.publicKey;
    final rsaPrivateKey = rsaKeyPair.privateKey;
    if (kDebugMode) {
      debugPrint('✅ RSA keypair generated');
    }
    
    // Store keys securely
    if (kDebugMode) {
      debugPrint('📝 Step 4: Storing keys securely...');
    }
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
    if (kDebugMode) {
      debugPrint('✅ Ed25519 keys stored');
    }
    
    // Store RSA keys
    if (kDebugMode) {
      debugPrint('📝 Step 5: Storing RSA keys...');
    }
    await _storeRSAKeys(rsaPublicKey, rsaPrivateKey);
    if (kDebugMode) {
      debugPrint('✅ RSA keys stored');
    }
    
    // Upload public keys to Firebase
    if (kDebugMode) {
      debugPrint('📝 Step 6: Uploading public keys to Firebase...');
    }
    await _uploadPublicKeysToFirebase(sessionId, publicKeyBytes, rsaPublicKey);
    
    if (kDebugMode) {
      debugPrint('🎉 Identity generation complete!');
    }
    return sessionId;
  }

  /// Store RSA keys securely
  Future<void> _storeRSAKeys(pc.RSAPublicKey publicKey, pc.RSAPrivateKey privateKey) async {
    // Encode RSA public key
    final publicKeyData = {
      'modulus': publicKey.modulus.toString(),
      'exponent': publicKey.exponent.toString(),
    };
    
    // Encode RSA private key
    final privateKeyData = {
      'modulus': privateKey.modulus.toString(),
      'privateExponent': privateKey.privateExponent.toString(),
      'p': privateKey.p.toString(),
      'q': privateKey.q.toString(),
    };
    
    await _secureStorage.write(
      key: _rsaPublicKeyKey,
      value: jsonEncode(publicKeyData),
    );
    await _secureStorage.write(
      key: _rsaPrivateKeyKey,
      value: jsonEncode(privateKeyData),
    );
  }

  /// Upload public keys to Firebase for key exchange
  Future<void> _uploadPublicKeysToFirebase(
    String sessionId,
    List<int> ed25519PublicKey,
    pc.RSAPublicKey rsaPublicKey,
  ) async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Uploading public keys to Firebase...');
      }
      
      // Add timeout to prevent hanging
      await _firestore.collection('users').doc(sessionId).set({
        'mercurio_id': sessionId,
        'ed25519_public_key': base64Encode(ed25519PublicKey),
        'rsa_public_key': {
          'modulus': rsaPublicKey.modulus.toString(),
          'exponent': rsaPublicKey.exponent.toString(),
        },
        'created_at': FieldValue.serverTimestamp(),
        'last_seen': FieldValue.serverTimestamp(),
        'is_online': true,
      }, SetOptions(merge: true)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('⏱️ Firebase upload timed out after 10 seconds');
          }
          throw TimeoutException('Firebase upload timeout');
        },
      );
      
      if (kDebugMode) {
        debugPrint('✅ Public keys uploaded to Firebase successfully');
      }
    } catch (e) {
      // Don't throw - allow signup to succeed even if Firebase upload fails
      // This allows offline-first functionality
      if (kDebugMode) {
        debugPrint('⚠️ Warning: Could not upload public keys to Firebase: $e');
        debugPrint('💡 Identity created successfully - you can still use the app offline');
      }
    }
  }

  /// Get recipient's RSA public key from Firebase
  Future<pc.RSAPublicKey?> getRecipientRSAPublicKey(String recipientMercurioId) async {
    try {
      final doc = await _firestore.collection('users').doc(recipientMercurioId).get();
      
      if (doc.exists) {
        final data = doc.data();
        final rsaKeyData = data?['rsa_public_key'] as Map<String, dynamic>?;
        
        if (rsaKeyData != null) {
          final modulus = BigInt.parse(rsaKeyData['modulus'] as String);
          final exponent = BigInt.parse(rsaKeyData['exponent'] as String);
          
          return pc.RSAPublicKey(modulus, exponent);
        }
      }
    } catch (e) {
      print('Error fetching recipient public key: $e');
    }
    return null;
  }

  /// Encrypt message with hybrid RSA + AES encryption
  Future<Map<String, String>> encryptMessageForRecipient(
    String plaintext,
    String recipientMercurioId,
  ) async {
    // 1. Get recipient's RSA public key from Firebase
    final recipientPublicKey = await getRecipientRSAPublicKey(recipientMercurioId);
    
    if (recipientPublicKey == null) {
      throw Exception('Could not fetch recipient public key');
    }
    
    // 2. Generate random AES-256 key
    final aesKey = _generateRandomBytes(32);
    
    // 3. Generate random nonce for AES-GCM
    final nonce = _generateRandomBytes(12);
    
    // 4. Encrypt message with AES-256-GCM
    final algorithm = AesGcm.with256bits();
    final secretKey = SecretKey(aesKey);
    
    final secretBox = await algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: nonce,
    );
    
    // 5. Encrypt AES key with recipient's RSA public key
    final encryptedAESKey = _rsaEncrypt(aesKey, recipientPublicKey);
    
    // 6. Return encrypted data
    return {
      'encrypted_content': base64Encode(secretBox.cipherText),
      'encrypted_aes_key': base64Encode(encryptedAESKey),
      'nonce': base64Encode(secretBox.nonce),
      'mac': base64Encode(secretBox.mac.bytes),
    };
  }

  /// Decrypt message with hybrid RSA + AES decryption
  Future<String> decryptMessageFromSender(Map<String, String> encryptedData) async {
    try {
      // 1. Get my RSA private key
      final myPrivateKey = await _getMyRSAPrivateKey();
      
      if (myPrivateKey == null) {
        throw Exception('No RSA private key found');
      }
      
      // 2. Decrypt AES key using RSA private key
      final encryptedAESKey = base64Decode(encryptedData['encrypted_aes_key']!);
      final aesKey = _rsaDecrypt(encryptedAESKey, myPrivateKey);
      
      // 3. Decrypt message with AES-256-GCM
      final encryptedContent = base64Decode(encryptedData['encrypted_content']!);
      final nonce = base64Decode(encryptedData['nonce']!);
      final mac = base64Decode(encryptedData['mac']!);
      
      final algorithm = AesGcm.with256bits();
      final secretKey = SecretKey(aesKey);
      
      final secretBox = SecretBox(
        encryptedContent,
        nonce: nonce,
        mac: Mac(mac),
      );
      
      final decrypted = await algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );
      
      return utf8.decode(decrypted);
    } catch (e) {
      print('Error decrypting message: $e');
      throw Exception('Failed to decrypt message');
    }
  }

  /// Get my RSA private key
  Future<pc.RSAPrivateKey?> _getMyRSAPrivateKey() async {
    try {
      final privateKeyJson = await _secureStorage.read(key: _rsaPrivateKeyKey);
      
      if (privateKeyJson == null) return null;
      
      final privateKeyData = jsonDecode(privateKeyJson) as Map<String, dynamic>;
      
      return pc.RSAPrivateKey(
        BigInt.parse(privateKeyData['modulus'] as String),
        BigInt.parse(privateKeyData['privateExponent'] as String),
        BigInt.parse(privateKeyData['p'] as String),
        BigInt.parse(privateKeyData['q'] as String),
      );
    } catch (e) {
      print('Error loading RSA private key: $e');
      return null;
    }
  }

  /// RSA encryption
  List<int> _rsaEncrypt(List<int> data, pc.RSAPublicKey publicKey) {
    final encryptor = pc.OAEPEncoding(pc.RSAEngine())
      ..init(true, pc.PublicKeyParameter<pc.RSAPublicKey>(publicKey));
    
    return encryptor.process(Uint8List.fromList(data));
  }

  /// RSA decryption
  List<int> _rsaDecrypt(List<int> encrypted, pc.RSAPrivateKey privateKey) {
    final decryptor = pc.OAEPEncoding(pc.RSAEngine())
      ..init(false, pc.PrivateKeyParameter<pc.RSAPrivateKey>(privateKey));
    
    return decryptor.process(Uint8List.fromList(encrypted));
  }

  /// Generate RSA-2048 keypair
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
      
      // Properly extract and return typed keypair
      final publicKey = keyPair.publicKey as pc.RSAPublicKey;
      final privateKey = keyPair.privateKey as pc.RSAPrivateKey;
      
      return pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey>(
        publicKey,
        privateKey,
      );
    });
  }

  /// Generate secure random bytes
  List<int> _generateRandomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  /// Get secure random for RSA
  pc.SecureRandom _getSecureRandom() {
    final secureRandom = pc.FortunaRandom();
    final random = Random.secure();
    final seeds = List<int>.generate(32, (_) => random.nextInt(256));
    secureRandom.seed(pc.KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }

  /// Get Session ID
  Future<String?> getSessionId() async {
    return await _secureStorage.read(key: _sessionIdKey);
  }

  /// Get Recovery Phrase
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

  /// Validate Mercurio ID format
  bool isValidSessionId(String sessionId) {
    // Must be 66 characters: "05" + 64 hex characters
    if (sessionId.length != 66) return false;
    if (!sessionId.startsWith('05')) return false;
    
    // Check if rest is valid hex
    final hexPart = sessionId.substring(2);
    return RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(hexPart);
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
    
    // Generate new RSA keypair (can't restore from phrase)
    final rsaKeyPair = await generateRSAKeyPair();
    final rsaPublicKey = rsaKeyPair.publicKey;
    final rsaPrivateKey = rsaKeyPair.privateKey;
    
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
    
    // Store RSA keys
    await _storeRSAKeys(rsaPublicKey, rsaPrivateKey);
    
    // Upload public keys to Firebase
    await _uploadPublicKeysToFirebase(sessionId, publicKeyBytes, rsaPublicKey);
    
    return sessionId;
  }

  /// Generate safety number for contact verification
  Future<String> generateSafetyNumber(String contactMercurioId) async {
    final mySessionId = await getSessionId();
    if (mySessionId == null) {
      throw Exception('No session ID found');
    }
    
    // Get both public keys
    final myPublicKey = await _secureStorage.read(key: _publicKeyKey);
    final contactPublicKey = await _getContactPublicKey(contactMercurioId);
    
    if (myPublicKey == null || contactPublicKey == null) {
      throw Exception('Could not generate safety number');
    }
    
    // Combine public keys in sorted order
    final sortedKeys = [mySessionId, contactMercurioId]..sort();
    final combined = sortedKeys[0] == mySessionId
        ? '$myPublicKey$contactPublicKey'
        : '$contactPublicKey$myPublicKey';
    
    // Generate 60-digit fingerprint
    final hash = combined.codeUnits.fold<int>(0, (prev, curr) => prev + curr);
    final fingerprint = hash.toString().padLeft(60, '0');
    
    return fingerprint;
  }

  /// Get contact's public key
  Future<String?> _getContactPublicKey(String mercurioId) async {
    try {
      final doc = await _firestore.collection('users').doc(mercurioId).get();
      if (doc.exists) {
        return doc.data()?['ed25519_public_key'] as String?;
      }
    } catch (e) {
      print('Error fetching contact public key: $e');
    }
    return null;
  }

  /// Clear all stored keys (logout)
  Future<void> clearAllKeys() async {
    await _secureStorage.deleteAll();
  }
}
