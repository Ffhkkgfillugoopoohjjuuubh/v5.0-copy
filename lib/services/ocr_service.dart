import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  Future<String> extractTextFromFile(File file) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final image = InputImage.fromFile(file);
      final recognizedText = await recognizer.processImage(image);
      return recognizedText.text.trim();
    } catch (_) {
      return '';
    } finally {
      await recognizer.close();
    }
  }
}
