import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  GeminiService({required String apiKey})
    : _model = GenerativeModel(
        model: modelName,
        apiKey: apiKey,
      );

  static const modelName = 'gemini-3.5-flash-lite';

  final GenerativeModel _model;

  Future<String?> generate(String prompt) async {
    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text;
  }

  Future<String?> generateWithImage(
    String prompt,
    Uint8List image,
    String mimeType,
  ) async {
    final response = await _model.generateContent([
      Content.multi([TextPart(prompt), DataPart(mimeType, image)]),
    ]);
    return response.text;
  }
}
