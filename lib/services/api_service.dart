import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/chat_message.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<String> sendMessage(List<ChatMessage> messages) async {
    if (_isPlaceholderKey) {
      throw Exception('Add your Groq API key in lib/config/api_config.dart.');
    }

    final payload = <String, dynamic>{
      'model': groqModel,
      'messages': <Map<String, String>>[
        <String, String>{
          'role': 'system',
          'content': 'You are Echo AI, a patient and encouraging teacher.',
        },
        ...messages.map(
          (message) => <String, String>{
            'role': message.role,
            'content': message.content,
          },
        ),
      ],
      'temperature': 0.7,
    };

    final response = await _client.post(
      Uri.parse(groqApiEndpoint),
      headers: <String, String>{
        'Authorization': 'Bearer $groqApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(response.body));
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'] as List<dynamic>? ?? <dynamic>[];
    final firstChoice =
        choices.isNotEmpty ? choices.first as Map<String, dynamic> : null;
    final message = firstChoice?['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;

    if (content == null || content.trim().isEmpty) {
      throw Exception('Groq returned an empty response.');
    }

    return content.trim();
  }

  Future<String> expandResponse(String original) async {
    if (original.trim().isEmpty || _wordCount(original) >= 80 || _isPlaceholderKey) {
      return original;
    }

    try {
      return await _sendUtilityPrompt(
        'Expand the following answer to around 120 words while staying clear, warm, and easy to understand. Return only the expanded answer.\n\n$original',
      );
    } catch (_) {
      return original;
    }
  }

  Future<String> translateText(String text, String targetLanguage) async {
    if (text.trim().isEmpty ||
        targetLanguage.toLowerCase() == 'english' ||
        _isPlaceholderKey) {
      return text;
    }

    try {
      return await _sendUtilityPrompt(
        'Translate the following text to $targetLanguage. Return only the translated text.\n\n$text',
      );
    } catch (_) {
      return text;
    }
  }

  Future<String> _sendUtilityPrompt(String prompt) async {
    final response = await _client.post(
      Uri.parse(groqApiEndpoint),
      headers: <String, String>{
        'Authorization': 'Bearer $groqApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(
        <String, dynamic>{
          'model': groqModel,
          'messages': <Map<String, String>>[
            <String, String>{
              'role': 'system',
              'content': 'You are Echo AI, a patient and encouraging teacher.',
            },
            <String, String>{
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.4,
        },
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(response.body));
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'] as List<dynamic>? ?? <dynamic>[];
    final firstChoice =
        choices.isNotEmpty ? choices.first as Map<String, dynamic> : null;
    final message = firstChoice?['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;

    if (content == null || content.trim().isEmpty) {
      throw Exception('Groq returned an empty response.');
    }

    return content.trim();
  }

  bool get _isPlaceholderKey => groqApiKey.contains('PASTE_YOUR_GROQ_API_KEY_HERE');

  int _wordCount(String text) {
    return text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  String _extractErrorMessage(String rawBody) {
    try {
      final json = jsonDecode(rawBody) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      return error?['message'] as String? ?? 'Groq request failed.';
    } catch (_) {
      return 'Groq request failed.';
    }
  }
}
