import 'package:flutter/services.dart';

/// Reads a single `KEY=value` line from the bundled `.env` asset.
Future<String?> loadEnvValue(String key) async {
  final String raw;
  try {
    raw = await rootBundle.loadString('.env');
  } catch (_) {
    return null;
  }
  final prefix = '$key=';
  for (final line in raw.split('\n')) {
    final trimmed = line.trim();
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
