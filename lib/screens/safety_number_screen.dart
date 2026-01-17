import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mercurio_messenger/services/crypto_service.dart';
import 'package:mercurio_messenger/utils/theme.dart';

/// Safety Number Verification Screen
/// Shows 60-digit fingerprint for contact verification
class SafetyNumberScreen extends StatefulWidget {
  final String contactName;
  final String contactMercurioId;

  const SafetyNumberScreen({
    super.key,
    required this.contactName,
    required this.contactMercurioId,
  });

  @override
  State<SafetyNumberScreen> createState() => _SafetyNumberScreenState();
}

class _SafetyNumberScreenState extends State<SafetyNumberScreen> {
  String? _safetyNumber;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSafetyNumber();
  }

  Future<void> _loadSafetyNumber() async {
    try {
      final safetyNumber = await CryptoService().generateSafetyNumber(
        widget.contactMercurioId,
      );
      setState(() {
        _safetyNumber = safetyNumber;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating safety number: $e')),
        );
      }
    }
  }

  void _copySafetyNumber() {
    if (_safetyNumber != null) {
      Clipboard.setData(ClipboardData(text: _safetyNumber!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Safety number copied')),
      );
    }
  }

  String _formatSafetyNumber(String number) {
    // Format as 12 groups of 5 digits
    final chunks = <String>[];
    for (int i = 0; i < number.length; i += 5) {
      final end = (i + 5 < number.length) ? i + 5 : number.length;
      chunks.add(number.substring(i, end));
    }
    return chunks.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text('Verify ${widget.contactName}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Shield icon
                  const Icon(
                    Icons.shield_outlined,
                    size: 80,
                    color: AppTheme.primaryOrange,
                  ),
                  const SizedBox(height: 32),

                  // Title
                  const Text(
                    'Safety Number',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'This 60-digit number uniquely identifies your conversation with ${widget.contactName}.',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Safety number display
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: _safetyNumber != null
                        ? SelectableText(
                            _formatSafetyNumber(_safetyNumber!),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontFamily: 'monospace',
                              letterSpacing: 2,
                              height: 1.8,
                            ),
                            textAlign: TextAlign.center,
                          )
                        : const Text(
                            'Error loading safety number',
                            style: TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Copy button
                  ElevatedButton.icon(
                    onPressed: _copySafetyNumber,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Safety Number'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Verification instructions
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'How to Verify:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildStep('1', 'Open this screen on both devices'),
                        const SizedBox(height: 8),
                        _buildStep('2', 'Compare the safety numbers'),
                        const SizedBox(height: 8),
                        _buildStep('3', 'If they match, your conversation is secure'),
                        const SizedBox(height: 8),
                        _buildStep('4', 'If they don\'t match, someone may be intercepting'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Security note
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppTheme.primaryOrange,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This number changes if you or ${widget.contactName} reinstall Mercurio.',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 12,
                            ),
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

  Widget _buildStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.cyanAccent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
