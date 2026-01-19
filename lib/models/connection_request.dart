class ConnectionRequest {
  final String id;
  final String fromSessionId;
  final String toSessionId;
  final String message;
  final DateTime timestamp;
  final String status; // 'pending', 'accepted', 'denied'

  ConnectionRequest({
    required this.id,
    required this.fromSessionId,
    required this.toSessionId,
    required this.message,
    required this.timestamp,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromSessionId': fromSessionId,
      'toSessionId': toSessionId,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status,
    };
  }

  factory ConnectionRequest.fromMap(Map<String, dynamic> map) {
    return ConnectionRequest(
      id: map['id'] as String,
      fromSessionId: map['fromSessionId'] as String,
      toSessionId: map['toSessionId'] as String,
      message: map['message'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      status: map['status'] as String? ?? 'pending',
    );
  }

  ConnectionRequest copyWith({
    String? status,
  }) {
    return ConnectionRequest(
      id: id,
      fromSessionId: fromSessionId,
      toSessionId: toSessionId,
      message: message,
      timestamp: timestamp,
      status: status ?? this.status,
    );
  }
}
