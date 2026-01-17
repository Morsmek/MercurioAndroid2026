import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mercurio_messenger/services/crypto_service.dart';
import 'package:mercurio_messenger/screens/verify_phrase_screen.dart';
import 'package:mercurio_messenger/utils/theme.dart';

class RecoveryPhraseScreen extends StatefulWidget {
  const RecoveryPhraseScreen({super.key});

  @override
  State<RecoveryPhraseScreen> createState() => _RecoveryPhraseScreenState();
}

class _RecoveryPhraseScreenState extends State<RecoveryPhraseScreen> {
  String? _recoveryPhrase;
  bool _hasWrittenDown = false;

  @override
  void initState() {
    super.initState();
    _loadRecoveryPhrase();
  }

  Future<void> _loadRecoveryPhrase() async {
    final phrase = await CryptoService().getRecoveryPhrase();
    setState(() {
      _recoveryPhrase = phrase;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_recoveryPhrase == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final words = _recoveryPhrase!.split(' ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Save Recovery Phrase'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Warning Icon
              Icon(
                Icons.warning_amber_rounded,
                size: 60,
                color: AppTheme.warningAmber,
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Save Your Recovery Phrase',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'Write these 12 words on paper. This is the ONLY way to recover your account if you lose your device.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Recovery Phrase Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.recoveryPhraseBorder,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < words.length; i += 2)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildWordItem(i + 1, words[i]),
                            ),
                            const SizedBox(width: 16),
                            if (i + 1 < words.length)
                              Expanded(
                                child: _buildWordItem(i + 2, words[i + 1]),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _copyPhrase,
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
                      onPressed: _takeScreenshot,
                      icon: const Icon(Icons.screenshot),
                      label: const Text('Screenshot'),
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
              const SizedBox(height: 32),

              // Confirmation Checkbox
              CheckboxListTile(
                value: _hasWrittenDown,
                onChanged: (value) {
                  setState(() {
                    _hasWrittenDown = value ?? false;
                  });
                },
                title: const Text('I\'ve written it down safely'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Theme.of(context).colorScheme.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),

              // Continue Button
              ElevatedButton(
                onPressed: _hasWrittenDown
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => VerifyPhraseScreen(
                              correctPhrase: _recoveryPhrase!,
                            ),
                          ),
                        );
                      }
                    : null,
                child: const Text('Continue'),
              ),
              const SizedBox(height: 24),

              // Warning Message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.errorRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.errorRed,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Never share this phrase with anyone!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.errorRed,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWordItem(int number, String word) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            '$number.',
            style: const TextStyle(
              color: AppTheme.textGray,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            word,
            style: const TextStyle(
              color: AppTheme.textWhite,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _copyPhrase() {
    Clipboard.setData(ClipboardData(text: _recoveryPhrase!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recovery phrase copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _takeScreenshot() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Take a screenshot to save this phrase'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
