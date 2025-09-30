import 'dart:convert';
import 'dart:io';
import 'package:dayflow/core/constants/notification_constants.dart';
import 'package:dayflow/core/services/notifications/notification_scheduler.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:dayflow/data/models/habit_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static const String _tag = 'NotificationService';

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  late final FlutterLocalNotificationsPlugin _plugin;
  late final NotificationScheduler _scheduler;

  bool _isInitialized = false;
  bool _hasPermission = false;
  BuildContext? _context;

  bool get isInitialized => _isInitialized;
  bool get hasPermission => _hasPermission;

  void setContext(BuildContext context) {
    _context = context;
  }

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      DebugLogger.info('Initializing notification service', tag: _tag);

      _plugin = GetIt.I<FlutterLocalNotificationsPlugin>();

      await _initializeTimezone();
      _hasPermission = await _requestPermissions();
      await _initializePlugin();

      if (Platform.isAndroid) {
        await _createChannels();
      }

      _scheduler = NotificationScheduler(_plugin);
      _isInitialized = true;

      DebugLogger.success('Notification service initialized', tag: _tag);
      return true;
    } catch (e) {
      DebugLogger.error('Initialization failed', tag: _tag, error: e);
      return false;
    }
  }

  Future<void> _initializeTimezone() async {
    try {
      tz.initializeTimeZones();
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      tz.setLocalLocation(tz.UTC);
      DebugLogger.warning('Using UTC timezone', tag: _tag);
    }
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return true;
  }

  Future<void> _initializePlugin() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );
  }

  Future<void> _createChannels() async {
    final androidPlugin =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (androidPlugin == null) return;

    for (final entry in NotificationChannels.configs.entries) {
      final channelId = entry.key;
      final config = entry.value;

      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          channelId,
          config.name,
          description: config.description,
          importance: _mapImportance(config.importance),
          playSound: true,
          enableVibration: true,
          enableLights: true,
        ),
      );
    }
  }

  void _handleNotificationResponse(NotificationResponse response) {
    DebugLogger.info('Notification tapped', tag: _tag, data: response.payload);

    if (response.payload == null || _context == null) return;

    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      final type = data[NotificationPayloadKeys.type] as String?;

      if (type == NotificationTypes.task) {
        final taskId = data[NotificationPayloadKeys.taskId] as String?;
        if (taskId != null) {
          _navigateToTask(taskId);
        }
      } else if (type == NotificationTypes.habit) {
        final habitId = data[NotificationPayloadKeys.habitId] as String?;
        if (habitId != null) {
          _navigateToHabit(habitId);
        }
      }
    } catch (e) {
      DebugLogger.error(
        'Failed to handle notification tap',
        tag: _tag,
        error: e,
      );
    }
  }

  void _navigateToTask(String taskId) {
    if (_context == null) return;

    GoRouter.of(_context!).go('/');
    DebugLogger.info('Navigated to task', tag: _tag, data: taskId);
  }

  void _navigateToHabit(String habitId) {
    if (_context == null) return;

    GoRouter.of(_context!).go('/');
    DebugLogger.info('Navigated to habit', tag: _tag, data: habitId);
  }

  Future<bool> scheduleTaskNotification(TaskModel task) async {
    if (!_canSchedule()) return false;
    return await _scheduler.scheduleTaskNotification(task);
  }

  Future<bool> scheduleHabitNotification(
    HabitModel habit, {
    DateTime? specificDate,
  }) async {
    if (!_canSchedule()) return false;
    return await _scheduler.scheduleHabitNotification(
      habit,
      specificDate: specificDate,
    );
  }

  Future<void> cancelTaskNotification(String taskId) async {
    if (!_isInitialized) return;
    await _scheduler.cancelNotification(taskId, NotificationTypes.task);
  }

  Future<void> cancelHabitNotification(String habitId) async {
    if (!_isInitialized) return;
    await _scheduler.cancelNotification(habitId, NotificationTypes.habit);
  }

  Future<bool> showNotification({
    required String title,
    required String body,
    String? payload,
    String? channelId,
  }) async {
    if (!_canSchedule()) return false;

    try {
      final channel = channelId ?? NotificationChannels.general;
      final config = NotificationChannels.configs[channel]!;

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          channel,
          config.name,
          channelDescription: config.description,
          importance: _mapImportance(config.importance),
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _plugin.show(id, title, body, details, payload: payload);

      return true;
    } catch (e) {
      DebugLogger.error('Show notification failed', tag: _tag, error: e);
      return false;
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_isInitialized) return [];
    try {
      return await _plugin.pendingNotificationRequests();
    } catch (e) {
      DebugLogger.error(
        'Failed to get pending notifications',
        tag: _tag,
        error: e,
      );
      return [];
    }
  }

  Future<void> cancelAll() async {
    if (!_isInitialized) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      DebugLogger.error(
        'Failed to cancel all notifications',
        tag: _tag,
        error: e,
      );
    }
  }

  Future<bool> testNotification() async {
    if (!_canSchedule()) return false;

    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.general,
          'Test',
          channelDescription: 'Test notification',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      final payload = jsonEncode({
        'type': 'test',
        'message': 'Test notification',
      });

      await _plugin.show(
        99999,
        'Test Notification',
        'This is a test notification',
        details,
        payload: payload,
      );

      return true;
    } catch (e) {
      DebugLogger.error('Test notification failed', tag: _tag, error: e);
      return false;
    }
  }

  bool _canSchedule() => _isInitialized && _hasPermission;

  Importance _mapImportance(int level) {
    return switch (level) {
      5 => Importance.max,
      4 => Importance.high,
      3 => Importance.defaultImportance,
      2 => Importance.low,
      _ => Importance.min,
    };
  }
}
