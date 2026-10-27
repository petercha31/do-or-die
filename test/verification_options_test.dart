import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:do_or_die/services/gemini/verification_options.dart';

void main() {
  test('옵션 JSON은 고른 항목만 담고 시작과 종료를 읽는다', () {
    const raw = '''
{"startAt":"2026-10-20T17:00:00+09:00","endAt":"2026-10-20T18:00:00+09:00","options":[
  {"title":"영수증","description":"계산대를 찍는다"},
  {"title":"장바구니","description":"물건을 찍는다"}
]}
''';

    final parsed = parseVerificationOptions(raw);
    final selected = jsonDecode(parsed.options.first.json) as Map<String, Object?>;

    expect(parsed.startAt, DateTime.parse('2026-10-20T17:00:00+09:00').toLocal());
    expect(parsed.endAt, DateTime.parse('2026-10-20T18:00:00+09:00').toLocal());
    expect(parsed.options, hasLength(2));
    expect(selected['title'], '영수증');
    expect(selected['description'], '계산대를 찍는다');
    expect(selected.containsKey('options'), isFalse);
    expect(selected.containsKey('startAt'), isFalse);
  });

  test('판정 응답을 읽는다', () {
    const raw = '```json\n{"result":"PASS","reason":"영수증에 오늘 날짜가 보입니다"}\n```';

    final verdict = parseVerificationVerdict(raw);

    expect(verdict.result, 'pass');
    expect(verdict.reason, '영수증에 오늘 날짜가 보입니다');
  });

  test('모르는 판정 결과는 거절한다', () {
    expect(
      () => parseVerificationVerdict('{"result":"maybe","reason":""}'),
      throwsFormatException,
    );
  });

  test('시작시각이나 종료시각이 없으면 거절한다', () {
    const raw = '{"options":[{"title":"영수증","description":"계산대를 찍는다"}]}';

    expect(() => parseVerificationOptions(raw), throwsFormatException);
  });
}
