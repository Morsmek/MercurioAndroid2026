import 'package:uuid/uuid.dart';

/// Message Model
class Message {
  final String id;
  final String conversationId;
  final String? senderSessionId; // null if sent by current user
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final DateTime? expiresAt;
  final String? replyToId;
  final bool isEdited;
  final Map<String, dynamic>? encryptedData;

  Message({
    String? id,
    required this.conversationId,
    this.senderSessionId,
    required this.content,
    this.type = MessageType.text,
    DateTime? timestamp,
    this.status = MessageStatus.sending,
    this.expiresAt,
    this.replyToId,
    this.isEdited = false,
    this.encryptedData,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  bool get isSentByMe => senderSessionId == null;
  bool get isRead => status == MessageStatus.read;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderSessionId': senderSessionId,
      'content': content,
      'type': type.toString(),
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.toString(),
      'expiresAt': expiresAt?.millisecondsSinceEpoch,
      'replyToId': replyToId,
      'isEdited': isEdited,
      'isRead': isRead,
      'isSent': isSentByMe,
      'encryptedData': encryptedData,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      conversationId: map['conversationId'] as String,
      senderSessionId: map['senderSessionId'] as String?,
      content: map['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => MessageStatus.sent,
      ),
      expiresAt: map['expiresAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['expiresAt'] as int)
          : null,
      replyToId: map['replyToId'] as String?,
      isEdited: map['isEdited'] as bool? ?? false,
      encryptedData: map['encryptedData'] as Map<String, dynamic>?,
    );
  }

  Message copyWith({
    String? content,
    MessageStatus? status,
    DateTime? expiresAt,
    bool? isEdited,
  }) {
    return Message(
      id: id,
      conversationId: conversationId,
      senderSessionId: senderSessionId,
      content: content ?? this.content,
      type: type,
      timestamp: timestamp,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      replyToId: replyToId,
      isEdited: isEdited ?? this.isEdited,
      encryptedData: encryptedData,
    );
  }
}

enum MessageType {
  text,
  image,
  voice,
  file,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}
