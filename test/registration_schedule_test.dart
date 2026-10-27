import 'package:do_or_die/services/goals/registration_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final startAt = DateTime(2026, 10, 26, 19);
  final endAt = DateTime(2026, 10, 26, 21);
  final registeredAt = DateTime(2026, 10, 26, 17, 10);

  test('N시간 뒤는 등록 시점부터 시작하고 길이는 유지한다', () {
    final schedule = scheduleAtRegistration(
      sentence: '2시간 뒤 운동',
      startAt: startAt,
      endAt: endAt,
      registeredAt: registeredAt,
    );

    expect(schedule.startAt, DateTime(2026, 10, 26, 19, 10));
    expect(schedule.endAt, DateTime(2026, 10, 26, 21, 10));
  });

  test('시간과 분이 함께 있으면 둘 다 더한다', () {
    expect(relativeDelay('2시간 30분 뒤에 시작'), const Duration(hours: 2, minutes: 30));
    expect(relativeDelay('30분 후 샤워'), const Duration(minutes: 30));
  });

  test('시각을 정한 문장은 등록 시점으로 밀지 않는다', () {
    final schedule = scheduleAtRegistration(
      sentence: '8시에 샤워한다',
      startAt: DateTime(2026, 10, 26, 20),
      endAt: DateTime(2026, 10, 26, 20, 30),
      registeredAt: registeredAt,
    );

    expect(schedule.startAt, DateTime(2026, 10, 26, 20));
    expect(schedule.endAt, DateTime(2026, 10, 26, 20, 30));
  });

  test('동안은 시작을 미루는 설정이 아니다', () {
    expect(relativeDelay('2시간동안 작업할거야'), isNull);
  });
}
