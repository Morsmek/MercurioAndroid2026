import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mercurio_messenger/models/message.dart';
import 'package:mercurio_messenger/services/storage_service.dart';
import 'package:mercurio_messenger/services/crypto_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Firebase-like Messaging Service
/// For demo: Uses SharedPreferences + polling to simulate real-time sync
/// In production: Would use actual Firebase Firestore with real-time listeners
class FirebaseMessagingService {
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  Timer? _pollingTimer;
  final _messageController = StreamController<Message>.broadcast();
  bool _isInitialized = false;
  String? _myMercurioId;

  Stream<Message> get messageStream => _messageController.stream;

  /// Initialize messaging service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _myMercurioId = await CryptoService().getSessionId();
    
    // Start polling for new messages every 2 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkForNewMessages();
    });

    _isInitialized = true;
    if (kDebugMode) {
      print('🔥 Firebase Messaging Service initialized');
    }
  }

  /// Send message to recipient
  Future<void> sendMessage(Message message, String recipientMercurioId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Create a global message key using timestamp + sender + recipient
      final messageKey = 'msg_${recipientMercurioId}_${message.id}';
      
      // Store message data
      final messageData = {
        ...message.toMap(),
        'recipientMercurioId': recipientMercurioId,
        'senderMercurioId': _myMercurioId,
      };
      
      await prefs.setString(messageKey, jsonEncode(messageData));
      
      if (kDebugMode) {
        print('📤 Message sent: ${message.content.substring(0, 20)}...');
      }

      // Mark as delivered
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

  /// Check for new messages (polling)
  Future<void> _checkForNewMessages() async {
    if (_myMercurioId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      
      // Find messages for this user
      final myMessageKeys = allKeys.where((key) => 
        key.startsWith('msg_$_myMercurioId')
      ).toList();

      for (final key in myMessageKeys) {
        final messageJson = prefs.getString(key);
        if (messageJson != null) {
          try {
            final messageData = jsonDecode(messageJson) as Map<String, dynamic>;
            final senderMercurioId = messageData['senderMercurioId'] as String?;
            
            // Skip if it's our own message
            if (senderMercurioId == _myMercurioId) {
              continue;
            }

            // Check if we already have this message
            final existingMessages = await StorageService().getMessages(
              messageData['conversationId'] as String
            );
            
            final messageExists = existingMessages.any(
              (msg) => msg['id'] == messageData['id']
            );

            if (!messageExists) {
              // New message! Save it locally
              final receivedMessage = Message.fromMap(messageData);
              await StorageService().saveMessage(receivedMessage.toMap());
              
              // Update conversation
              await _updateConversationWithNewMessage(receivedMessage, senderMercurioId!);
              
              // Notify listeners
              _messageController.add(receivedMessage);
              
              if (kDebugMode) {
                print('📥 New message received: ${receivedMessage.content.substring(0, 20)}...');
              }
              
              // Clean up - remove from shared storage
              await prefs.remove(key);
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Error processing message: $e');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking messages: $e');
      }
    }
  }

  Future<void> _updateConversationWithNewMessage(
    Message message,
    String senderMercurioId,
  ) async {
    // Find or create conversation
    final conversations = await StorageService().getAllConversations();
    final existingConversation = conversations.firstWhere(
      (conv) => conv['contactSessionId'] == senderMercurioId,
      orElse: () => {},
    );

    if (existingConversation.isEmpty) {
      // No conversation exists - contact might not be added yet
      if (kDebugMode) {
        print('⚠️ Received message from unknown contact: $senderMercurioId');
      }
      return;
    }

    // Update conversation
    final conversationId = existingConversation['id'] as String;
    final updatedConversation = {
      ...existingConversation,
      'lastMessage': message.content,
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
    }
  }

  /// Clean up old messages (optional)
  Future<void> cleanupOldMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      
      // Remove messages older than 7 days
      final cutoffTime = DateTime.now().subtract(const Duration(days: 7));
      
      for (final key in allKeys) {
        if (key.startsWith('msg_')) {
          final messageJson = prefs.getString(key);
          if (messageJson != null) {
            try {
              final messageData = jsonDecode(messageJson) as Map<String, dynamic>;
              final timestamp = DateTime.fromMillisecondsSinceEpoch(
                messageData['timestamp'] as int
              );
              
              if (timestamp.isBefore(cutoffTime)) {
                await prefs.remove(key);
              }
            } catch (e) {
              // Invalid message, remove it
              await prefs.remove(key);
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error cleaning up messages: $e');
      }
    }
  }

  /// Dispose service
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.close();
    _isInitialized = false;
  }
}
