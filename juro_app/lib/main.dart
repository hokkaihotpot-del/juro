import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'app.dart';

final FlutterLocalNotificationsPlugin _notifications =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 日本語ロケール初期化
  await initializeDateFormatting('ja_JP', null);

  // タイムゾーン初期化
  tz.initializeTimeZones();

  // ローカル通知初期化
  await _initNotifications();

  // 毎週月曜日の通知スケジュール（要件3.3.2）
  await _scheduleWeeklyReportReminder();

  runApp(const JuroApp());
}

Future<void> _initNotifications() async {
  const androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const initSettings = InitializationSettings(
    android: androidInit,
    iOS: iosInit,
  );
  await _notifications.initialize(initSettings);
}

Future<void> _scheduleWeeklyReportReminder() async {
  try {
    const androidDetails = AndroidNotificationDetails(
      'juro_weekly_report',
      '週次レポート通知',
      channelDescription: '毎週月曜日に担当医へのレポート送信を確認します',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
        android: androidDetails, iOS: iosDetails);

    final now = tz.TZDateTime.now(tz.local);
    final daysUntilMonday =
        (DateTime.monday - now.weekday + 7) % 7 == 0
            ? 7
            : (DateTime.monday - now.weekday + 7) % 7;
    final nextMonday = now.add(Duration(days: daysUntilMonday));
    final scheduledDate = tz.TZDateTime(tz.local, nextMonday.year,
        nextMonday.month, nextMonday.day, 9, 0);

    await _notifications.zonedSchedule(
      0,
      '先週の献立を担当医に送りますか？',
      '1週間分の食事データが集まりました。担当医への送信をお忘れなく。',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  } catch (_) {
    // 通知権限がない場合はスキップ
  }
}
