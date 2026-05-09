import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  static const _prefKey = 'translation_enabled';
  static const _apiUrl = 'https://libretranslate.de/translate';

  bool _enabled = false;
  bool get isEnabled => _enabled;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefKey) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }

  Future<String> translate(String text) async {
    if (text.trim().isEmpty) return text;
    try {
      final bool hasCyrillic = text.runes.any((r) => r >= 0x0400 && r <= 0x04FF);
      final String sourceLang = hasCyrillic ? 'ru' : 'en';
      final String targetLang = hasCyrillic ? 'en' : 'ru';
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'q': text, 'source': sourceLang, 'target': targetLang, 'format': 'text'}),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['translatedText'] as String? ?? text;
      }
    } catch (e) {
      if (kDebugMode) print('Translation error: $e');
    }
    return text;
  }
}
