import 'package:flutter/services.dart';

Future<String?> loadGeminiApiKey() async {
  final raw = await rootBundle.loadString('.env');
  for (final line in raw.split('\n')) {
    final trimmed = line.trim();
    const prefix = 'GEMINI_API_KEY=';
    if (!trimmed.startsWith(prefix)) {
      continue;
    }
    final value = trimmed.substring(prefix.length).trim();
    if (value.isEmpty) {
      return null;
    }
    return value;
  }
  return null;
}
