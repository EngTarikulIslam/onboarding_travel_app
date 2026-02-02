import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        print('Notification tapped: ${response.payload}');
      },
    );

    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'alarm_channel',
        'Travel Alarms',
        description: 'Channel for travel alarm notifications',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      print("Notification channel created");
    }
  }

  Future<bool> requestAllPermissions() async {
    bool allGranted = true;

    final status = await Permission.notification.request();
    allGranted = status.isGranted;

    if (Platform.isAndroid) {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      final exactGranted = await androidImpl?.requestExactAlarmsPermission() ?? false;
      print("Exact alarm permission: $exactGranted");
      allGranted = allGranted && exactGranted;

      if (await Permission.ignoreBatteryOptimizations.isDenied) {
        await Permission.ignoreBatteryOptimizations.request();
        print("Battery optimization request sent");
      }
    }

    print("All permissions: $allGranted");
    return allGranted;
  }

  Future<void> scheduleAlarmNotification({
    required String id,
    required DateTime scheduledDateTime,
    String title = 'Travel Alarm',
    String body = 'Time to start your journey!',
    String? payload,
  }) async {
    if (scheduledDateTime.isBefore(DateTime.now())) {
      print('Cannot schedule past: $scheduledDateTime');
      return;
    }

    final tz.TZDateTime tzScheduled = tz.TZDateTime.from(scheduledDateTime, tz.local);
    print('Scheduling ID: $id at $tzScheduled');

    try {
      await _notificationsPlugin.zonedSchedule(
        id.hashCode,
        title,
        body,
        tzScheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'alarm_channel',
            'Travel Alarms',
            importance: Importance.max,
            priority: Priority.high,
            fullScreenIntent: true,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload ?? id,
      );
      print('Scheduled success for ID: $id');
    } catch (e) {
      print('Schedule failed: $e');
    }
  }

  Future<void> cancelNotification(String id) async {
    await _notificationsPlugin.cancel(id.hashCode);
    print('Cancelled ID: $id');
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
    print('All cancelled');
  }

  Future<void> printPendingNotifications() async {
    final pending = await _notificationsPlugin.pendingNotificationRequests();
    print('Pending count: ${pending.length}');
    for (var req in pending) {
      print('Pending ID: ${req.id}, Payload: ${req.payload}');
    }
  }
}