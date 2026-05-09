import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mercurio_messenger/models/conversation.dart';
import 'package:mercurio_messenger/models/contact.dart';
import 'package:mercurio_messenger/models/message.dart';
import 'package:mercurio_messenger/services/storage_service.dart';
import 'package:mercurio_messenger/services/crypto_service.dart';
import 'package:mercurio_messenger/services/firebase_messaging_service.dart';
import 'package:mercurio_messenger/services/translation_service.dart';
import 'package:mercurio_messenger/utils/theme.dart';
import 'package:mercurio_messenger/screens/safety_number_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;
  final Contact contact;
  const ChatScreen({super.key, required this.conversation, required this.contact});
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
  final Map<String, String?> _translations = {};

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
    setState(() => _myMercurioId = id);
  }

  void _setupMessageListener() {
    _messageSubscription = FirebaseMessagingService().messageStream.listen((message) {
      if (message.conversationId == widget.conversation.id) {
        setState(() {
          _messages.add(message);
          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(_scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
          }
        });
        FirebaseMessagingService().markAsRead(message.id, widget.conversation.id);
      }
    });
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    final messagesData = await StorageService().getMessages(widget.conversation.id);
    setState(() {
      _messages = messagesData.map((d) => Message.fromMap(d)).toList();
      _isLoading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
    await StorageService().markConversationAsRead(widget.conversation.id);
  }

  // CHANGE 1: Only "Send with Plinxx" in attachment menu
  Future<void> _showAttachmentOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Send with Plinxx'),
              subtitle: const Text('Share a file securely via Plinxx'),
              onTap: () { Navigator.pop(ctx); _handleSendWithPlinxx(); },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSendWithPlinxx() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1920, maxHeight: 1080, imageQuality: 85);
      if (image != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sending "${image.name}" with Plinxx...')));
        // TODO: upload via Plinxx API and send link as message
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to pick file: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  // CHANGE 3: Translation
  Future<void> _translateMessage(Message message) async {
    final translated = await TranslationService().translate(message.content);
    if (mounted) setState(() => _translations[message.id] = translated);
  }

  Widget _buildMessageBubble(Message message, bool isSentByMe) {
    final translationEnabled = TranslationService().isEnabled;
    final translatedText = _translations[message.id];
    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isSentByMe ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isSentByMe ? 18 : 4),
                bottomRight: Radius.circular(isSentByMe ? 4 : 18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.content, style: TextStyle(color: isSentByMe ? Colors.black : Colors.white, fontSize: 15)),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_formatTime(message.timestamp),
                        style: TextStyle(fontSize: 11, color: isSentByMe ? Colors.black54 : Colors.white60)),
                    if (isSentByMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.status == MessageStatus.read ? Icons.done_all
                            : message.status == MessageStatus.delivered ? Icons.done_all : Icons.done,
                        size: 14,
                        color: message.status == MessageStatus.read ? Colors.blue : Colors.black45,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (translationEnabled) ...[
            if (translatedText == null)
              GestureDetector(
                onTap: () => _translateMessage(message),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
                  child: Text('Show translation',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline)),
                ),
              )
            else
              Container(
                margin: const EdgeInsets.only(bottom: 6, left: 4, right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
                ),
                child: Text(translatedText, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
              ),
          ],
        ],
      ),
    );
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
              child: Text(widget.contact.displayName[0].toUpperCase(), style: const TextStyle(color: Colors.black, fontSize: 16)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.contact.displayName, style: const TextStyle(fontSize: 16)),
                  if (widget.contact.verified)
                    Row(children: [
                      Icon(Icons.verified, size: 12, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 4),
                      Text('Verified', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary)),
                    ]),
                ],
              ),
            ),
          ],
        ),
        actions: [IconButton(icon: const Icon(Icons.more_vert), onPressed: _showChatOptions)],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text('No messages yet', style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 8),
                        Text('Send a message to start the conversation', style: Theme.of(context).textTheme.bodyMedium),
                      ]))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isSentByMe = message.senderSessionId == null;
                          final showDateHeader = index == 0 || !_isSameDay(_messages[index - 1].timestamp, message.timestamp);
                          return Column(children: [
                            if (showDateHeader) _buildDateHeader(message.timestamp),
                            _buildMessageBubble(message, isSentByMe),
                          ]);
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(top: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest, width: 1)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.attach_file), onPressed: _showAttachmentOptions, tooltip: 'Send with Plinxx'),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: IconButton(icon: const Icon(Icons.send, color: Colors.black), onPressed: _sendMessage),
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
    final diff = DateTime.now().difference(date);
    final dateText = diff.inDays == 0 ? 'Today' : diff.inDays == 1 ? 'Yesterday' : '${date.day}/${date.month}/${date.year}';
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
        child: Text(dateText, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }

  String _formatTime(DateTime time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    _messageController.clear();
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: widget.conversation.id,
      senderSessionId: null,
      content: content,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );
    setState(() => _messages.add(message));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
    await StorageService().saveMessage(message.toMap());
    await StorageService().updateConversationLastMessage(widget.conversation.id, content);
    try {
      await FirebaseMessagingService().sendMessage(message, widget.contact.sessionId);
    } catch (e) {
      if (kDebugMode) print('Error sending: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e'), backgroundColor: Theme.of(context).colorScheme.error));
    }
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.shield_outlined), title: const Text('Verify Safety Number'),
              subtitle: const Text('Confirm end-to-end encryption'),
              onTap: () { Navigator.pop(context); _showSafetyNumber(); }),
          ListTile(leading: const Icon(Icons.timer), title: const Text('Disappearing messages'),
              subtitle: Text(widget.conversation.disappearingTimer != null ? 'Timer: ${widget.conversation.disappearingTimer}s' : 'Off'),
              onTap: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon!'))); }),
          ListTile(leading: const Icon(Icons.info_outline), title: const Text('Contact info'),
              onTap: () { Navigator.pop(context); _showContactInfo(); }),
          ListTile(
              leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              title: Text('Delete conversation', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () { Navigator.pop(context); _confirmDeleteConversation(); }),
        ]),
      ),
    );
  }

  void _showContactInfo() {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: Text(widget.contact.displayName),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Mercurio ID:', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        SelectableText(widget.contact.sessionId, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
        if (widget.contact.verified) ...[
          const SizedBox(height: 16),
          Row(children: [Icon(Icons.verified, size: 16, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 8), const Text('Verified Contact')]),
        ],
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    ));
  }

  void _showSafetyNumber() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => SafetyNumberScreen(
      contactName: widget.contact.displayName, contactMercurioId: widget.contact.sessionId)));
  }

  void _confirmDeleteConversation() {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Delete Conversation'),
      content: const Text('Are you sure? All messages will be permanently deleted.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () async {
            await StorageService().deleteConversation(widget.conversation.id);
            if (context.mounted) { Navigator.pop(context); Navigator.pop(context); }
          },
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          child: const Text('Delete'),
        ),
      ],
    ));
  }
}
