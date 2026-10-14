import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  GeminiService({required String apiKey})
    : _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

  final GenerativeModel _model;

  Future<String?> generate(String prompt) async {
    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text;
  }
}
