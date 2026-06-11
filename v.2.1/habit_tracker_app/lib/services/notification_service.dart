import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const int dailyReminderId = 1001;

  bool isInitialized = false;

  Future<void> initialize() async {
    if (isInitialized) {
      return;
    }

    tz.initializeTimeZones();

    tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await notificationsPlugin.initialize(settings: initializationSettings);

    isInitialized = true;
  }

  Future<bool> requestPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    final IOSFlutterLocalNotificationsPlugin? iosPlugin = notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    bool androidGranted = true;
    bool iosGranted = true;

    if (androidPlugin != null) {
      androidGranted =
          await androidPlugin.requestNotificationsPermission() ?? true;
    }

    if (iosPlugin != null) {
      iosGranted =
          await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          true;
    }

    return androidGranted && iosGranted;
  }

  NotificationDetails getNotificationDetails() {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'daily_habit_reminder_channel',
          'Daily Habit Reminder',
          channelDescription: 'Daily reminder notification for habit tracking',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  Future<bool> showTestNotification() async {
    await initialize();

    bool permissionGranted = await requestPermission();

    if (!permissionGranted) {
      return false;
    }

    await notificationsPlugin.show(
      id: 999,
      title: 'Habit Tracker',
      body: 'Notification is working successfully.',
      notificationDetails: getNotificationDetails(),
    );

    return true;
  }

  Future<bool> scheduleDailyReminder(TimeOfDay time) async {
    await initialize();

    bool permissionGranted = await requestPermission();

    if (!permissionGranted) {
      return false;
    }

    await cancelDailyReminder();

    await notificationsPlugin.zonedSchedule(
      id: dailyReminderId,
      title: 'Daily Habit Reminder',
      body: 'Open Habit Tracker and complete today’s habits.',
      scheduledDate: getNextReminderTime(time),
      notificationDetails: getNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    return true;
  }

  Future<void> cancelDailyReminder() async {
    await notificationsPlugin.cancel(id: dailyReminderId);
  }

  tz.TZDateTime getNextReminderTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }
}
