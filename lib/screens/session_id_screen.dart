import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mercurio_messenger/screens/recovery_phrase_screen.dart';
import 'package:mercurio_messenger/utils/theme.dart';

class SessionIdScreen extends StatelessWidget {
  final String sessionId;

  const SessionIdScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Mercurio ID'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Description
              Text(
                'This is your anonymous Mercurio ID. Share it with contacts to start chatting.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Session ID Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.sessionIdBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  _formatSessionId(sessionId),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    color: AppTheme.textWhite,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),

              // QR Code
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.qrCodeBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: sessionId,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copyToClipboard(context),
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _shareSessionId(context),
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Continue Button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RecoveryPhraseScreen(),
                    ),
                  );
                },
                child: const Text('Continue →'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSessionId(String sessionId) {
    // Format: 05d871fc80ca007e...ed9b2f4df72853e (break into chunks)
    final buffer = StringBuffer();
    for (int i = 0; i < sessionId.length; i += 16) {
      if (i > 0) buffer.write('\n');
      final end = (i + 16 < sessionId.length) ? i + 16 : sessionId.length;
      buffer.write(sessionId.substring(i, end));
    }
    return buffer.toString();
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: sessionId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mercurio ID copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareSessionId(BuildContext context) {
    // In a full implementation, use share_plus package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality - Use Copy for now'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
