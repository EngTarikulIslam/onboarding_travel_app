import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_init;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Call this once at app startup (preferably in main after WidgetsFlutterBinding)
  Future<void> initialize() async {
    tz_init.initializeTimeZones();

    await AwesomeNotifications().initialize(
      null, // default icon (or use your @mipmap/ic_launcher)
      [
        NotificationChannel(
          channelKey: 'alarm_channel',
          channelName: 'Travel Alarms',
          channelDescription: 'Notifications for travel reminders and alarms',
          defaultColor: const Color(0xFF5200FF),
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: lowVibrationPattern,
          // soundSource: 'resource://raw/alarm_sound',   // uncomment if you added raw/alarm_sound.mp3
          criticalAlerts: true,
          locked: true,
        ),
      ],
      debug: true,
    );

    // Register action listeners
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onActionReceived,
      onNotificationCreatedMethod: _onNotificationCreated,
      onNotificationDisplayedMethod: _onNotificationDisplayed,
      onDismissActionReceivedMethod: _onDismissActionReceived,
    );

    print('Awesome Notifications initialized');
  }

  // ───────────────────────────────────────────────
  //  Permissions – modern / realistic approach 2025–2026
  // ───────────────────────────────────────────────
  Future<bool> requestAllPermissions() async {
    bool granted = true;

    // 1. Normal notification permission
    if (!await AwesomeNotifications().isNotificationAllowed()) {
      granted = await AwesomeNotifications().requestPermissionToSendNotifications();
      print('Notification permission: $granted');
    }

    // 2. Android exact alarm permission – no direct request method in recent versions
    //    User must manually allow "Alarms & reminders" in app info
    if (Platform.isAndroid) {
      // We can only politely ask / guide user
      // The SCHEDULE_EXACT_ALARM permission in manifest is still required
      print('Note: For exact alarms on Android 13+, user must allow "Alarms & reminders" in settings');
    }

    // 3. Battery optimization bypass (very important for background scheduling)
    if (Platform.isAndroid) {
      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
      if (!batteryStatus.isGranted) {
        final result = await Permission.ignoreBatteryOptimizations.request();
        print('Battery optimization permission: ${result.isGranted}');
        granted = granted && result.isGranted;
      }
    }

    return granted;
  }

  // ───────────────────────────────────────────────
  //  Schedule zoned (exact) alarm notification
  // ───────────────────────────────────────────────
  Future<bool> scheduleAlarmNotification({
    required String id,
    required DateTime scheduledDateTime,
    String title = 'Travel Alarm',
    String body = 'Time to start your journey!',
    String? payload,
  }) async {
    if (scheduledDateTime.isBefore(DateTime.now())) {
      print('Cannot schedule past time: $scheduledDateTime');
      return false;
    }

    final tz.TZDateTime tzScheduled = tz.TZDateTime.from(scheduledDateTime, tz.local);

    print('→ Scheduling alarm  |  ID: $id  |  $tzScheduled');

    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id.hashCode,
          channelKey: 'alarm_channel',
          title: title,
          body: body,
          payload: {
            'alarm_id': id,
            if (payload != null) 'custom_payload': payload,
          },
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          autoDismissible: false,
        ),
        schedule: NotificationCalendar.fromDate(
          date: tzScheduled,
          preciseAlarm: true,           // ← this is the most important flag
          allowWhileIdle: true,
          repeats: false,
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'snooze',
            label: 'Snooze 5 min',
            color: const Color(0xFF8A2BE2),
            autoDismissible: false,
          ),
          NotificationActionButton(
            key: 'dismiss',
            label: 'Dismiss',
            color: const Color(0xFF5200FF),
            autoDismissible: true,
          ),
        ],
      );

      print('Alarm scheduled successfully → $tzScheduled');
      return true;
    } catch (e, stack) {
      print('Schedule failed: $e');
      debugPrintStack(stackTrace: stack);
      return false;
    }
  }

  // ───────────────────────────────────────────────
  //  Cancel helpers
  // ───────────────────────────────────────────────
  Future<void> cancelNotification(String id) async {
    await AwesomeNotifications().cancel(id.hashCode);
    print('Cancelled alarm: $id');
  }

  Future<void> cancelAll() async {
    await AwesomeNotifications().cancelAll();
    print('All alarms cancelled');
  }

  Future<void> printPending() async {
    final pending = await AwesomeNotifications().listScheduledNotifications();
    print('Pending scheduled notifications: ${pending.length}');
    for (var n in pending) {
      print('  • ID: ${n.content?.id}   ${n.schedule?.toMap()}');
    }
  }

  // ───────────────────────────────────────────────
  //  Action / lifecycle handlers
  // ───────────────────────────────────────────────
  static Future<void> _onActionReceived(ReceivedAction action) async {
    print('Action pressed: ${action.buttonKeyPressed}');

    if (action.buttonKeyPressed == 'snooze') {
      final newTime = DateTime.now().add(const Duration(minutes: 5));
      await NotificationService().scheduleAlarmNotification(
        id: 'snooze_${DateTime.now().millisecondsSinceEpoch}',
        scheduledDateTime: newTime,
        title: 'Snoozed Alarm',
        body: 'Reminder moved +5 minutes',
      );
    }
  }

  static Future<void> _onNotificationCreated(ReceivedNotification n) async {
    print('Notification created → ID: ${n.id}');
  }

  static Future<void> _onNotificationDisplayed(ReceivedNotification n) async {
    print('Notification shown → ID: ${n.id}');
  }

  static Future<void> _onDismissActionReceived(ReceivedAction action) async {
    print('Notification dismissed → ID: ${action.id}');
  }
}