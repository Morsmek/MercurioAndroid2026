import 'package:flutter/material.dart';
import 'package:mercurio_messenger/services/crypto_service.dart';
import 'package:mercurio_messenger/screens/session_id_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isGenerating = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _generateIdentity();
  }

  Future<void> _generateIdentity() async {
    setState(() {
      _isGenerating = true;
      _progress = 0.0;
    });

    // Simulate progress for UX
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) {
        setState(() {
          _progress = i / 100;
        });
      }
    }

    try {
      // Generate actual identity
      final sessionId = await CryptoService().generateIdentity();

      if (mounted) {
        setState(() {
          _isGenerating = false;
        });

        // Navigate to Session ID display screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => SessionIdScreen(sessionId: sessionId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating identity: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Lock Icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                child: Icon(
                  Icons.vpn_key,
                  size: 100,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 48),

              // Title
              Text(
                'Generating Your\nSecure Identity',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Progress Bar
              if (_isGenerating) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 8,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],

              const SizedBox(height: 48),

              // Status Messages
              _buildStatusMessage(
                context,
                Icons.flash_on,
                'Creating anonymous cryptographic identity on your device...',
              ),
              const SizedBox(height: 16),
              _buildStatusMessage(
                context,
                Icons.lock,
                'End-to-end encrypted',
              ),
              const SizedBox(height: 16),
              _buildStatusMessage(
                context,
                Icons.language,
                'Decentralized network',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusMessage(
      BuildContext context, IconData icon, String message) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
