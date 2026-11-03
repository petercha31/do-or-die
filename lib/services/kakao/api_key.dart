import 'package:flutter/services.dart';

Future<String?> loadKakaoNativeAppKey() async {
  final String raw;
  try {
    raw = await rootBundle.loadString('.env');
  } catch (_) {
    return null;
  }
  for (final line in raw.split('\n')) {
    final trimmed = line.trim();
    const prefix = 'KAKAO_NATIVE_APP_KEY=';
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
