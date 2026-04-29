import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

import 'api_service.dart';

class TtsService {
  factory TtsService() => instance;

  TtsService._();

  static final TtsService instance = TtsService._();

  static const List<String> supportedLanguageCodes = <String>[
    'en-US',
    'hi-IN',
    'bn-IN',
    'ta-IN',
    'te-IN',
    'kn-IN',
    'ml-IN',
    'mr-IN',
    'gu-IN',
    'pa-IN',
    'or-IN',
    'as-IN',
    'ur-PK',
    'ar-SA',
    'fr-FR',
    'es-ES',
    'pt-BR',
    'ru-RU',
    'de-DE',
    'it-IT',
    'ja-JP',
    'ko-KR',
    'zh-CN',
    'nl-NL',
    'tr-TR',
    'vi-VN',
    'th-TH',
    'id-ID',
    'pl-PL',
    'sv-SE',
  ];

  static const Map<String, String> languageNames = <String, String>{
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

  final FlutterTts _flutterTts = FlutterTts();
  final ApiService _apiService = ApiService();
  final StreamController<bool> _speakingController =
      StreamController<bool>.broadcast();

  bool _initialized = false;
  bool _isSpeaking = false;
  bool _stopRequested = false;

  bool get isSpeaking => _isSpeaking;
  Stream<bool> get speakingStream => _speakingController.stream;

  Future<void> init() => initialize();

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.15);
    await _flutterTts.setSpeechRate(0.42);
    _flutterTts.setStartHandler(() => _setSpeaking(true));
    _flutterTts.setCompletionHandler(() => _setSpeaking(false));
    _flutterTts.setCancelHandler(() => _setSpeaking(false));
    _flutterTts.setErrorHandler((_) => _setSpeaking(false));
    _initialized = true;
  }

  Future<void> speak(
    String text, {
    String languageCode = 'en-US',
    double? volume,
    double? pitch,
    double? speechRate,
  }) async {
    if (text.trim().isEmpty) {
      return;
    }

    await initialize();
    await stop();
    _stopRequested = false;

    final locale = _normalizeLocale(languageCode);
    var preparedText = _cleanForSpeech(text);
    final isEnglish = locale.toLowerCase().startsWith('en');

    if (!isEnglish) {
      preparedText = await _apiService.translateText(preparedText, locale);
    }

    final useAsianVoiceSettings = _usesAsianVoiceSettings(locale);
    await _flutterTts.setLanguage(locale);
    await _flutterTts.setVolume((volume ?? 1.0).clamp(0.0, 1.0).toDouble());
    await _flutterTts.setPitch(
      (pitch ?? (useAsianVoiceSettings ? 1.2 : 1.15))
          .clamp(0.5, 2.0)
          .toDouble(),
    );
    await _flutterTts.setSpeechRate(
      (speechRate ?? (useAsianVoiceSettings ? 0.40 : 0.42))
          .clamp(0.1, 1.0)
          .toDouble(),
    );

    final sentences = _dedupeConsecutive(_splitIntoSentences(preparedText));
    if (sentences.isEmpty) {
      return;
    }

    _setSpeaking(true);
    for (final sentence in sentences) {
      if (_stopRequested) {
        break;
      }
      await _flutterTts.speak(sentence);
    }
    _setSpeaking(false);
  }

  Future<void> stop() async {
    _stopRequested = true;
    await _flutterTts.stop();
    _setSpeaking(false);
  }

  String _normalizeLocale(String code) {
    if (supportedLanguageCodes.contains(code)) {
      return code;
    }

    final lower = code.toLowerCase();
    for (final item in supportedLanguageCodes) {
      final itemLower = item.toLowerCase();
      if (itemLower == lower || itemLower.startsWith('$lower-')) {
        return item;
      }
    }

    return 'en-US';
  }

  bool _usesAsianVoiceSettings(String locale) {
    const asianLocales = <String>{
      'hi-IN',
      'bn-IN',
      'ta-IN',
      'te-IN',
      'kn-IN',
      'ml-IN',
      'mr-IN',
      'gu-IN',
      'pa-IN',
      'or-IN',
      'as-IN',
      'ur-PK',
      'ar-SA',
      'ja-JP',
      'ko-KR',
      'zh-CN',
      'vi-VN',
      'th-TH',
      'id-ID',
    };
    return asianLocales.contains(locale);
  }

  String _cleanForSpeech(String text) {
    return text
        .replaceAll(RegExp(r'```[\s\S]*?```'), ' code block omitted ')
        .replaceAll(RegExp(r'[`*_#>\[\]()]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<String> _splitIntoSentences(String text) {
    return text
        .split(RegExp(r'(?<=[.!?।。؟])\s+'))
        .map((sentence) => sentence.trim())
        .where((sentence) => sentence.isNotEmpty)
        .toList();
  }

  List<String> _dedupeConsecutive(List<String> sentences) {
    final filtered = <String>[];
    for (final sentence in sentences) {
      if (filtered.isNotEmpty &&
          filtered.last.toLowerCase() == sentence.toLowerCase()) {
        continue;
      }
      filtered.add(sentence);
    }
    return filtered;
  }

  void _setSpeaking(bool value) {
    if (_isSpeaking == value) {
      return;
    }
    _isSpeaking = value;
    if (!_speakingController.isClosed) {
      _speakingController.add(value);
    }
  }
}
