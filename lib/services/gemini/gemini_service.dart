import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  GeminiService({required String apiKey})
    : _model = GenerativeModel(
        model: modelName,
        apiKey: apiKey,
      );

  static const modelName = 'gemini-4-argon';

  final GenerativeModel _model;

  Future<String?> generate(String prompt) async {
    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text;
  }
}
