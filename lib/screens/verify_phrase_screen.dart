import 'package:flutter/material.dart';
import 'package:mercurio_messenger/screens/home_screen.dart';
import 'package:mercurio_messenger/services/firebase_messaging_service.dart';
import 'package:mercurio_messenger/services/connection_service.dart';
import 'dart:math';

class VerifyPhraseScreen extends StatefulWidget {
  final String correctPhrase;

  const VerifyPhraseScreen({super.key, required this.correctPhrase});

  @override
  State<VerifyPhraseScreen> createState() => _VerifyPhraseScreenState();
}

class _VerifyPhraseScreenState extends State<VerifyPhraseScreen> {
  late final List<int> _wordsToVerify; // Random words to verify (1-indexed)
  final Map<int, String?> _selectedWords = {};

  @override
  void initState() {
    super.initState();
    
    // Generate 3 random word indices from the 12-word phrase
    final totalWords = widget.correctPhrase.split(' ').length;
    final random = Random();
    final indices = <int>{};
    
    // Keep generating until we have 3 unique random indices
    while (indices.length < 3) {
      indices.add(random.nextInt(totalWords) + 1); // 1-indexed
    }
    
    // Sort for better UX (ask in order)
    _wordsToVerify = indices.toList()..sort();
    
    // Initialize selected words map
    for (final wordIndex in _wordsToVerify) {
      _selectedWords[wordIndex] = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.correctPhrase.split(' ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Recovery Phrase'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Description
              Text(
                'Select the correct words to verify you\'ve saved your recovery phrase',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Verification Questions
              for (final wordIndex in _wordsToVerify) ...[
                _buildVerificationQuestion(wordIndex, words),
                const SizedBox(height: 24),
              ],

              const SizedBox(height: 32),

              // Verify Button
              ElevatedButton(
                onPressed: _isAllSelected() ? _verifyAndContinue : null,
                child: const Text('Verify & Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationQuestion(int wordIndex, List<String> allWords) {
    final correctWord = allWords[wordIndex - 1];
    
    // Generate 3 random wrong words
    final wrongWords = <String>[];
    while (wrongWords.length < 3) {
      final randomWord = allWords[DateTime.now().millisecondsSinceEpoch % allWords.length];
      if (randomWord != correctWord && !wrongWords.contains(randomWord)) {
        wrongWords.add(randomWord);
      }
    }
    
    // Mix correct word with wrong words
    final options = [correctWord, ...wrongWords]..shuffle();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select word #$wordIndex:',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: options.map((word) {
            final isSelected = _selectedWords[wordIndex] == word;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedWords[wordIndex] = word;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  word,
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  bool _isAllSelected() {
    return _selectedWords.values.every((word) => word != null);
  }

  Future<void> _verifyAndContinue() async {
    final words = widget.correctPhrase.split(' ');
    bool allCorrect = true;

    for (final wordIndex in _wordsToVerify) {
      final correct = words[wordIndex - 1];
      final selected = _selectedWords[wordIndex];
      if (correct != selected) {
        allCorrect = false;
        break;
      }
    }

    if (allCorrect) {
      // Verification successful - initialize Firebase messaging and connection service
      await FirebaseMessagingService().initialize();
      await ConnectionService().initialize();
      
      if (mounted) {
        // Navigate to home
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
          (route) => false,
        );
      }
    } else {
      // Verification failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Incorrect words selected. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
