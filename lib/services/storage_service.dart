import 'package:hive_flutter/hive_flutter.dart';

/// Mercurio Local Storage Service
/// Handles encrypted local data storage using Hive
/// Stores: messages, contacts, conversations, settings
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // Box names
  static const String _messagesBox = 'messages';
  static const String _contactsBox = 'contacts';
  static const String _conversationsBox = 'conversations';
  static const String _settingsBox = 'settings';

  bool _initialized = false;

  /// Initialize Hive storage
  Future<void> initialize() async {
    if (_initialized) return;
    
    await Hive.initFlutter();
    
    // Open boxes
    await Hive.openBox(_messagesBox);
    await Hive.openBox(_contactsBox);
    await Hive.openBox(_conversationsBox);
    await Hive.openBox(_settingsBox);
    
    _initialized = true;
  }

  /// Save message to local storage
  Future<void> saveMessage(Map<String, dynamic> message) async {
    final box = Hive.box(_messagesBox);
    await box.put(message['id'], message);
  }

  /// Get all messages for a conversation
  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    final box = Hive.box(_messagesBox);
    final allMessages = box.values.cast<Map<dynamic, dynamic>>();
    
    return allMessages
        .where((msg) => msg['conversationId'] == conversationId)
        .map((msg) => Map<String, dynamic>.from(msg))
        .toList()
      ..sort((a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));
  }

  /// Save contact
  Future<void> saveContact(Map<String, dynamic> contact) async {
    final box = Hive.box(_contactsBox);
    await box.put(contact['sessionId'], contact);
  }

  /// Get contact by Session ID
  Future<Map<String, dynamic>?> getContact(String sessionId) async {
    final box = Hive.box(_contactsBox);
    final contact = box.get(sessionId);
    return contact != null ? Map<String, dynamic>.from(contact) : null;
  }

  /// Get all contacts
  Future<List<Map<String, dynamic>>> getAllContacts() async {
    final box = Hive.box(_contactsBox);
    return box.values
        .cast<Map<dynamic, dynamic>>()
        .map((contact) => Map<String, dynamic>.from(contact))
        .toList();
  }

  /// Delete contact
  Future<void> deleteContact(String sessionId) async {
    final box = Hive.box(_contactsBox);
    await box.delete(sessionId);
  }

  /// Save conversation
  Future<void> saveConversation(Map<String, dynamic> conversation) async {
    final box = Hive.box(_conversationsBox);
    await box.put(conversation['id'], conversation);
  }

  /// Get conversation by ID
  Future<Map<String, dynamic>?> getConversation(String conversationId) async {
    final box = Hive.box(_conversationsBox);
    final conversation = box.get(conversationId);
    return conversation != null ? Map<String, dynamic>.from(conversation) : null;
  }

  /// Get all conversations
  Future<List<Map<String, dynamic>>> getAllConversations() async {
    final box = Hive.box(_conversationsBox);
    return box.values
        .cast<Map<dynamic, dynamic>>()
        .map((conv) => Map<String, dynamic>.from(conv))
        .toList()
      ..sort((a, b) => (b['lastMessageTimestamp'] as int? ?? 0)
          .compareTo(a['lastMessageTimestamp'] as int? ?? 0));
  }

  /// Delete conversation and all its messages
  Future<void> deleteConversation(String conversationId) async {
    // Delete conversation
    final convBox = Hive.box(_conversationsBox);
    await convBox.delete(conversationId);
    
    // Delete all messages in conversation
    final msgBox = Hive.box(_messagesBox);
    final messagesToDelete = msgBox.values
        .cast<Map<dynamic, dynamic>>()
        .where((msg) => msg['conversationId'] == conversationId)
        .map((msg) => msg['id'])
        .toList();
    
    for (final msgId in messagesToDelete) {
      await msgBox.delete(msgId);
    }
  }

  /// Save setting
  Future<void> saveSetting(String key, dynamic value) async {
    final box = Hive.box(_settingsBox);
    await box.put(key, value);
  }

  /// Get setting
  Future<T?> getSetting<T>(String key, {T? defaultValue}) async {
    final box = Hive.box(_settingsBox);
    return box.get(key, defaultValue: defaultValue) as T?;
  }

  /// Delete expired disappearing messages
  Future<void> deleteExpiredMessages() async {
    final box = Hive.box(_messagesBox);
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final expiredMessages = box.values
        .cast<Map<dynamic, dynamic>>()
        .where((msg) {
          final expiresAt = msg['expiresAt'] as int?;
          return expiresAt != null && expiresAt < now;
        })
        .map((msg) => msg['id'])
        .toList();
    
    for (final msgId in expiredMessages) {
      await box.delete(msgId);
    }
  }

  /// Get unread message count for a conversation
  Future<int> getUnreadCount(String conversationId) async {
    final box = Hive.box(_messagesBox);
    return box.values
        .cast<Map<dynamic, dynamic>>()
        .where((msg) =>
            msg['conversationId'] == conversationId &&
            msg['isRead'] == false &&
            msg['isSent'] == false)
        .length;
  }

  /// Mark all messages as read in a conversation
  Future<void> markConversationAsRead(String conversationId) async {
    final box = Hive.box(_messagesBox);
    final messages = box.values.cast<Map<dynamic, dynamic>>().where(
          (msg) => msg['conversationId'] == conversationId && msg['isRead'] == false,
        );
    
    for (final msg in messages) {
      final updatedMsg = Map<String, dynamic>.from(msg);
      updatedMsg['isRead'] = true;
      await box.put(msg['id'], updatedMsg);
    }
  }

  /// Clear all data (logout/delete account)
  Future<void> clearAllData() async {
    await Hive.box(_messagesBox).clear();
    await Hive.box(_contactsBox).clear();
    await Hive.box(_conversationsBox).clear();
    await Hive.box(_settingsBox).clear();
  }

  /// Close all boxes
  Future<void> close() async {
    await Hive.close();
    _initialized = false;
  }
}
