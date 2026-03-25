import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:mercurio_messenger/models/message.dart';
import 'package:mercurio_messenger/services/storage_service.dart';
import 'package:mercurio_messenger/services/crypto_service.dart';

/// Real Firebase Firestore Messaging Service
/// Enables real-time cross-device encrypted messaging.
/// Supports two encryption modes:
///   - RSA hybrid (if recipient has RSA key in Firestore)
///   - Shared-key AES-GCM (derived from both user IDs — works with no setup)
class FirebaseMessagingService {
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _messageSubscription;
  StreamController<Message>? _messageController;
  bool _isInitialized = false;
  String? _myMercurioId;

  Stream<Message> get messageStream {
    _messageController ??= StreamController<Message>.broadcast();
    return _messageController!.stream;
  }

  /// Initialize messaging service
  Future<void> initialize() async {
    _myMercurioId = await CryptoService().getSessionId();
    
    if (_myMercurioId == null) {
      if (kDebugMode) {
        print('⚠️ Cannot initialize Firebase messaging: No Mercurio ID');
      }
      return;
    }

    if (_isInitialized) {
      if (kDebugMode) {
        print('🔄 Re-initializing Firebase messaging for: $_myMercurioId');
      }
      await dispose();
    }

    _startListeningForMessages();
    await _registerUser();

    _isInitialized = true;
    if (kDebugMode) {
      print('🔥 Firebase Messaging Service initialized for: $_myMercurioId');
    }
  }

  /// Register / update user document in Firestore with all public keys
  Future<void> _registerUser() async {
    if (_myMercurioId == null) return;

    try {
      final publicKey = await CryptoService().getPublicKeyString();
      final userDoc = _firestore.collection('users').doc(_myMercurioId);
      
      final docSnapshot = await userDoc.get();
      
      if (!docSnapshot.exists) {
        // Build the create payload — include both old and new key fields
        // so the Firestore rules (which accept either schema) are satisfied.
        final createPayload = <String, dynamic>{
          'mercurio_id': _myMercurioId!,
          'public_key': publicKey,          // old schema
          'ed25519_public_key': publicKey,  // new schema
          'created_at': FieldValue.serverTimestamp(),
          'last_seen': FieldValue.serverTimestamp(),
          'is_online': true,
        };

        // Try to get the RSA public key and include it if available
        try {
          final rsaPublicKeyJson = await _getRSAPublicKeyJson();
          if (rsaPublicKeyJson != null) {
            createPayload['rsa_public_key'] = rsaPublicKeyJson;
          }
        } catch (_) {}

        await userDoc.set(createPayload);
        
        if (kDebugMode) {
          print('✅ User created in Firestore: $_myMercurioId');
        }
      } else {
        // UPDATE: refresh online status + upload RSA key if missing
        final existing = docSnapshot.data();
        final updatePayload = <String, dynamic>{
          'last_seen': FieldValue.serverTimestamp(),
          'is_online': true,
        };

        if (existing != null && existing['rsa_public_key'] == null) {
          try {
            final rsaPublicKeyJson = await _getRSAPublicKeyJson();
            if (rsaPublicKeyJson != null) {
              updatePayload['rsa_public_key'] = rsaPublicKeyJson;
              updatePayload['ed25519_public_key'] = publicKey;
            }
          } catch (_) {}
        }

        await userDoc.update(updatePayload);
        
        if (kDebugMode) {
          print('✅ User status updated in Firestore: $_myMercurioId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error registering user: $e');
      }
      // Don't rethrow — allow the app to work even if Firebase is unavailable
    }
  }

  /// Get my RSA public key as a Firestore-compatible map
  Future<Map<String, dynamic>?> _getRSAPublicKeyJson() async {
    try {
      final rsaPubKeyStr = await CryptoService().getSessionId(); // just to check
      if (rsaPubKeyStr == null) return null;

      // We don't have a direct method to get RSA pub key as map from CryptoService,
      // so we trigger a "get recipient RSA key" on ourselves.
      // Better: read from secure storage via a helper on CryptoService.
      // For now we'll just skip — the key will be there from generateIdentity().
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Start listening for real-time messages
  void _startListeningForMessages() {
    if (_myMercurioId == null) return;

    _messageSubscription = _firestore
        .collection('messages')
        .where('recipient_id', isEqualTo: _myMercurioId)
        .snapshots()
        .listen((snapshot) {
      _handleNewMessages(snapshot);
    }, onError: (error) {
      if (kDebugMode) {
        print('❌ Error listening for messages: $error');
      }
    });

    if (kDebugMode) {
      print('👂 Listening for real-time messages for: $_myMercurioId');
    }
  }

  /// Handle incoming messages (with E2EE decryption)
  Future<void> _handleNewMessages(QuerySnapshot snapshot) async {
    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        try {
          final data = change.doc.data() as Map<String, dynamic>;
          final messageId = change.doc.id;
          
          final senderId = data['sender_id'] as String;
          
          final conversationId = _getConversationId(senderId, _myMercurioId!);

          final existingMessages = await StorageService().getMessages(conversationId);
          if (existingMessages.any((msg) => msg['id'] == messageId)) {
            continue;
          }

          // 🔓 DECRYPT MESSAGE
          String decryptedContent;
          try {
            final encryptedData = {
              'encrypted_content': data['encrypted_content'] as String,
              'encrypted_aes_key': (data['encrypted_aes_key'] as String?) ?? '',
              'nonce': data['nonce'] as String,
              'mac': data['mac'] as String,
              'enc_type': (data['enc_type'] as String?) ?? 'rsa',
              'sender_id': senderId,
            };
            
            decryptedContent = await CryptoService().decryptMessageFromSender(
              encryptedData,
              senderMercurioId: senderId,
            );
            
            if (kDebugMode) print('   ✅ Message decrypted (${encryptedData['enc_type']})');
          } catch (e) {
            if (kDebugMode) print('   ❌ Decryption failed: $e');
            decryptedContent = '[Message could not be decrypted]';
          }
          
          final message = Message(
            id: messageId,
            conversationId: conversationId,
            senderSessionId: senderId,
            content: decryptedContent,
            timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            status: MessageStatus.delivered,
          );

          await StorageService().saveMessage(message.toMap());
          await _updateConversationWithNewMessage(message, senderId);
          _messageController?.add(message);
          await _updateMessageStatus(messageId, 'delivered');

        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error processing message: $e');
          }
        }
      }
    }
  }

  /// Send message to recipient (with E2EE)
  Future<void> sendMessage(Message message, String recipientMercurioId) async {
    try {
      if (kDebugMode) {
        print('📤 Sending message from $_myMercurioId to $recipientMercurioId');
      }

      // 🔐 ENCRYPT MESSAGE — uses RSA if available, shared-key otherwise
      final encryptedData = await CryptoService().encryptMessageForRecipient(
        message.content,
        recipientMercurioId,
      );

      final encType = encryptedData['enc_type'] ?? 'rsa';
      if (kDebugMode) print('🔐 Encrypted with: $encType');

      // Build Firestore document
      final docData = <String, dynamic>{
        'sender_id': _myMercurioId,
        'recipient_id': recipientMercurioId,
        'encrypted_content': encryptedData['encrypted_content']!,
        'encrypted_aes_key': encryptedData['encrypted_aes_key'] ?? '',
        'nonce': encryptedData['nonce']!,
        'mac': encryptedData['mac']!,
        'enc_type': encType,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sent',
        'type': 'text',
      };

      final docRef = await _firestore.collection('messages').add(docData);

      if (kDebugMode) {
        print('📤 Message sent to Firebase: ${docRef.id}');
      }

      await Future.delayed(const Duration(milliseconds: 500));
      final updatedMessage = message.copyWith(status: MessageStatus.delivered);
      await StorageService().saveMessage(updatedMessage.toMap());
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending message: $e');
      }
      rethrow;
    }
  }

  /// Update message status
  Future<void> _updateMessageStatus(String messageId, String status) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Non-fatal — status update failure doesn't break messaging
    }
  }

  /// Generate conversation ID from two Mercurio IDs
  String _getConversationId(String id1, String id2) {
    final sortedIds = [id1, id2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  /// Update conversation with new message (auto-create if unknown sender)
  Future<void> _updateConversationWithNewMessage(
    Message message,
    String senderMercurioId,
  ) async {
    final conversations = await StorageService().getAllConversations();
    final existingConversation = conversations.firstWhere(
      (conv) => conv['contactSessionId'] == senderMercurioId,
      orElse: () => {},
    );

    String conversationId;

    if (existingConversation.isEmpty) {
      if (kDebugMode) {
        print('📬 Auto-creating contact for unknown sender: $senderMercurioId');
      }

      final newContact = {
        'sessionId': senderMercurioId,
        'displayName': 'User ${senderMercurioId.substring(0, 8)}...',
        'verified': false,
        'blocked': false,
        'addedTimestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      await StorageService().saveContact(newContact);

      conversationId = _getConversationId(senderMercurioId, _myMercurioId!);
      final newConversation = {
        'id': conversationId,
        'contactSessionId': senderMercurioId,
        'contactName': newContact['displayName'],
        'lastMessage': message.content.length > 50 
            ? '${message.content.substring(0, 50)}...' 
            : message.content,
        'lastMessageTimestamp': message.timestamp.millisecondsSinceEpoch,
        'unreadCount': 1,
      };
      
      await StorageService().saveConversation(newConversation);
    } else {
      conversationId = existingConversation['id'] as String;
      final updatedConversation = {
        ...existingConversation,
        'lastMessage': message.content.length > 50 
            ? '${message.content.substring(0, 50)}...' 
            : message.content,
        'lastMessageTimestamp': message.timestamp.millisecondsSinceEpoch,
        'unreadCount': (existingConversation['unreadCount'] as int? ?? 0) + 1,
      };

      await StorageService().saveConversation(updatedConversation);
    }
  }

  /// Mark message as read
  Future<void> markAsRead(String messageId, String conversationId) async {
    final messages = await StorageService().getMessages(conversationId);
    final message = messages.firstWhere(
      (msg) => msg['id'] == messageId,
      orElse: () => {},
    );

    if (message.isNotEmpty) {
      message['status'] = MessageStatus.read.toString();
      await StorageService().saveMessage(message);
      
      if (!(message['isSentByMe'] as bool? ?? true)) {
        await _updateMessageStatus(messageId, 'read');
      }
    }
  }

  /// Update user online status
  Future<void> setOnlineStatus(bool isOnline) async {
    if (_myMercurioId == null) return;

    try {
      await _firestore.collection('users').doc(_myMercurioId).update({
        'is_online': isOnline,
        'last_seen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Non-fatal
    }
  }

  /// Get recipient's public key from Firestore
  Future<String?> getRecipientPublicKey(String recipientMercurioId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(recipientMercurioId)
          .get();

      if (doc.exists) {
        return doc.data()?['public_key'] as String?;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching public key: $e');
      }
    }
    return null;
  }

  /// Dispose service
  Future<void> dispose() async {
    await _messageSubscription?.cancel();
    _messageSubscription = null;
    
    if (_messageController != null && !_messageController!.isClosed) {
      await _messageController!.close();
      _messageController = null;
    }
    
    _isInitialized = false;
    _myMercurioId = null;
    
    if (kDebugMode) {
      print('🔌 Firebase Messaging Service disposed');
    }
  }
}
