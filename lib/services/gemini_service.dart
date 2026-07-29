import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // Get your FREE key at: https://aistudio.google.com
  // Replace the string below with your actual key.
static const _apiKey = String.fromEnvironment('GEMINI_KEY', defaultValue: '');
  static const _url =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  Future<String> send(String prompt) async {
    if (_apiKey == 'YOUR_GEMINI_API_KEY') {
      return '⚠️ Gemini API key not set.\n\nGo to https://aistudio.google.com → Get API key → copy it → paste it in lib/services/gemini_service.dart replacing YOUR_GEMINI_API_KEY.';
    }

    try {
      final res = await http.post(
        Uri.parse('$_url?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': 'You are FocusMate AI, a helpful productivity assistant for students and working professionals. Answer concisely and helpfully.\n\nUser: $prompt'}
              ]
            }
          ],
          'generationConfig': {'maxOutputTokens': 500, 'temperature': 0.7},
        }),
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        return json['candidates'][0]['content']['parts'][0]['text'] ?? 'No response.';
      } else {
        return 'Error ${res.statusCode}: ${res.body}';
      }
    } catch (e) {
      return 'Connection error. Please check your internet and try again.';
    }
  }
}
