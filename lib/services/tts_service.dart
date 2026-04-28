import 'package:flutter_tts/flutter_tts.dart';

import 'api_service.dart';

class TtsService {
  TtsService._();

  static final TtsService instance = TtsService._();

  final FlutterTts _flutterTts = FlutterTts();
  final ApiService _apiService = ApiService();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.15);
    await _flutterTts.setSpeechRate(0.42);
    _initialized = true;
  }

  Future<void> speak(
    String text, {
    String languageCode = 'en',
    double? volume,
    double? pitch,
    double? speechRate,
  }) async {
    if (text.trim().isEmpty) {
      return;
    }

    await init();
    await stop();

    final normalizedLanguage = languageCode.toLowerCase();
    var preparedText = text.trim();
    var effectivePitch = pitch ?? 1.15;
    final effectiveRate = speechRate ?? 0.42;

    if (normalizedLanguage == 'hi') {
      preparedText = await _apiService.translateText(preparedText, 'Hindi');
      effectivePitch = pitch ?? 1.2;
      await _flutterTts.setLanguage('hi-IN');
    } else if (normalizedLanguage == 'bn') {
      preparedText = await _apiService.translateText(preparedText, 'Bengali');
      effectivePitch = pitch ?? 1.2;
      await _flutterTts.setLanguage('bn-IN');
    } else {
      await _flutterTts.setLanguage('en-IN');
    }

    await _flutterTts.setVolume((volume ?? 1.0).clamp(0.0, 1.0));
    await _flutterTts.setPitch(effectivePitch.clamp(0.5, 2.0));
    await _flutterTts.setSpeechRate(effectiveRate.clamp(0.1, 1.0));

    for (final sentence in _splitIntoSentences(preparedText)) {
      if (sentence.trim().isEmpty) {
        continue;
      }
      await _flutterTts.speak(sentence.trim());
    }
  }

  Future<void> stop() => _flutterTts.stop();

  List<String> _splitIntoSentences(String text) {
    return text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((sentence) => sentence.trim().isNotEmpty)
        .toList();
  }
}
