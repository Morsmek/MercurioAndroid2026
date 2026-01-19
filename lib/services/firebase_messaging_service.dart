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

    // If already initialized with different ID, restart
    if (_isInitialized) {
      if (kDebugMode) {
        print('🔄 Re-initializing Firebase messaging for: $_myMercurioId');
      }
      await dispose();
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
    // Note: Removed orderBy to avoid needing composite index
    // Firestore snapshots() will still deliver new messages in real-time
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
    if (kDebugMode) {
      print('📬 Received ${snapshot.docChanges.length} message changes');
    }

    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        try {
          final data = change.doc.data() as Map<String, dynamic>;
          final messageId = change.doc.id;
          
          if (kDebugMode) {
            print('📥 Processing new message:');
            print('   ID: $messageId');
            print('   From: ${data['sender_id']}');
            print('   To: ${data['recipient_id']}');
          }
          
          // Check if we already have this message locally
          final conversationId = _getConversationId(
            data['sender_id'] as String,
            _myMercurioId!,
          );

          final existingMessages = await StorageService().getMessages(conversationId);
          final messageExists = existingMessages.any((msg) => msg['id'] == messageId);

          if (messageExists) {
            if (kDebugMode) {
              print('   ⏭️ Message already exists locally, skipping');
            }
            continue;
          }

          if (kDebugMode) {
            print('   🔓 Decrypting message...');
          }

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
              print('   ✅ Message decrypted successfully');
            }
          } catch (e) {
            if (kDebugMode) {
              print('   ❌ Failed to decrypt message: $e');
            }
            decryptedContent = '[Encrypted message - decryption failed]';
          }
          
          // New message - save locally with DECRYPTED content
          final message = Message(
            id: messageId,
            conversationId: conversationId,
            senderSessionId: data['sender_id'] as String,
            content: decryptedContent,
            timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            status: MessageStatus.delivered,
          );

          await StorageService().saveMessage(message.toMap());
          
          if (kDebugMode) {
            print('   💾 Message saved locally');
          }
          
          // Update conversation
          await _updateConversationWithNewMessage(
            message,
            data['sender_id'] as String,
          );

          // Notify listeners
          _messageController?.add(message);

          // Update message status to delivered
          await _updateMessageStatus(messageId, 'delivered');

          if (kDebugMode) {
            print('   ✅ Message processing complete');
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
      if (kDebugMode) {
        print('📤 Sending message from $_myMercurioId to $recipientMercurioId');
      }

      // 🔐 ENCRYPT MESSAGE WITH E2EE
      final encryptedData = await CryptoService().encryptMessageForRecipient(
        message.content,
        recipientMercurioId,
      );

      if (kDebugMode) {
        print('🔐 Message encrypted with E2EE');
      }

      // Upload ENCRYPTED message to Firestore
      final docRef = await _firestore.collection('messages').add({
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
        print('📤 Encrypted message sent to Firebase with ID: ${docRef.id}');
        print('   From: $_myMercurioId');
        print('   To: $recipientMercurioId');
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

    String conversationId;

    if (existingConversation.isEmpty) {
      // NEW: Auto-create contact and conversation for unknown sender
      if (kDebugMode) {
        print('📬 Received message from unknown contact: $senderMercurioId');
        print('   Creating contact and conversation automatically...');
      }

      // Create contact with Session ID as display name (user can rename later)
      final newContact = {
        'sessionId': senderMercurioId,
        'displayName': 'User ${senderMercurioId.substring(0, 8)}...',
        'verified': false,
        'blocked': false,
        'addedTimestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      await StorageService().saveContact(newContact);
      
      if (kDebugMode) {
        print('   ✅ Contact created');
      }

      // Create conversation
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
      
      if (kDebugMode) {
        print('   ✅ Conversation created with ID: $conversationId');
      }
    } else {
      // Existing conversation - just update it
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
