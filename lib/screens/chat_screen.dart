import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mercurio_messenger/models/conversation.dart';
import 'package:mercurio_messenger/models/contact.dart';
import 'package:mercurio_messenger/models/message.dart';
import 'package:mercurio_messenger/services/storage_service.dart';
import 'package:mercurio_messenger/services/crypto_service.dart';
import 'package:mercurio_messenger/services/firebase_messaging_service.dart';
import 'package:mercurio_messenger/utils/theme.dart';
import 'package:mercurio_messenger/screens/safety_number_screen.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;
  final Contact contact;

  const ChatScreen({
    super.key,
    required this.conversation,
    required this.contact,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = true;
  String? _myMercurioId;
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadMyId();
    _setupMessageListener();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadMyId() async {
    final id = await CryptoService().getSessionId();
    setState(() {
      _myMercurioId = id;
    });
  }

  void _setupMessageListener() {
    // Listen for new messages from Firebase
    _messageSubscription = FirebaseMessagingService().messageStream.listen((message) {
      // Check if message belongs to this conversation
      if (message.conversationId == widget.conversation.id) {
        setState(() {
          _messages.add(message);
          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        });

        // Scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        // Mark as read
        FirebaseMessagingService().markAsRead(message.id, widget.conversation.id);
      }
    });
  }

  Future<void> _loadMessages() async {
    if (kDebugMode) {
      print('📖 Loading messages for conversation: ${widget.conversation.id}');
    }

    setState(() {
      _isLoading = true;
    });

    final messagesData = await StorageService().getMessages(widget.conversation.id);
    
    if (kDebugMode) {
      print('   Found ${messagesData.length} messages');
    }

    setState(() {
      _messages = messagesData.map((data) => Message.fromMap(data)).toList();
      _isLoading = false;
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    // Mark messages as read
    await StorageService().markConversationAsRead(widget.conversation.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              radius: 18,
              child: Text(
                widget.contact.displayName[0].toUpperCase(),
                style: const TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contact.displayName,
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (widget.contact.verified)
                    Row(
                      children: [
                        Icon(
                          Icons.verified,
                          size: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showChatOptions(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Send a message to start the conversation',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isSentByMe = message.senderSessionId == null;
                          final showDateHeader = index == 0 ||
                              !_isSameDay(
                                _messages[index - 1].timestamp,
                                message.timestamp,
                              );

                          return Column(
                            children: [
                              if (showDateHeader)
                                _buildDateHeader(message.timestamp),
                              _buildMessageBubble(message, isSentByMe),
                            ],
                          );
                        },
                      ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Attachment Button (placeholder)
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('File attachments coming soon!'),
                        ),
                      );
                    },
                  ),

                  // Message Input Field
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send Button
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.black),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    String dateText;
    if (difference.inDays == 0) {
      dateText = 'Today';
    } else if (difference.inDays == 1) {
      dateText = 'Yesterday';
    } else {
      dateText = '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        dateText,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textGray,
            ),
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isSentByMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSentByMe) ...[
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              radius: 16,
              child: Text(
                widget.contact.displayName[0].toUpperCase(),
                style: const TextStyle(color: Colors.black, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSentByMe
                    ? AppTheme.sentMessageBubble
                    : AppTheme.receivedMessageBubble,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isSentByMe ? 16 : 4),
                  bottomRight: Radius.circular(isSentByMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: const TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: AppTheme.textGray.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                      if (isSentByMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          _getStatusIcon(message.status),
                          size: 14,
                          color: message.status == MessageStatus.read
                              ? Theme.of(context).colorScheme.primary
                              : AppTheme.textGray.withValues(alpha: 0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isSentByMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.done;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error_outline;
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Clear input immediately for better UX
    _messageController.clear();

    try {
      if (kDebugMode) {
        print('💬 Sending message:');
        print('   Conversation ID: ${widget.conversation.id}');
        print('   To: ${widget.contact.sessionId}');
        print('   Text: $text');
      }

      // Create message
      final message = Message(
        conversationId: widget.conversation.id,
        senderSessionId: null, // null means sent by current user
        content: text,
        type: MessageType.text,
        status: MessageStatus.sending,
      );

      // Save message locally first
      await StorageService().saveMessage(message.toMap());

      if (kDebugMode) {
        print('   💾 Message saved locally');
      }

      // Update conversation
      final updatedConversation = widget.conversation.copyWith(
        lastMessage: text,
        lastMessageTimestamp: message.timestamp,
      );
      await StorageService().saveConversation(updatedConversation.toMap());

      // Add to UI immediately
      setState(() {
        _messages.add(message);
      });

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      // Send via Firebase messaging service
      await FirebaseMessagingService().sendMessage(
        message,
        widget.contact.sessionId,
      );

      if (kDebugMode) {
        print('   📤 Message sent to Firebase');
      }

      // Update message status to sent
      final sentMessage = message.copyWith(status: MessageStatus.sent);
      await StorageService().saveMessage(sentMessage.toMap());
      
      // Reload messages to show updated status
      await _loadMessages();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text('Verify Safety Number'),
              subtitle: const Text('Confirm end-to-end encryption'),
              onTap: () {
                Navigator.pop(context);
                _showSafetyNumber();
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('Disappearing messages'),
              subtitle: Text(
                widget.conversation.disappearingTimer != null
                    ? 'Timer: ${widget.conversation.disappearingTimer}s'
                    : 'Off',
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Disappearing messages coming soon!'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Contact info'),
              onTap: () {
                Navigator.pop(context);
                _showContactInfo();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Delete conversation',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteConversation();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showContactInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.contact.displayName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mercurio ID:', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            SelectableText(
              widget.contact.sessionId,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
            const SizedBox(height: 16),
            if (widget.contact.verified)
              Row(
                children: [
                  Icon(
                    Icons.verified,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text('Verified Contact'),
                ],
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSafetyNumber() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SafetyNumberScreen(
          contactName: widget.contact.displayName,
          contactMercurioId: widget.contact.sessionId,
        ),
      ),
    );
  }

  void _confirmDeleteConversation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text(
          'Are you sure you want to delete this conversation? All messages will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await StorageService().deleteConversation(widget.conversation.id);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close chat screen
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
