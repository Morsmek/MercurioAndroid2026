/// Conversation Model
class Conversation {
  final String id;
  final String contactSessionId;
  final String contactName;
  final String? contactAvatar;
  final String? lastMessage;
  final DateTime? lastMessageTimestamp;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;
  final int? disappearingTimer; // in seconds, null = off

  Conversation({
    required this.id,
    required this.contactSessionId,
    required this.contactName,
    this.contactAvatar,
    this.lastMessage,
    this.lastMessageTimestamp,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isMuted = false,
    this.disappearingTimer,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contactSessionId': contactSessionId,
      'contactName': contactName,
      'contactAvatar': contactAvatar,
      'lastMessage': lastMessage,
      'lastMessageTimestamp': lastMessageTimestamp?.millisecondsSinceEpoch,
      'unreadCount': unreadCount,
      'isPinned': isPinned,
      'isMuted': isMuted,
      'disappearingTimer': disappearingTimer,
    };
  }

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'] as String,
      contactSessionId: map['contactSessionId'] as String,
      contactName: map['contactName'] as String,
      contactAvatar: map['contactAvatar'] as String?,
      lastMessage: map['lastMessage'] as String?,
      lastMessageTimestamp: map['lastMessageTimestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map['lastMessageTimestamp'] as int)
          : null,
      unreadCount: map['unreadCount'] as int? ?? 0,
      isPinned: map['isPinned'] as bool? ?? false,
      isMuted: map['isMuted'] as bool? ?? false,
      disappearingTimer: map['disappearingTimer'] as int?,
    );
  }

  Conversation copyWith({
    String? id,
    String? contactName,
    String? contactAvatar,
    String? lastMessage,
    DateTime? lastMessageTimestamp,
    int? unreadCount,
    bool? isPinned,
    bool? isMuted,
    int? disappearingTimer,
  }) {
    return Conversation(
      id: id ?? this.id,
      contactSessionId: contactSessionId,
      contactName: contactName ?? this.contactName,
      contactAvatar: contactAvatar ?? this.contactAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      disappearingTimer: disappearingTimer ?? this.disappearingTimer,
    );
  }

  String getFormattedTime() {
    if (lastMessageTimestamp == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(lastMessageTimestamp!);
    
    if (difference.inDays == 0) {
      // Today - show time
      final hour = lastMessageTimestamp!.hour.toString().padLeft(2, '0');
      final minute = lastMessageTimestamp!.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[lastMessageTimestamp!.weekday - 1];
    } else {
      // Older - show date
      return '${lastMessageTimestamp!.day}/${lastMessageTimestamp!.month}';
    }
  }
}
