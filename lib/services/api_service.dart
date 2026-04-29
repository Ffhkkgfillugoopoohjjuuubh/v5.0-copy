import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/chat_message.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _missingKeyMessage =
      'API key error. Please contact support.';
  static const String _networkErrorMessage =
      'Unable to connect to Echo AI. Please check your internet and try again.';

  Uri get _chatCompletionsUri => Uri.parse(groqApiEndpoint);

  Future<String> sendMessage(List<ChatMessage> messages) async {
    if (_isMissingKey) {
      return _missingKeyMessage;
    }

    final payload = <String, dynamic>{
      'model': groqModel,
      'messages': <Map<String, String>>[
        <String, String>{
          'role': 'system',
          'content': teacherSystemPrompt,
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

    try {
      final response = await _client.post(
        _chatCompletionsUri,
        headers: <String, String>{
          'Authorization': 'Bearer $groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final friendly = _friendlyMessageForStatusCode(response.statusCode);
        if (friendly != null) {
          return friendly;
        }

        return _networkErrorMessage;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = json['choices'] as List<dynamic>? ?? <dynamic>[];
      final firstChoice =
          choices.isNotEmpty ? choices.first as Map<String, dynamic> : null;
      final message = firstChoice?['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String?;

      if (content == null || content.trim().isEmpty) {
        return _networkErrorMessage;
      }

      return content.trim();
    } on SocketException {
      return _networkErrorMessage;
    } on http.ClientException {
      return _networkErrorMessage;
    } catch (_) {
      return _networkErrorMessage;
    }
  }

  Future<String> expandResponse(String original) async {
    if (original.trim().isEmpty || _wordCount(original) >= 100 || _isMissingKey) {
      return original;
    }

    try {
      return await _sendUtilityPrompt(
        'Expand the following answer with helpful examples and a warm encouraging ending. Keep it clear, student-friendly, and around 140-180 words. Return only the expanded answer.\n\n$original',
      );
    } catch (_) {
      return original;
    }
  }

  Future<String> translateText(String text, String targetLanguage) async {
    final normalizedTarget = targetLanguage.trim();
    if (text.trim().isEmpty ||
        normalizedTarget.toLowerCase().startsWith('en') ||
        normalizedTarget.toLowerCase() == 'english' ||
        _isMissingKey) {
      return text;
    }

    try {
      return await _sendTranslationPrompt(
        text: text,
        targetLanguage: normalizedTarget,
      );
    } catch (_) {
      return text;
    }
  }

  Future<String> _sendUtilityPrompt(String prompt) async {
    final response = await _client.post(
      _chatCompletionsUri,
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
              'content':
                  '$teacherSystemPrompt Be concise and return only the requested text.',
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
      final friendly = _friendlyMessageForStatusCode(response.statusCode);
      throw Exception(friendly ?? _networkErrorMessage);
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'] as List<dynamic>? ?? <dynamic>[];
    final firstChoice =
        choices.isNotEmpty ? choices.first as Map<String, dynamic> : null;
    final message = firstChoice?['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;

    if (content == null || content.trim().isEmpty) {
      throw Exception(_networkErrorMessage);
    }

    return content.trim();
  }

  bool get _isMissingKey =>
      groqApiKey.trim().isEmpty || groqApiKey == 'GROQ_API_KEY_HERE';

  int _wordCount(String text) {
    return text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  String? _friendlyMessageForStatusCode(int statusCode) {
    if (statusCode == 401 || statusCode == 403) {
      return _missingKeyMessage;
    }
    return null;
  }

  Future<String> _sendTranslationPrompt({
    required String text,
    required String targetLanguage,
  }) async {
    final response = await _client.post(
      _chatCompletionsUri,
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
              'content':
                  'Translate the following text to ${_languageName(targetLanguage)}. Only return the translated text, nothing else.',
            },
            <String, String>{
              'role': 'user',
              'content': text,
            },
          ],
          'temperature': 0.2,
        },
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final friendly = _friendlyMessageForStatusCode(response.statusCode);
      throw Exception(friendly ?? _networkErrorMessage);
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'] as List<dynamic>? ?? <dynamic>[];
    final firstChoice =
        choices.isNotEmpty ? choices.first as Map<String, dynamic> : null;
    final message = firstChoice?['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;

    if (content == null || content.trim().isEmpty) {
      throw Exception(_networkErrorMessage);
    }

    return content.trim();
  }

  String _languageName(String codeOrName) {
    const names = <String, String>{
      'en-US': 'English',
      'hi-IN': 'Hindi',
      'bn-IN': 'Bengali',
      'ta-IN': 'Tamil',
      'te-IN': 'Telugu',
      'kn-IN': 'Kannada',
      'ml-IN': 'Malayalam',
      'mr-IN': 'Marathi',
      'gu-IN': 'Gujarati',
      'pa-IN': 'Punjabi',
      'or-IN': 'Odia',
      'as-IN': 'Assamese',
      'ur-PK': 'Urdu',
      'ar-SA': 'Arabic',
      'fr-FR': 'French',
      'es-ES': 'Spanish',
      'pt-BR': 'Portuguese',
      'ru-RU': 'Russian',
      'de-DE': 'German',
      'it-IT': 'Italian',
      'ja-JP': 'Japanese',
      'ko-KR': 'Korean',
      'zh-CN': 'Chinese',
      'nl-NL': 'Dutch',
      'tr-TR': 'Turkish',
      'vi-VN': 'Vietnamese',
      'th-TH': 'Thai',
      'id-ID': 'Indonesian',
      'pl-PL': 'Polish',
      'sv-SE': 'Swedish',
    };
    return names[codeOrName] ?? codeOrName;
  }
}
