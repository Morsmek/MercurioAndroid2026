import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:mercurio_messenger/models/message.dart';
import 'package:mercurio_messenger/services/storage_service.dart';
import 'package:mercurio_messenger/services/crypto_service.dart';

/// Real Firebase Firestore Messaging Service
/// Enables real-time cross-device encrypted messaging
class FirebaseMessagingService {
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _messageSubscription;
  final _messageController = StreamController<Message>.broadcast();
  bool _isInitialized = false;
  String? _myMercurioId;

  Stream<Message> get messageStream => _messageController.stream;

  /// Initialize messaging service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _myMercurioId = await CryptoService().getSessionId();
    
    if (_myMercurioId == null) {
      if (kDebugMode) {
        print('⚠️ Cannot initialize Firebase messaging: No Mercurio ID');
      }
      return;
    }

    // Listen for real-time messages from Firestore
    _startListeningForMessages();

    // Register user in Firestore
    await _registerUser();

    _isInitialized = true;
    if (kDebugMode) {
      print('🔥 Firebase Messaging Service initialized for: $_myMercurioId');
    }
  }

  /// Register user in Firestore users collection
  Future<void> _registerUser() async {
    if (_myMercurioId == null) return;

    try {
      final publicKey = await CryptoService().getPublicKeyString();
      
      await _firestore.collection('users').doc(_myMercurioId).set({
        'mercurio_id': _myMercurioId,
        'public_key': publicKey,
        'last_seen': FieldValue.serverTimestamp(),
        'is_online': true,
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        print('✅ User registered in Firestore');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error registering user: $e');
      }
    }
  }

  /// Start listening for real-time messages
  void _startListeningForMessages() {
    if (_myMercurioId == null) return;

    // Listen for messages where we are the recipient
    _messageSubscription = _firestore
        .collection('messages')
        .where('recipient_id', isEqualTo: _myMercurioId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      _handleNewMessages(snapshot);
    });

    if (kDebugMode) {
      print('👂 Listening for real-time messages...');
    }
  }

  /// Handle incoming messages (with E2EE decryption)
  Future<void> _handleNewMessages(QuerySnapshot snapshot) async {
    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        try {
          final data = change.doc.data() as Map<String, dynamic>;
          
          // Check if we already have this message locally
          final messageId = change.doc.id;
          final conversationId = _getConversationId(
            data['sender_id'] as String,
            _myMercurioId!,
          );

          final existingMessages = await StorageService().getMessages(conversationId);
          final messageExists = existingMessages.any((msg) => msg['id'] == messageId);

          if (!messageExists) {
            // 🔓 DECRYPT MESSAGE WITH E2EE
            String decryptedContent;
            try {
              final encryptedData = {
                'encrypted_content': data['encrypted_content'] as String,
                'encrypted_aes_key': data['encrypted_aes_key'] as String,
                'nonce': data['nonce'] as String,
                'mac': data['mac'] as String,
              };
              
              decryptedContent = await CryptoService().decryptMessageFromSender(encryptedData);
              
              if (kDebugMode) {
                print('🔓 Message decrypted with E2EE');
              }
            } catch (e) {
              if (kDebugMode) {
                print('❌ Failed to decrypt message: $e');
              }
              decryptedContent = '[Encrypted message - decryption failed]';
            }
            
            // New message - save locally with DECRYPTED content
            final message = Message(
              id: messageId,
              conversationId: conversationId,
              senderSessionId: data['sender_id'] as String,
              content: decryptedContent,
              timestamp: (data['timestamp'] as Timestamp).toDate(),
              status: MessageStatus.delivered,
            );

            await StorageService().saveMessage(message.toMap());
            
            // Update conversation
            await _updateConversationWithNewMessage(
              message,
              data['sender_id'] as String,
            );

            // Notify listeners
            _messageController.add(message);

            // Update message status to delivered
            await _updateMessageStatus(messageId, 'delivered');

            if (kDebugMode) {
              print('📥 New encrypted message received and decrypted');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error processing encrypted message: $e');
          }
        }
      }
    }
  }

  /// Send message to recipient (with E2EE)
  Future<void> sendMessage(Message message, String recipientMercurioId) async {
    try {
      // 🔐 ENCRYPT MESSAGE WITH E2EE
      final encryptedData = await CryptoService().encryptMessageForRecipient(
        message.content,
        recipientMercurioId,
      );

      if (kDebugMode) {
        print('🔐 Message encrypted with E2EE');
      }

      // Upload ENCRYPTED message to Firestore
      await _firestore.collection('messages').add({
        'sender_id': _myMercurioId,
        'recipient_id': recipientMercurioId,
        'encrypted_content': encryptedData['encrypted_content']!,
        'encrypted_aes_key': encryptedData['encrypted_aes_key']!,
        'nonce': encryptedData['nonce']!,
        'mac': encryptedData['mac']!,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sent',
        'type': 'text',
      });

      if (kDebugMode) {
        print('📤 Encrypted message sent to Firebase');
      }

      // Update local message status
      await Future.delayed(const Duration(milliseconds: 500));
      final updatedMessage = message.copyWith(status: MessageStatus.delivered);
      await StorageService().saveMessage(updatedMessage.toMap());
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending encrypted message: $e');
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
      if (kDebugMode) {
        print('⚠️ Error updating message status: $e');
      }
    }
  }

  /// Generate conversation ID from two Mercurio IDs
  String _getConversationId(String id1, String id2) {
    final sortedIds = [id1, id2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  /// Update conversation with new message
  Future<void> _updateConversationWithNewMessage(
    Message message,
    String senderMercurioId,
  ) async {
    final conversations = await StorageService().getAllConversations();
    final existingConversation = conversations.firstWhere(
      (conv) => conv['contactSessionId'] == senderMercurioId,
      orElse: () => {},
    );

    if (existingConversation.isEmpty) {
      if (kDebugMode) {
        print('⚠️ Received message from unknown contact: $senderMercurioId');
      }
      return;
    }

    final conversationId = existingConversation['id'] as String;
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

  /// Mark message as read
  Future<void> markAsRead(String messageId, String conversationId) async {
    // Update local message status
    final messages = await StorageService().getMessages(conversationId);
    final message = messages.firstWhere(
      (msg) => msg['id'] == messageId,
      orElse: () => {},
    );

    if (message.isNotEmpty) {
      message['status'] = MessageStatus.read.toString();
      await StorageService().saveMessage(message);
      
      // Update Firebase if message is from another user
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
      if (kDebugMode) {
        print('⚠️ Error updating online status: $e');
      }
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
  void dispose() {
    _messageSubscription?.cancel();
    _messageController.close();
    _isInitialized = false;
    
    // Set offline status
    setOnlineStatus(false);
  }
}
