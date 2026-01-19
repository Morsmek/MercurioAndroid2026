import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mercurio_messenger/services/crypto_service.dart';
import 'package:mercurio_messenger/services/storage_service.dart';
import 'package:mercurio_messenger/services/firebase_messaging_service.dart';
import 'package:mercurio_messenger/services/connection_service.dart';
import 'package:mercurio_messenger/models/connection_request.dart';
import 'package:mercurio_messenger/models/conversation.dart';
import 'package:mercurio_messenger/models/contact.dart';
import 'package:mercurio_messenger/screens/add_contact_screen.dart';
import 'package:mercurio_messenger/screens/chat_screen.dart';
import 'package:mercurio_messenger/screens/qr_display_screen.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String? _sessionId;
  List<Conversation> _conversations = [];
  StreamSubscription? _messageSubscription;
  StreamSubscription? _requestSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupMessageListener();
    _setupConnectionRequestListener();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _requestSubscription?.cancel();
    super.dispose();
  }

  void _setupMessageListener() {
    // Listen for new messages and refresh conversation list
    _messageSubscription = FirebaseMessagingService().messageStream.listen((_) {
      _loadData();
    });
  }

  void _setupConnectionRequestListener() {
    // Listen for incoming connection requests
    _requestSubscription = ConnectionService().requestStream.listen((request) {
      if (mounted) {
        _showConnectionRequestDialog(request);
      }
    });
  }

  Future<void> _loadData() async {
    final sessionId = await CryptoService().getSessionId();
    final conversationsData = await StorageService().getAllConversations();
    
    setState(() {
      _sessionId = sessionId;
      _conversations = conversationsData
          .map((data) => Conversation.fromMap(data))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mercurio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddContactScreen(),
                  ),
                );
                
                // Reload data if contact was added
                if (result == true) {
                  _loadData();
                }
              },
              child: const Icon(Icons.person_add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildConversationsList();
      case 1:
        return _buildGroupsList();
      case 2:
        return _buildSettings();
      default:
        return _buildConversationsList();
    }
  }

  Widget _buildConversationsList() {
    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to start a new chat',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              conversation.contactName[0].toUpperCase(),
              style: const TextStyle(color: Colors.black),
            ),
          ),
          title: Text(conversation.contactName),
          subtitle: Text(
            conversation.lastMessage ?? 'No messages yet',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                conversation.getFormattedTime(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (conversation.unreadCount > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    conversation.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          onTap: () async {
            // Load contact and open chat
            final contactData = await StorageService().getContact(conversation.contactSessionId);
            if (contactData != null && mounted) {
              final contact = Contact.fromMap(contactData);
              
              // CRITICAL FIX: Regenerate the correct conversation ID
              final mySessionId = await CryptoService().getSessionId();
              if (mySessionId == null) return;
              
              final correctConversationId = _getConversationId(contact.sessionId, mySessionId);
              
              // Update conversation with correct ID if needed
              Conversation conversationToUse = conversation;
              if (conversation.id != correctConversationId) {
                if (kDebugMode) {
                  print('🔧 FIXING conversation ID: ${conversation.id} -> $correctConversationId');
                }
                conversationToUse = conversation.copyWith(id: correctConversationId);
                await StorageService().saveConversation(conversationToUse.toMap());
              }
              
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    conversation: conversationToUse,
                    contact: contact,
                  ),
                ),
              );
              
              // Reload data after returning from chat
              if (result == true || result == null) {
                _loadData();
              }
            }
          },
        );
      },
    );
  }

  Widget _buildGroupsList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No groups yet',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Group chats coming soon',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    return ListView(
      children: [
        // Profile Section
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/mercurio_logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Mercurio User',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (_sessionId != null)
                SelectableText(
                  '${_sessionId!.substring(0, 16)}...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
            ],
          ),
        ),
        const Divider(),

        // Settings Options
        ListTile(
          leading: const Icon(Icons.qr_code),
          title: const Text('Show My QR Code'),
          subtitle: const Text('Let others scan to add you'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const QRCodeDisplayScreen(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.vpn_key),
          title: const Text('Your Mercurio ID'),
          subtitle: const Text('View and share your Mercurio ID'),
          onTap: () {
            _showSessionId();
          },
        ),
        ListTile(
          leading: const Icon(Icons.shield),
          title: const Text('Recovery Phrase'),
          subtitle: const Text('View your 12-word recovery phrase'),
          onTap: () {
            _showRecoveryPhrase();
          },
        ),
        ListTile(
          leading: const Icon(Icons.lock),
          title: const Text('Privacy & Security'),
          subtitle: const Text('App lock, biometric settings'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Security settings coming soon')),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Notifications'),
          subtitle: const Text('Manage notification preferences'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notification settings coming soon')),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('About Mercurio'),
          subtitle: const Text('Version 1.0.0'),
          onTap: () {
            _showAboutDialog();
          },
        ),
        const Divider(),
        ListTile(
          leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
          title: Text(
            'Logout',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          onTap: () {
            _logout();
          },
        ),
      ],
    );
  }

  void _showSessionId() async {
    final sessionId = await CryptoService().getSessionId();
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Your Mercurio ID'),
          content: SelectableText(
            sessionId ?? 'Error loading Mercurio ID',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
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
  }

  void _showRecoveryPhrase() async {
    final phrase = await CryptoService().getRecoveryPhrase();
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Recovery Phrase'),
          content: SelectableText(phrase ?? 'Error loading recovery phrase'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Mercurio Messenger',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/mercurio_logo.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
      children: const [
        Text('Ultra-secure private messaging with anonymous registration.'),
        SizedBox(height: 16),
        Text('Privacy is a right, not a privilege.'),
      ],
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout? Make sure you have your recovery phrase saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement logout
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logout feature coming soon')),
              );
              Navigator.pop(context);
            },
            child: Text(
              'Logout',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
  
  // Generate deterministic conversation ID from two session IDs
  String _getConversationId(String id1, String id2) {
    final sortedIds = [id1, id2]..sort();
    return sortedIds.join('_');
  }

  Future<void> _showConnectionRequestDialog(ConnectionRequest request) async {
    final nameController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Connection Request Received!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Message from sender:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                request.message,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Give them a display name:', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'e.g., John from work',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Deny'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a display name')),
                );
                return;
              }
              Navigator.pop(context, name);
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      // Accept request with display name
      try {
        await ConnectionService().acceptRequest(request, result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$result added as contact!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData(); // Refresh to show new contact
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error accepting: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } else if (result == null) {
      // Deny request
      try {
        await ConnectionService().denyRequest(request);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connection denied'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error denying: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}
