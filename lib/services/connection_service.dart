import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:mercurio_messenger/models/connection_request.dart';
import 'package:mercurio_messenger/models/contact.dart';
import 'package:mercurio_messenger/models/conversation.dart';
import 'package:mercurio_messenger/services/storage_service.dart';
import 'package:mercurio_messenger/services/crypto_service.dart';
import 'package:uuid/uuid.dart';

class ConnectionService {
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _requestSubscription;
  final _requestController = StreamController<ConnectionRequest>.broadcast();
  
  Stream<ConnectionRequest> get requestStream => _requestController.stream;
  
  String? _myMercurioId;

  /// Initialize connection service to listen for incoming requests
  Future<void> initialize() async {
    _myMercurioId = await CryptoService().getSessionId();
    
    if (_myMercurioId == null) {
      if (kDebugMode) {
        print('⚠️ Cannot initialize connection service: No Mercurio ID');
      }
      return;
    }

    _startListeningForRequests();
    
    if (kDebugMode) {
      print('🔗 Connection Service initialized for: $_myMercurioId');
    }
  }

  /// Listen for incoming connection requests
  void _startListeningForRequests() {
    if (_myMercurioId == null) return;

    _requestSubscription = _firestore
        .collection('connection_requests')
        .where('toSessionId', isEqualTo: _myMercurioId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final request = ConnectionRequest.fromMap(data);
          
          if (kDebugMode) {
            print('📨 New connection request from: ${request.fromSessionId}');
            print('   Message: ${request.message}');
          }
          
          _requestController.add(request);
        }
      }
    });

    if (kDebugMode) {
      print('👂 Listening for connection requests...');
    }
  }

  /// Send a connection request
  Future<void> sendRequest({
    required String toSessionId,
    required String message,
    required String displayName,
  }) async {
    if (_myMercurioId == null) throw Exception('No session ID');

    final request = ConnectionRequest(
      id: const Uuid().v4(),
      fromSessionId: _myMercurioId!,
      toSessionId: toSessionId,
      message: message,
      timestamp: DateTime.now(),
    );

    await _firestore
        .collection('connection_requests')
        .doc(request.id)
        .set(request.toMap());

    if (kDebugMode) {
      print('📤 Connection request sent to: $toSessionId');
    }
  }

  /// Accept a connection request
  Future<void> acceptRequest(ConnectionRequest request, String displayName) async {
    try {
      // Update request status
      await _firestore
          .collection('connection_requests')
          .doc(request.id)
          .update({'status': 'accepted'});

      // Create contact
      final contact = Contact(
        sessionId: request.fromSessionId,
        displayName: displayName,
        verified: false,
        blocked: false,
      );
      
      await StorageService().saveContact(contact.toMap());

      // Create conversation
      final conversationId = _getConversationId(request.fromSessionId, _myMercurioId!);
      final conversation = {
        'id': conversationId,
        'contactSessionId': request.fromSessionId,
        'contactName': displayName,
        'lastMessage': '',
        'lastMessageTimestamp': DateTime.now().millisecondsSinceEpoch,
        'unreadCount': 0,
      };
      
      await StorageService().saveConversation(conversation);

      if (kDebugMode) {
        print('✅ Connection request accepted from: ${request.fromSessionId}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error accepting request: $e');
      }
      rethrow;
    }
  }

  /// Deny a connection request
  Future<void> denyRequest(ConnectionRequest request) async {
    await _firestore
        .collection('connection_requests')
        .doc(request.id)
        .update({'status': 'denied'});

    if (kDebugMode) {
      print('❌ Connection request denied from: ${request.fromSessionId}');
    }
  }

  String _getConversationId(String id1, String id2) {
    final sortedIds = [id1, id2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  void dispose() {
    _requestSubscription?.cancel();
    if (!_requestController.isClosed) {
      _requestController.close();
    }
  }
}
