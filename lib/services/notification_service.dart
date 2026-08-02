import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../utils/platform_util.dart';
import '../utils/test_environment.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService.internal();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isSupported = false;
  bool? _canScheduleExactNotifications;

  factory NotificationService() {
    return _instance;
  }

  @visibleForTesting
  NotificationService.internal();

  Future<void> initialize() async {
    if (isTestEnvironment) return;

    if (PlatformUtil.isWeb) {
      debugPrint(
        '[NotificationService] local notifications are not supported on web.',
      );
      return;
    }

    try {
      tz_data.initializeTimeZones();

      String resolvedTimeZone = 'UTC';
      try {
        final detectedTimeZone = await FlutterTimezone.getLocalTimezone();
        if (detectedTimeZone.identifier.isNotEmpty) {
          resolvedTimeZone = detectedTimeZone.identifier;
        }
        debugPrint(
          '[NotificationService] detected timezone: $resolvedTimeZone',
        );
      } on MissingPluginException catch (e) {
        debugPrint('[NotificationService] timezone plugin unavailable: $e');
      } catch (e) {
        debugPrint('[NotificationService] failed to determine timezone: $e');
      }

      try {
        tz.setLocalLocation(tz.getLocation(resolvedTimeZone));
      } catch (e) {
        debugPrint('[NotificationService] falling back to UTC timezone: $e');
        tz.setLocalLocation(tz.UTC);
      }

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@drawable/ic_stat_notification');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await _flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Hook for navigation when a notification is tapped.
        },
      );

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      await androidImplementation?.requestNotificationsPermission();

      if (androidImplementation != null) {
        _canScheduleExactNotifications =
            await androidImplementation.canScheduleExactNotifications();
        if (_canScheduleExactNotifications == false) {
          await androidImplementation.requestExactAlarmsPermission();
          _canScheduleExactNotifications =
              await androidImplementation.canScheduleExactNotifications();
        }
        debugPrint(
          '[NotificationService] exact alarm permission: $_canScheduleExactNotifications',
        );
      }

      _isSupported = true;
    } catch (e) {
      debugPrint('[NotificationService] initialization failed: $e');
      _isSupported = false;
    }
  }

  AndroidScheduleMode get _androidScheduleMode {
    return _canScheduleExactNotifications == false
        ? AndroidScheduleMode.inexactAllowWhileIdle
        : AndroidScheduleMode.exactAllowWhileIdle;
  }

  // 设置任务提醒
  Future<void> scheduleTaskReminder(Task task) async {
    if (!_isSupported || task.id == null) {
      return;
    }

    try {
      // 1. 如果任务已完成，直接取消通知提醒
      if (task.isCompleted) {
        await cancelNotification(task.id!);
        return;
      }

      if (task.dueDate == null) {
        await cancelNotification(task.id!);
        return;
      }

      // 获取本地时区
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
        task.dueDate!,
        tz.local,
      );

      // 2. 避免调度过去的时间导致平台异常崩溃，清理旧通知后直接返回
      final now = tz.TZDateTime.now(tz.local);
      if (scheduledDate.isBefore(now)) {
        await cancelNotification(task.id!);
        return;
      }

      // 取消可能已经存在的提醒
      await cancelNotification(task.id!);

      // 根据优先级定义通知详情
      NotificationDetails notificationDetails =
          _getNotificationDetailsByPriority(task.reminderPriority);

      final hasRepeat =
          task.repeatFrequency != null && task.repeatFrequency!.isNotEmpty;
      final monthlyDateCanRepeat =
          task.repeatFrequency != 'monthly' || scheduledDate.day <= 28;

      if (!hasRepeat ||
          (task.repeatInterval ?? 1) > 1 ||
          !monthlyDateCanRepeat) {
        await _scheduleOneShotNotification(
          task,
          scheduledDate,
          notificationDetails,
        );
        return;
      }

      switch (task.repeatFrequency) {
        case 'daily':
          await _flutterLocalNotificationsPlugin.zonedSchedule(
            id: task.id!,
            title: _getNotificationTitle(task),
            body: task.title,
            scheduledDate: scheduledDate,
            notificationDetails: notificationDetails,
            androidScheduleMode: _androidScheduleMode,
            payload: task.id.toString(),
            matchDateTimeComponents: DateTimeComponents.time,
          );
          break;
        case 'weekly':
          await _flutterLocalNotificationsPlugin.zonedSchedule(
            id: task.id!,
            title: _getNotificationTitle(task),
            body: task.title,
            scheduledDate: scheduledDate,
            notificationDetails: notificationDetails,
            androidScheduleMode: _androidScheduleMode,
            payload: task.id.toString(),
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
          break;
        case 'monthly':
          await _flutterLocalNotificationsPlugin.zonedSchedule(
            id: task.id!,
            title: _getNotificationTitle(task),
            body: task.title,
            scheduledDate: scheduledDate,
            notificationDetails: notificationDetails,
            androidScheduleMode: _androidScheduleMode,
            payload: task.id.toString(),
            matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
          );
          break;
        default:
          await _scheduleOneShotNotification(
            task,
            scheduledDate,
            notificationDetails,
          );
      }
    } catch (e) {
      debugPrint('[NotificationService] failed to schedule reminder: $e');
    }
  }

  Future<void> _scheduleOneShotNotification(
    Task task,
    tz.TZDateTime scheduledDate,
    NotificationDetails notificationDetails,
  ) async {
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: task.id!,
      title: _getNotificationTitle(task),
      body: task.title,
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: _androidScheduleMode,
      payload: task.id.toString(),
    );
  }

  // 根据优先级获取通知标题
  String _getNotificationTitle(Task task) {
    switch (task.reminderPriority) {
      case 1:
        return 'Low priority reminder';
      case 3:
        return 'High priority reminder';
      case 2:
      default:
        return 'Task reminder';
    }
  }

  // 根据优先级获取通知详情
  NotificationDetails _getNotificationDetailsByPriority(int priority) {
    AndroidNotificationDetails androidDetails;
    DarwinNotificationDetails iosDetails; // 使用 Darwin 代替 IOS

    Priority notificationPriority;
    Importance importance;

    switch (priority) {
      case 1: // Low
        notificationPriority = Priority.low;
        importance = Importance.low;
        break;
      case 3: // High
        notificationPriority = Priority.high;
        importance = Importance.high;
        break;
      case 2: // Medium (Default)
      default:
        notificationPriority = Priority.defaultPriority;
        importance = Importance.defaultImportance;
        break;
    }

    androidDetails = AndroidNotificationDetails(
      'task_reminders', // Channel ID
      'Task Reminders', // Channel Name
      channelDescription: 'Notifications for task reminders',
      icon: '@drawable/ic_stat_notification',
      importance: importance,
      priority: notificationPriority,
      // Add other Android specific details if needed
    );

    iosDetails = _getIOSNotificationDetailsByPriority(priority);

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails, // 使用 iOS 字段
    );
  }

  // 根据优先级获取iOS通知详情
  DarwinNotificationDetails _getIOSNotificationDetailsByPriority(int priority) {
    switch (priority) {
      case 1: // 低优先级
        return const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.passive, // 被动中断级别
        );
      case 3: // 高优先级
        return const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          // Critical Alerts require a separate iOS entitlement. Time-sensitive
          // keeps high-priority reminders prominent without that entitlement.
          interruptionLevel: InterruptionLevel.timeSensitive,
        );
      case 2: // 中优先级（默认）
      default:
        return const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.active, // 活跃中断级别
        );
    }
  }

  // 取消特定任务的通知
  Future<void> cancelNotification(int id) async {
    if (!_isSupported) return;

    try {
      await _flutterLocalNotificationsPlugin.cancel(id: id);
    } catch (e) {
      debugPrint('[NotificationService] failed to cancel notification: $e');
    }
  }

  // 取消所有通知
  Future<void> cancelAllNotifications() async {
    if (!_isSupported) return;

    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint(
        '[NotificationService] failed to cancel all notifications: $e',
      );
    }
  }
}
