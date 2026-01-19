import 'package:flutter/material.dart';
import 'package:mercurio_messenger/services/crypto_service.dart';
import 'package:mercurio_messenger/screens/home_screen.dart';
import 'package:mercurio_messenger/services/firebase_messaging_service.dart';
import 'package:mercurio_messenger/services/connection_service.dart';

class RestoreScreen extends StatefulWidget {
  const RestoreScreen({super.key});

  @override
  State<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends State<RestoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phraseController = TextEditingController();
  bool _isRestoring = false;

  @override
  void dispose() {
    _phraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restore Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                Icon(
                  Icons.restore,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Restore from Recovery Phrase',
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  'Enter your 12-word recovery phrase to restore your account',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Recovery Phrase Input
                TextFormField(
                  controller: _phraseController,
                  decoration: const InputDecoration(
                    labelText: 'Recovery Phrase',
                    hintText: 'word1 word2 word3 ...',
                    helperText: 'Enter all 12 words separated by spaces',
                  ),
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your recovery phrase';
                    }
                    
                    final words = value.trim().split(' ');
                    if (words.length != 12) {
                      return 'Recovery phrase must be exactly 12 words';
                    }
                    
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Restore Button
                ElevatedButton(
                  onPressed: _isRestoring ? null : _restoreAccount,
                  child: _isRestoring
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Restore Account'),
                ),
                const SizedBox(height: 16),

                // Warning
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
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
                          'Message history is stored locally and will not be restored. Only your identity and Session ID will be recovered.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _restoreAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isRestoring = true;
    });

    try {
      final phrase = _phraseController.text.trim();
      await CryptoService().restoreFromPhrase(phrase);

      // Initialize Firebase messaging and connection service after successful restore
      await FirebaseMessagingService().initialize();
      await ConnectionService().initialize();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account restored successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to home
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
