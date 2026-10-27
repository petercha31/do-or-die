import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

const startReminderLead = Duration(minutes: 5);

DateTime? startReminderTime(DateTime? startAt, DateTime now) {
  if (startAt == null) {
    return null;
  }
  final remindAt = startAt.subtract(startReminderLead);
  if (!remindAt.isAfter(now)) {
    return null;
  }
  return remindAt;
}

class GoalReminders {
  GoalReminders._();

  static final instance = GoalReminders._();

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'goal_start',
      '목표 시작 알림',
      channelDescription: '목표 시작 5분 전에 알려 줍니다',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _initializing;

  Future<void> scheduleStart({
    required int id,
    required String text,
    required DateTime? startAt,
  }) async {
    final remindAt = startReminderTime(startAt, DateTime.now());
    if (remindAt == null) {
      return;
    }
    await _ready();
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    final exact = await android?.canScheduleExactNotifications() ?? false;
    await _plugin.zonedSchedule(
      id: id,
      title: '5분 후 시작합니다',
      body: text,
      scheduledDate: tz.TZDateTime.from(remindAt.toUtc(), tz.UTC),
      notificationDetails: _details,
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelAll() async {
    await _ready();
    await _plugin.cancelAllPendingNotifications();
  }

  Future<void> _ready() {
    return _initializing ??= _initialize();
  }

  Future<void> _initialize() async {
    tz_data.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }
}
