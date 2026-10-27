import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:do_or_die/calendar_screen.dart';
import 'package:do_or_die/main.dart';
import 'package:do_or_die/services/goals/goal_store.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    GoalStore.path = inMemoryDatabasePath;
  });

  setUp(GoalStore.instance.dropConnection);

  Future<void> settleDatabase(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
    await tester.pump();
  }

  testWidgets('응답 화면 버튼을 누르면 입력한 문장으로 응답 화면이 열린다', (WidgetTester tester) async {
    await tester.pumpWidget(const DoOrDieApp());

    expect(find.text('To Do'), findsOneWidget);
    expect(find.text('목록'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).minLines, 1);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).minLines, 5);

    await tester.enterText(find.byType(TextField), '  8시에 샤워한다  ');
    await tester.tap(find.widgetWithText(FilledButton, '응답 화면'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Gemini 응답'), findsOneWidget);
    expect(find.text('8시에 샤워한다'), findsOneWidget);
    await settleDatabase(tester);
  });

  testWidgets('캘린더의 목표를 누르면 상세 화면으로 들어간다', (WidgetTester tester) async {
    final now = DateTime.now();
    await tester.runAsync(
      () => GoalStore.instance.insert(
        text: '마트에서 장보기',
        verification: '영수증',
        responseJson: '{"title":"영수증"}',
        startAt: DateTime(now.year, now.month, now.day, 17),
        endAt: DateTime(now.year, now.month, now.day, 18),
      ),
    );
    await tester.pumpWidget(const DoOrDieApp());

    await tester.tap(find.byTooltip('캘린더'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await settleDatabase(tester);

    expect(find.text('캘린더'), findsOneWidget);
    expect(find.byType(CalendarDatePicker), findsOneWidget);

    final goalText = find.descendant(
      of: find.byType(CalendarScreen),
      matching: find.text('마트에서 장보기'),
    );
    await tester.ensureVisible(goalText);
    await tester.pump();
    await tester.tap(goalText);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('상세'), findsOneWidget);
  });

  testWidgets('전체 지우기를 누르면 목록의 목표가 사라진다', (WidgetTester tester) async {
    await tester.runAsync(
      () => GoalStore.instance.insert(
        text: '마트에서 장보기',
        verification: '영수증',
        responseJson: '{"title":"영수증"}',
        startAt: DateTime(2026, 10, 26, 17),
        endAt: DateTime(2026, 10, 26, 18),
      ),
    );
    await tester.pumpWidget(const DoOrDieApp());
    await settleDatabase(tester);

    expect(find.text('마트에서 장보기'), findsOneWidget);

    await tester.tap(find.text('전체 지우기'));
    await settleDatabase(tester);

    expect(find.text('마트에서 장보기'), findsNothing);
    expect(find.text('아직 목표가 없습니다'), findsOneWidget);
  });
}
