import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // Key injected at build time via --dart-define=GEMINI_KEY=your_key
  // Run locally: flutter run -d chrome --dart-define=GEMINI_KEY=your_key
  static const _apiKey = String.fromEnvironment('GEMINI_KEY', defaultValue: '');

  // Using gemini-1.5-flash — fast, free tier, great for chat
  static const _model = 'gemini-1.5-flash';
  static const _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  Future<String> send(String userMessage) async {
    // Key check — tells user exactly what to do
    if (_apiKey.isEmpty) {
      return '⚠️ Gemini API key not configured.\n\n'
          'To fix this:\n'
          '• Locally: run with --dart-define=GEMINI_KEY=your_key\n'
          '• Vercel: add GEMINI_KEY in project environment variables\n'
          '• GitHub Actions: add GEMINI_KEY in repo secrets\n\n'
          'Get a free key at: https://aistudio.google.com';
    }

    try {
      final uri = Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                      'You are FocusMate AI, a helpful productivity assistant '
                      'for students and working professionals. '
                      'Keep answers concise, friendly, and practical.\n\n'
                      'User: $userMessage'
                }
              ]
            }
          ],
          'generationConfig': {
            'maxOutputTokens': 600,
            'temperature': 0.7,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_NONE'
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        // Navigate the response structure safely
        final candidates = json['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates[0]['content']?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            return parts[0]['text']?.toString() ?? 'No response text.';
          }
        }
        return 'Received empty response from Gemini.';
      } else if (response.statusCode == 400) {
        return '❌ Bad request (400). Your API key may be invalid.\n'
            'Get a new key at https://aistudio.google.com';
      } else if (response.statusCode == 403) {
        return '❌ Access denied (403). Check your API key is correct and '
            'the Generative Language API is enabled in Google Cloud Console.';
      } else if (response.statusCode == 429) {
        return '⏳ Rate limit reached. You\'re sending too many requests. '
            'Wait a moment and try again.';
      } else {
        return '❌ API Error ${response.statusCode}:\n${response.body}';
      }
    } catch (e) {
      return '❌ Network error: $e\n\nCheck your internet connection and try again.';
    }
  }
}
