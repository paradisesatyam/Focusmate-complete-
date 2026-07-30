import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  static const _prefKey = 'gemini_api_key';
  // Built-in key from --dart-define (works when deploying via GitHub Actions)
  static const _builtInKey =
      String.fromEnvironment('GEMINI_KEY', defaultValue: '');

  static const _model = 'gemini-2.0-flash';
  static const _url =
    'https://generativelanguage.googleapis.com/v1/models/$_model:generateContent';

  /// Returns the active API key — built-in first, then saved in prefs
  Future<String> _key() async {
    if (_builtInKey.isNotEmpty) return _builtInKey;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey) ?? '';
  }

  /// Save a user-provided key into SharedPreferences
  Future<void> saveKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, key.trim());
  }

  /// True if any key is available
  Future<bool> hasKey() async {
    if (_builtInKey.isNotEmpty) return true;
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_prefKey) ?? '').isNotEmpty;
  }

  /// Remove saved key (reset)
  Future<void> clearKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }

  /// Send a message and return the AI response
  Future<String> send(String userMessage) async {
    final apiKey = await _key();

    if (apiKey.isEmpty) {
      return '__NO_KEY__'; // Special signal — UI will show key setup dialog
    }

    try {
      final response = await http.post(
        Uri.parse('$_url?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                      'You are FocusMate AI, a helpful productivity assistant '
                      'for students and working professionals. '
                      'Keep answers concise, friendly and practical.\n\n'
                      'User: $userMessage'
                }
              ]
            }
          ],
          'generationConfig': {
            'maxOutputTokens': 600,
            'temperature': 0.7,
          },
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final candidates = json['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates[0]['content']?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            return parts[0]['text']?.toString().trim() ?? 'No response.';
          }
        }
        return 'Received an empty response. Please try again.';
      } else if (response.statusCode == 400) {
        return '❌ Invalid API key (400). Tap the key icon to update it.';
      } else if (response.statusCode == 403) {
        return '❌ Access denied (403). Make sure the Generative Language API '
            'is enabled in your Google Cloud Console.';
      } else if (response.statusCode == 429) {
        return '⏳ Rate limit reached. Please wait a moment and try again.';
      } else {
        return '❌ Error ${response.statusCode}. Please try again.';
      }
    } catch (e) {
      return '❌ Network error: Could not reach Gemini API. '
          'Check your internet connection.';
    }
  }
}
