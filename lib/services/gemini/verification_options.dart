import 'dart:convert';

class VerificationOption {
  const VerificationOption({required this.title, required this.description});

  final String title;
  final String description;
}

List<VerificationOption> parseVerificationOptions(String raw) {
  final decoded = jsonDecode(_stripJsonFence(raw));
  final items = _readItems(decoded);
  if (items.isEmpty) {
    throw const FormatException('인증 옵션이 없습니다');
  }
  return [for (final item in items) _readOption(item)];
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
    return VerificationOption(title: item.trim(), description: '');
  }
  if (item is Map) {
    final title = _readString(item, const ['title', '제목']);
    if (title.isEmpty) {
      throw const FormatException('인증 옵션 제목이 없습니다');
    }
    return VerificationOption(
      title: title,
      description: _readString(item, const ['description', '설명']),
    );
  }
  throw const FormatException('인증 옵션 형식이 아닙니다');
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
