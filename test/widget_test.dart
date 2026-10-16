import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:do_or_die/main.dart';

void main() {
  testWidgets('목표를 등록하면 상세 화면으로 들어간다', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 2000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const DoOrDieApp());

    expect(find.text('TO DO'), findsOneWidget);
    expect(find.text('아직 목표가 없습니다'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '  마트에서 장보기  ');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '등록'));
    await tester.pump();

    expect(find.text('마트에서 장보기'), findsOneWidget);
    expect(find.text('아직 목표가 없습니다'), findsNothing);
    expect(find.text('목표 1'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);

    await tester.tap(find.text('마트에서 장보기'));
    await tester.pumpAndSettle();

    expect(find.text('상세'), findsOneWidget);
    expect(find.text('마트에서 장보기'), findsWidgets);
  });

  testWidgets('빈 문장은 등록되지 않는다', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 2000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const DoOrDieApp());

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();

    final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, '등록'));
    expect(button.onPressed, isNull);
    expect(find.text('아직 목표가 없습니다'), findsOneWidget);
  });

  testWidgets('캘린더를 누르면 캘린더 화면으로 들어간다', (WidgetTester tester) async {
    await tester.pumpWidget(const DoOrDieApp());

    await tester.tap(find.text('📅'));
    await tester.pumpAndSettle();

    expect(find.text('캘린더'), findsOneWidget);
    expect(find.byType(CalendarDatePicker), findsOneWidget);
  });

  testWidgets('통제 시작 버튼을 누르면 유튜브 차단 안내가 나온다', (WidgetTester tester) async {
    const channel = MethodChannel('do_or_die/app_block');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'startYoutubeBlock');
      return 'started';
    });
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    });

    await tester.pumpWidget(const DoOrDieApp());

    await tester.tap(find.widgetWithText(FilledButton, '통제 시작'));
    await tester.pump();

    expect(find.text('유튜브 앱 실행을 막았습니다'), findsOneWidget);
  });
}
