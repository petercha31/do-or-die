abstract final class GeminiPrompts {
  static const verificationOptions = '''
이 목표를 인증하는 방법 3가지를 JSON으로만 응답해.
형식은 {"options":[{"title":"","description":""}]} 이다.
options는 3개다.
다른 문장과 코드 펜스는 넣지 마.

문장:
''';
}
