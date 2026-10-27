import 'package:flutter_test/flutter_test.dart';

import 'package:do_or_die/services/notifications/goal_reminders.dart';

void main() {
  final now = DateTime(2026, 10, 21, 15, 30);

  test('시작 5분 전에 알린다', () {
    expect(
      startReminderTime(DateTime(2026, 10, 21, 20), now),
      DateTime(2026, 10, 21, 19, 55),
    );
  });

  test('알림 시각이 지났으면 예약하지 않는다', () {
    expect(startReminderTime(DateTime(2026, 10, 21, 15, 33), now), isNull);
    expect(startReminderTime(DateTime(2026, 10, 21, 15), now), isNull);
  });

  test('시작시각이 없으면 예약하지 않는다', () {
    expect(startReminderTime(null, now), isNull);
  });
}
