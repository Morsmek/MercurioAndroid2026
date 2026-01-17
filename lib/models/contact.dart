/// Contact Model
class Contact {
  final String sessionId;
  final String displayName;
  final String? avatar;
  final bool verified;
  final bool blocked;
  final DateTime? lastSeen;
  final String? notes;

  Contact({
    required this.sessionId,
    required this.displayName,
    this.avatar,
    this.verified = false,
    this.blocked = false,
    this.lastSeen,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'displayName': displayName,
      'avatar': avatar,
      'verified': verified,
      'blocked': blocked,
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
      'notes': notes,
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      sessionId: map['sessionId'] as String,
      displayName: map['displayName'] as String,
      avatar: map['avatar'] as String?,
      verified: map['verified'] as bool? ?? false,
      blocked: map['blocked'] as bool? ?? false,
      lastSeen: map['lastSeen'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastSeen'] as int)
          : null,
      notes: map['notes'] as String?,
    );
  }

  Contact copyWith({
    String? displayName,
    String? avatar,
    bool? verified,
    bool? blocked,
    DateTime? lastSeen,
    String? notes,
  }) {
    return Contact(
      sessionId: sessionId,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar,
      verified: verified ?? this.verified,
      blocked: blocked ?? this.blocked,
      lastSeen: lastSeen ?? this.lastSeen,
      notes: notes ?? this.notes,
    );
  }
}
