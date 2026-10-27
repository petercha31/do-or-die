import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:do_or_die/services/goals/goal_store.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    GoalStore.path = inMemoryDatabasePath;
  });

  setUp(() async {
    await GoalStore.instance.close();
  });

  test('목표를 저장하고 다시 읽는다', () async {
    const responseJson = '{"options":[{"title":"영수증"}]}';
    final saved = await GoalStore.instance.insert(
      text: '마트에서 장보기',
      verification: '영수증',
      responseJson: responseJson,
    );
    final goals = await GoalStore.instance.list();

    expect(saved.id, greaterThan(0));
    expect(goals, hasLength(1));
    expect(goals.single.text, '마트에서 장보기');
    expect(goals.single.verification, '영수증');
    expect(goals.single.responseJson, responseJson);
  });

  test('등록 목록은 시간순이다', () async {
    await GoalStore.instance.insert(
      text: '먼저',
      verification: '',
      responseJson: '',
    );
    await GoalStore.instance.insert(
      text: '나중',
      verification: '',
      responseJson: '',
    );

    final goals = await GoalStore.instance.listChronological();

    expect(goals.map((goal) => goal.text), ['먼저', '나중']);
    expect(goals.first.createdAt.compareTo(goals.last.createdAt) <= 0, isTrue);
  });

  test('선택한 날짜의 목표만 남긴다', () {
    final goals = [
      StoredGoal(
        id: 1,
        text: '오늘',
        verification: '',
        responseJson: '',
        createdAt: DateTime(2026, 10, 19, 9),
      ),
      StoredGoal(
        id: 2,
        text: '내일',
        verification: '',
        responseJson: '',
        createdAt: DateTime(2026, 10, 20, 8),
      ),
    ];

    final selected = goalsOnDate(goals, DateTime(2026, 10, 19, 23));

    expect(selected.map((goal) => goal.text), ['오늘']);
  });

  test('시작부터 종료까지 날짜에 목표가 남는다', () {
    final goals = [
      StoredGoal(
        id: 1,
        text: '이틀',
        verification: '',
        responseJson: '',
        createdAt: DateTime(2026, 10, 18),
        startAt: DateTime(2026, 10, 19, 21),
        endAt: DateTime(2026, 10, 20, 1),
      ),
    ];

    expect(goalsOnDate(goals, DateTime(2026, 10, 19)).map((goal) => goal.text), ['이틀']);
    expect(goalsOnDate(goals, DateTime(2026, 10, 20)).map((goal) => goal.text), ['이틀']);
    expect(goalsOnDate(goals, DateTime(2026, 10, 18)), isEmpty);
  });

  test('시작시각과 종료시각을 저장한다', () async {
    final startAt = DateTime(2026, 10, 20, 17);
    final endAt = DateTime(2026, 10, 20, 18);
    await GoalStore.instance.insert(
      text: '장보기',
      verification: '영수증',
      responseJson: '{"title":"영수증"}',
      startAt: startAt,
      endAt: endAt,
    );

    final goal = (await GoalStore.instance.list()).single;

    expect(goal.startAt, startAt);
    expect(goal.endAt, endAt);
  });

  test('판정 결과를 저장한다', () async {
    final saved = await GoalStore.instance.insert(
      text: '장보기',
      verification: '영수증',
      responseJson: '{"title":"영수증"}',
    );
    final verifiedAt = DateTime(2026, 10, 20, 17, 30);

    await GoalStore.instance.saveVerdict(
      id: saved.id,
      verdict: 'pass',
      verdictReason: '영수증이 보입니다',
      verifiedAt: verifiedAt,
    );
    final goal = (await GoalStore.instance.list()).single;

    expect(goal.verdict, 'pass');
    expect(goal.verdictReason, '영수증이 보입니다');
    expect(goal.verifiedAt, verifiedAt);
  });

  test('전체 지우면 목록이 빈다', () async {
    await GoalStore.instance.insert(
      text: '지울 목표',
      verification: '',
      responseJson: '',
    );

    await GoalStore.instance.deleteAll();

    expect(await GoalStore.instance.list(), isEmpty);
  });
}
