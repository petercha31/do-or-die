import 'dart:convert';

class VerificationOption {
  const VerificationOption({
    required this.title,
    required this.description,
    required this.json,
  });

  final String title;
  final String description;
  final String json;
}

class ParsedVerificationOptions {
  const ParsedVerificationOptions({
    required this.startAt,
    required this.endAt,
    required this.options,
  });

  final DateTime startAt;
  final DateTime endAt;
  final List<VerificationOption> options;
}

const verdictResults = {'pass', 'fail', 'unclear'};

class VerificationVerdict {
  const VerificationVerdict({required this.result, required this.reason});

  final String result;
  final String reason;
}

VerificationVerdict parseVerificationVerdict(String raw) {
  final decoded = jsonDecode(_stripJsonFence(raw));
  if (decoded is! Map) {
    throw const FormatException('판정 형식이 아닙니다');
  }
  final result = _readString(decoded, const ['result', '결과']).toLowerCase();
  if (!verdictResults.contains(result)) {
    throw const FormatException('판정 결과가 없습니다');
  }
  return VerificationVerdict(
    result: result,
    reason: _readString(decoded, const ['reason', '이유']),
  );
}

String localIso8601(DateTime time) {
  final local = time.toLocal();
  final offset = local.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final hours = offset.inHours.abs().toString().padLeft(2, '0');
  final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
  String two(int value) => value.toString().padLeft(2, '0');
  return '${local.year.toString().padLeft(4, '0')}-${two(local.month)}-${two(local.day)}'
      'T${two(local.hour)}:${two(local.minute)}:${two(local.second)}'
      '$sign$hours:$minutes';
}

String prettyJson(String raw) {
  final body = _stripJsonFence(raw.trim());
  if (body.isEmpty) {
    return raw;
  }
  try {
    return const JsonEncoder.withIndent('  ').convert(jsonDecode(body));
  } on FormatException {
    return raw;
  }
}

ParsedVerificationOptions parseVerificationOptions(String raw) {
  final decoded = jsonDecode(_stripJsonFence(raw));
  if (decoded is! Map) {
    throw const FormatException('시작시각과 종료시각이 없습니다');
  }
  final startAt = _readDateTime(decoded, const ['startAt', '시작시각']);
  final endAt = _readDateTime(decoded, const ['endAt', '종료시각']);
  if (endAt.isBefore(startAt)) {
    throw const FormatException('종료시각이 시작시각보다 이릅니다');
  }
  final items = _readItems(decoded);
  if (items.isEmpty) {
    throw const FormatException('인증 옵션이 없습니다');
  }
  return ParsedVerificationOptions(
    startAt: startAt,
    endAt: endAt,
    options: [for (final item in items) _readOption(item)],
  );
}

String _stripJsonFence(String raw) {
  var text = raw.trim();
  if (!text.startsWith('```')) {
    return text;
  }
  final firstLineEnd = text.indexOf('\n');
  if (firstLineEnd == -1) {
    return text;
  }
  text = text.substring(firstLineEnd + 1);
  if (text.endsWith('```')) {
    text = text.substring(0, text.length - 3);
  }
  return text.trim();
}

List<Object?> _readItems(Object? decoded) {
  if (decoded is List) {
    return decoded;
  }
  if (decoded is Map) {
    final options = decoded['options'] ?? decoded['옵션'];
    if (options is List) {
      return options;
    }
  }
  throw const FormatException('인증 옵션 형식이 아닙니다');
}

VerificationOption _readOption(Object? item) {
  if (item is String && item.trim().isNotEmpty) {
    final title = item.trim();
    return VerificationOption(title: title, description: '', json: jsonEncode(title));
  }
  if (item is Map) {
    final title = _readString(item, const ['title', '제목']);
    if (title.isEmpty) {
      throw const FormatException('인증 옵션 제목이 없습니다');
    }
    return VerificationOption(
      title: title,
      description: _readString(item, const ['description', '설명']),
      json: jsonEncode(item),
    );
  }
  throw const FormatException('인증 옵션 형식이 아닙니다');
}

DateTime _readDateTime(Map<dynamic, dynamic> json, List<String> keys) {
  final raw = _readString(json, keys);
  if (raw.isEmpty) {
    throw const FormatException('시작시각과 종료시각이 없습니다');
  }
  try {
    return DateTime.parse(raw).toLocal();
  } on FormatException {
    throw const FormatException('시작시각과 종료시각이 없습니다');
  }
}

String _readString(Map<dynamic, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return '';
}
