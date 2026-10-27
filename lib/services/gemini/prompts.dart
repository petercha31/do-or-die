abstract final class GeminiPrompts {
  static const verificationOptions = '''
이 목표를 인증하는 방법 3가지를 JSON으로만 응답해.
형식은 {"startAt":"","endAt":"","options":[{"title":"","description":""}]} 이다.
startAt은 목표 시작시각, endAt은 목표 종료시각이다. 둘 다 비우지 말고 ISO-8601에 시간대 오프셋을 붙인다.
options는 3개다.
다른 문장과 코드 펜스는 넣지 마.

현재시각: 
''';

  static const verifyEvidence = '''
첨부한 사진이 아래 목표를 아래 인증 방법대로 해냈다는 증거인지 판정해.
JSON으로만 응답해. 형식은 {"result":"","reason":""} 이다.
result는 pass, fail, unclear 중 하나다.
사진이 인증 방법과 맞으면 pass, 맞지 않으면 fail, 흐리거나 가려져서 판단할 수 없으면 unclear다.
reason은 판정 이유를 한국어 한두 문장으로 쓴다.
다른 문장과 코드 펜스는 넣지 마.

''';
}
