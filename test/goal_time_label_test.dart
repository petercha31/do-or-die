import 'package:flutter_test/flutter_test.dart';

import 'package:do_or_die/goal_time_label.dart';

void main() {
  final now = DateTime(2026, 10, 26, 19);

  test('남은 시간을 분:초로 보여 준다', () {
    expect(remainingMinutesSeconds(now.add(const Duration(minutes: 5, seconds: 9)), now), '05:09');
    expect(remainingMinutesSeconds(now.add(const Duration(minutes: 90)), now), '90:00');
  });

  test('기준 시각이 지났으면 00:00이다', () {
    expect(remainingMinutesSeconds(now.subtract(const Duration(seconds: 1)), now), '00:00');
  });
}
