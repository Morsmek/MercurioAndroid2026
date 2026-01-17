import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mercurio_messenger/services/crypto_service.dart';
import 'package:mercurio_messenger/utils/theme.dart';

class QRCodeDisplayScreen extends StatefulWidget {
  const QRCodeDisplayScreen({super.key});

  @override
  State<QRCodeDisplayScreen> createState() => _QRCodeDisplayScreenState();
}

class _QRCodeDisplayScreenState extends State<QRCodeDisplayScreen> {
  String? _mercurioId;

  @override
  void initState() {
    super.initState();
    _loadMercurioId();
  }

  Future<void> _loadMercurioId() async {
    final id = await CryptoService().getSessionId();
    setState(() {
      _mercurioId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Mercurio ID'),
        actions: [
          if (_mercurioId != null)
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: _copyToClipboard,
              tooltip: 'Copy Mercurio ID',
            ),
        ],
      ),
      body: _mercurioId == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Instructions
                  Text(
                    'Share this QR code with others to let them add you as a contact',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // QR Code
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.qrCodeBackground,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: _mercurioId!,
                        version: QrVersions.auto,
                        size: 280,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Mercurio ID Display
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.sessionIdBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Mercurio ID:',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          _formatMercurioId(_mercurioId!),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: AppTheme.textWhite,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Copy Button
                  ElevatedButton.icon(
                    onPressed: _copyToClipboard,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Mercurio ID'),
                  ),
                  const SizedBox(height: 16),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Anyone can add you as a contact by scanning this QR code or entering your Mercurio ID',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _formatMercurioId(String id) {
    // Format: break into 4 lines of 16-17 characters each
    final buffer = StringBuffer();
    for (int i = 0; i < id.length; i += 17) {
      if (i > 0) buffer.write('\n');
      final end = (i + 17 < id.length) ? i + 17 : id.length;
      buffer.write(id.substring(i, end));
    }
    return buffer.toString();
  }

  void _copyToClipboard() {
    if (_mercurioId != null) {
      Clipboard.setData(ClipboardData(text: _mercurioId!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mercurio ID copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
