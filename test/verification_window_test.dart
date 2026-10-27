import 'package:do_or_die/goal_detail_screen.dart';
import 'package:do_or_die/services/goals/goal_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final startAt = DateTime(2026, 10, 26, 18);
  final endAt = DateTime(2026, 10, 26, 19);
  final goal = StoredGoal(
    id: 1,
    text: '작업',
    verification: '사진',
    responseJson: '{}',
    createdAt: startAt,
    startAt: startAt,
    endAt: endAt,
  );

  test('시작시각 전후 5분 동안은 인증할 수 있다', () {
    expect(verificationWindowMessage(goal, startAt.subtract(verificationWindow)), isNull);
    expect(verificationWindowMessage(goal, startAt), isNull);
    expect(verificationWindowMessage(goal, startAt.add(verificationWindow)), isNull);
  });

  test('시작 5분보다 이르면 인증할 수 없다', () {
    expect(
      verificationWindowMessage(
        goal,
        startAt.subtract(verificationWindow).subtract(const Duration(seconds: 1)),
      ),
      '아직 인증 시간이 아닙니다',
    );
  });

  test('시작 5분이 지나면 종료시각 전이어도 인증할 수 없다', () {
    expect(
      verificationWindowMessage(
        goal,
        startAt.add(verificationWindow).add(const Duration(seconds: 1)),
      ),
      '인증 가능 시간이 지났습니다',
    );
  });
}
