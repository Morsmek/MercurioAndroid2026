import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mercurio_messenger/services/crypto_service.dart';
import 'package:mercurio_messenger/services/storage_service.dart';
import 'package:mercurio_messenger/models/contact.dart';
import 'package:mercurio_messenger/models/conversation.dart';
import 'package:uuid/uuid.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mercurioIdController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isAdding = false;
  bool _showScanner = false;

  @override
  void dispose() {
    _mercurioIdController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Contact'),
        actions: [
          IconButton(
            icon: Icon(_showScanner ? Icons.keyboard : Icons.qr_code_scanner),
            onPressed: () {
              setState(() {
                _showScanner = !_showScanner;
              });
            },
            tooltip: _showScanner ? 'Enter manually' : 'Scan QR code',
          ),
        ],
      ),
      body: SafeArea(
        child: _showScanner ? _buildQRScanner() : _buildManualEntry(),
      ),
    );
  }

  Widget _buildManualEntry() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon
            Icon(
              Icons.person_add,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              'Add New Contact',
              style: Theme.of(context).textTheme.displayMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Mercurio ID Input
            TextFormField(
              controller: _mercurioIdController,
              decoration: InputDecoration(
                labelText: 'Mercurio ID',
                hintText: '05d871fc80ca007e...',
                helperText: 'Enter their 66-character Mercurio ID',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  onPressed: _pasteFromClipboard,
                  tooltip: 'Paste from clipboard',
                ),
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a Mercurio ID';
                }

                final cleanId = value.trim().replaceAll('\n', '').replaceAll(' ', '');
                if (!CryptoService().isValidSessionId(cleanId)) {
                  return 'Invalid Mercurio ID format (must be 66 hex characters starting with 05)';
                }

                return null;
              },
            ),
            const SizedBox(height: 24),

            // Display Name Input
            TextFormField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                hintText: 'e.g., Alice, Bob, Carol',
                helperText: 'What would you like to call this contact?',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a display name';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Add Contact Button
            ElevatedButton(
              onPressed: _isAdding ? null : _addContact,
              child: _isAdding
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add Contact'),
            ),
            const SizedBox(height: 16),

            // Scan QR Code Button
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _showScanner = true;
                });
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR Code'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRScanner() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final mercurioId = barcodes.first.rawValue;
                    if (mercurioId != null && CryptoService().isValidSessionId(mercurioId)) {
                      _handleScannedId(mercurioId);
                    }
                  }
                },
              ),
              // Overlay with instructions
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Position the QR code within the frame',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null) {
      setState(() {
        _mercurioIdController.text = clipboardData.text!;
      });
    }
  }

  void _handleScannedId(String mercurioId) {
    setState(() {
      _showScanner = false;
      _mercurioIdController.text = mercurioId;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR code scanned! Enter a display name to continue.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _addContact() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isAdding = true;
    });

    try {
      final mercurioId = _mercurioIdController.text.trim().replaceAll('\n', '').replaceAll(' ', '');
      final displayName = _displayNameController.text.trim();

      // Check if contact already exists
      final existingContact = await StorageService().getContact(mercurioId);
      if (existingContact != null) {
        throw Exception('Contact already exists');
      }

      // Check if trying to add yourself
      final myMercurioId = await CryptoService().getSessionId();
      if (mercurioId == myMercurioId) {
        throw Exception('You cannot add yourself as a contact');
      }

      // Create contact
      final contact = Contact(
        sessionId: mercurioId,
        displayName: displayName,
        verified: false,
        blocked: false,
      );

      // Save contact
      await StorageService().saveContact(contact.toMap());

      // Create conversation
      final conversation = Conversation(
        id: const Uuid().v4(),
        contactSessionId: mercurioId,
        contactName: displayName,
        unreadCount: 0,
      );

      await StorageService().saveConversation(conversation.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$displayName added successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add contact: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
