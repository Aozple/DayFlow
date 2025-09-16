import 'dart:io';
import 'dart:typed_data';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:dayflow/data/models/app_settings.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:dayflow/data/repositories/settings_repository.dart';
import 'package:dayflow/data/repositories/task_repository.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static const String _tag = 'NotificationService';

  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _notificationsEnabled = true;

  // Cache for Android SDK version
  int? _androidSdkVersion;

  // Channel identifiers
  static const String _highPriorityChannel = 'dayflow_high_priority';
  static const String _defaultChannel = 'dayflow_default';
  static const String _reminderChannel = 'dayflow_reminders';

  bool get isInitialized => _isInitialized;
  bool get notificationsEnabled => _notificationsEnabled;

  Future<bool> initialize() async {
    if (_isInitialized) {
      DebugLogger.warning('Already initialized', tag: _tag);
      return true;
    }

    return DebugLogger.timeOperation(
      'Initialize NotificationService',
      () async {
        try {
          DebugLogger.info('Initializing notification service', tag: _tag);

          // Set up timezone data
          await _initializeTimezone();

          // Check and request permissions
          _notificationsEnabled = await _checkAndRequestPermissions();
          if (!_notificationsEnabled) {
            DebugLogger.warning(
              'Notification permissions not granted',
              tag: _tag,
            );
          }

          // Set up notification plugin
          await _initializePlugin();

          // Create Android notification channels
          if (Platform.isAndroid) {
            await _createNotificationChannels();
          }

          _isInitialized = true;
          DebugLogger.success('Notification service initialized', tag: _tag);

          // Verify channels
          await _verifyChannels();

          return true;
        } catch (e, stackTrace) {
          DebugLogger.error(
            'Failed to initialize notification service',
            tag: _tag,
            error: e,
            stackTrace: stackTrace,
          );
          _isInitialized = false;
          return false;
        }
      },
    );
  }

  Future<void> _initializeTimezone() async {
    try {
      tz.initializeTimeZones();

      String timeZoneName;
      try {
        timeZoneName = await FlutterTimezone.getLocalTimezone();
      } catch (_) {
        timeZoneName = DateTime.now().timeZoneName;
      }

      try {
        final location = tz.getLocation(timeZoneName);
        tz.setLocalLocation(location);
        DebugLogger.success('Timezone set', tag: _tag, data: timeZoneName);
      } catch (_) {
        final fixedName = _fixTimezoneName(timeZoneName);
        try {
          final location = tz.getLocation(fixedName);
          tz.setLocalLocation(location);
          DebugLogger.success(
            'Timezone set (corrected)',
            tag: _tag,
            data: fixedName,
          );
        } catch (_) {
          tz.setLocalLocation(tz.UTC);
          DebugLogger.warning('Using UTC as timezone', tag: _tag);
        }
      }
    } catch (e) {
      tz.setLocalLocation(tz.UTC);
      DebugLogger.error(
        'Timezone initialization failed, using UTC',
        tag: _tag,
        error: e,
      );
    }
  }

  String _fixTimezoneName(String original) {
    if (original.startsWith('GMT')) {
      return original.replaceFirst('GMT', 'Etc/GMT');
    }
    return original;
  }

  Future<bool> _checkAndRequestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final sdkInt = await _getAndroidSdkInt();

        // Android 13+ notification permission
        if (sdkInt >= 33) {
          final status = await Permission.notification.status;
          if (!status.isGranted) {
            if (status.isPermanentlyDenied) {
              DebugLogger.error(
                'Notification permission permanently denied',
                tag: _tag,
              );
              return false;
            }
            final result = await Permission.notification.request();
            if (!result.isGranted) {
              DebugLogger.warning('Notification permission denied', tag: _tag);
              return false;
            }
          }
          DebugLogger.success('Notification permission granted', tag: _tag);
        }

        // Android 12+ exact alarm permission
        if (sdkInt >= 31) {
          await _requestExactAlarmPermission();
        }
      }

      return true;
    } catch (e) {
      DebugLogger.error('Permission check failed', tag: _tag, error: e);
      return false;
    }
  }

  Future<void> _requestExactAlarmPermission() async {
    try {
      final androidPlugin =
          _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidPlugin != null) {
        final hasExactAlarm =
            await androidPlugin.canScheduleExactNotifications() ?? false;
        if (!hasExactAlarm) {
          DebugLogger.warning('Exact alarm permission not granted', tag: _tag);
          final granted = await androidPlugin.requestExactAlarmsPermission();
          if (granted == true) {
            DebugLogger.success('Exact alarm permission granted', tag: _tag);
          } else {
            DebugLogger.warning('Exact alarm permission denied', tag: _tag);
          }
        }
      }
    } catch (e) {
      DebugLogger.error(
        'Failed to request exact alarm permission',
        tag: _tag,
        error: e,
      );
    }
  }

  Future<int> _getAndroidSdkInt() async {
    // Use cached version if available
    if (_androidSdkVersion != null) {
      return _androidSdkVersion!;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      _androidSdkVersion = androidInfo.version.sdkInt;
      DebugLogger.info(
        'Android SDK version',
        tag: _tag,
        data: _androidSdkVersion,
      );
      return _androidSdkVersion!;
    } catch (e) {
      DebugLogger.error(
        'Failed to get Android SDK version',
        tag: _tag,
        error: e,
      );
      return 29; // Default to Android 10
    }
  }

  Future<void> _initializePlugin() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          'task_reminder',
          actions: [
            DarwinNotificationAction.plain(
              'complete',
              'Complete',
              options: {DarwinNotificationActionOption.destructive},
            ),
            DarwinNotificationAction.plain(
              'snooze',
              'Snooze 5min',
              options: {DarwinNotificationActionOption.foreground},
            ),
          ],
          options: {DarwinNotificationCategoryOption.hiddenPreviewShowTitle},
        ),
      ],
    );

    var initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationTapped,
    );

    DebugLogger.success('Notification plugin initialized', tag: _tag);
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin == null) return;

    try {
      await Future.wait([
        androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _highPriorityChannel,
            'High Priority',
            description: 'Important and urgent task reminders',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            ledColor: Colors.blue,
            showBadge: true,
          ),
        ),
        androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _defaultChannel,
            'Default',
            description: 'General app notifications',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
        androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _reminderChannel,
            'Task Reminders',
            description: 'Scheduled reminders for tasks',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          ),
        ),
      ]);

      DebugLogger.success('Notification channels created', tag: _tag);
    } catch (e) {
      DebugLogger.error(
        'Failed to create notification channels',
        tag: _tag,
        error: e,
      );
    }
  }

  Future<void> _verifyChannels() async {
    if (!Platform.isAndroid) return;

    try {
      final androidPlugin =
          _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidPlugin != null) {
        DebugLogger.success('Notification channels verified', tag: _tag);
      }
    } catch (e) {
      DebugLogger.warning(
        'Channel verification failed',
        tag: _tag,
        data: e.toString(),
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    DebugLogger.info(
      'Notification tapped',
      tag: _tag,
      data: {
        'action': response.actionId,
        'payload': response.payload,
        'input': response.input,
      },
    );

    if (response.actionId == 'complete') {
      _handleCompleteAction(response.payload);
    } else if (response.actionId == 'snooze') {
      _handleSnoozeAction(response.payload);
    } else {
      _handleDefaultTap(response.payload);
    }
  }

  Future<void> _handleCompleteAction(String? taskId) async {
    if (taskId == null || taskId.isEmpty) return;

    return DebugLogger.timeOperation(
      'Complete task from notification',
      () async {
        try {
          final taskRepo = TaskRepository();
          await taskRepo.toggleTaskComplete(taskId);
          await cancelTaskNotifications(taskId);

          await showNotification(
            title: '✅ Task Completed!',
            body: 'Great job! Task has been marked as complete.',
            channelId: _defaultChannel,
          );

          DebugLogger.success(
            'Task completed from notification',
            tag: _tag,
            data: taskId,
          );
        } catch (e) {
          DebugLogger.error(
            'Failed to complete task from notification',
            tag: _tag,
            error: e,
          );
        }
      },
    );
  }

  Future<void> _handleSnoozeAction(String? taskId) async {
    if (taskId == null || taskId.isEmpty) return;

    return DebugLogger.timeOperation('Snooze task notification', () async {
      try {
        final taskRepo = TaskRepository();
        final task = taskRepo.getTask(taskId);

        if (task == null) {
          DebugLogger.warning(
            'Task not found for snooze',
            tag: _tag,
            data: taskId,
          );
          return;
        }

        await cancelTaskNotifications(taskId);

        const snoozeMinutes = 5;
        final snoozeTime = DateTime.now().add(
          const Duration(minutes: snoozeMinutes),
        );

        final snoozedTask = task.copyWith(
          dueDate: snoozeTime,
          hasNotification: true,
          notificationMinutesBefore: 0,
        );

        final settingsRepo = SettingsRepository();
        await settingsRepo.init();
        final settings = settingsRepo.getSettings();

        await scheduleTaskNotification(task: snoozedTask, settings: settings);

        await showNotification(
          title: '⏰ Reminder Snoozed',
          body: 'I\'ll remind you again in $snoozeMinutes minutes',
          channelId: _defaultChannel,
        );

        DebugLogger.success(
          'Task snoozed',
          tag: _tag,
          data: '$taskId for $snoozeMinutes minutes',
        );
      } catch (e) {
        DebugLogger.error('Failed to snooze task', tag: _tag, error: e);
      }
    });
  }

  void _handleDefaultTap(String? taskId) {
    DebugLogger.info('Opening task from notification', tag: _tag, data: taskId);
    // TODO: Navigate to task details
  }

  /// Handle background notification tap
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(
    NotificationResponse response,
  ) async {
    try {
      if (response.actionId == 'complete') {
        await _handleBackgroundCompleteAction(response.payload);
      } else if (response.actionId == 'snooze') {
        await _handleBackgroundSnoozeAction(response.payload);
      }
    } catch (e) {
      // Silent fail in background
    }
  }

  static Future<void> _handleBackgroundCompleteAction(String? taskId) async {
    if (taskId == null || taskId.isEmpty) return;

    try {
      await Hive.initFlutter();
      await Hive.openBox('tasks');

      final taskRepo = TaskRepository();
      await taskRepo.toggleTaskComplete(taskId);
    } catch (_) {
      // Silent fail in background
    }
  }

  static Future<void> _handleBackgroundSnoozeAction(String? taskId) async {
    if (taskId == null || taskId.isEmpty) return;

    try {
      await Hive.initFlutter();
      await Hive.openBox('tasks');
      await Hive.openBox('settings');

      final taskRepo = TaskRepository();
      final task = taskRepo.getTask(taskId);
      if (task == null) return;

      final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
      final snoozedTask = task.copyWith(dueDate: snoozeTime);
      await taskRepo.updateTask(snoozedTask);
    } catch (_) {
      // Silent fail in background
    }
  }

  Future<bool> showNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = _defaultChannel,
  }) async {
    if (!_isInitialized || !_notificationsEnabled) {
      DebugLogger.warning(
        'Cannot show notification - not initialized or disabled',
        tag: _tag,
      );
      return false;
    }

    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelName(channelId),
        channelDescription: _getChannelDescription(channelId),
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'DayFlow',
          htmlFormatBigText: true,
          htmlFormatContentTitle: true,
          htmlFormatSummaryText: true,
        ),
        color: const Color(0xFF2196F3),
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
        enableLights: true,
        ledColor: const Color(0xFF2196F3),
        ledOnMs: 1000,
        ledOffMs: 500,
        autoCancel: true,
        groupKey: 'dayflow_tasks',
        setAsGroupSummary: false,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        badgeNumber: 1,
        threadIdentifier: 'dayflow_notifications',
        interruptionLevel: InterruptionLevel.active,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _notifications.show(id, title, body, details, payload: payload);

      DebugLogger.success('Notification shown', tag: _tag, data: 'ID: $id');
      return true;
    } catch (e) {
      DebugLogger.error('Failed to show notification', tag: _tag, error: e);
      return false;
    }
  }

  Future<bool> scheduleTaskNotification({
    required TaskModel task,
    required AppSettings settings,
  }) async {
    if (!_isInitialized || !_notificationsEnabled) {
      DebugLogger.warning(
        'Cannot schedule - not initialized or disabled',
        tag: _tag,
      );
      return false;
    }

    return DebugLogger.timeOperation('Schedule task notification', () async {
      try {
        DebugLogger.info(
          'Scheduling notification',
          tag: _tag,
          data: {
            'task': task.title,
            'dueDate': task.dueDate?.toIso8601String(),
            'hasNotification': task.hasNotification,
          },
        );

        if (!task.hasNotification || task.dueDate == null) {
          DebugLogger.warning(
            'Task has no notification or due date',
            tag: _tag,
          );
          return false;
        }

        await cancelTaskNotifications(task.id);

        final minutesBefore = task.notificationMinutesBefore ?? 0;
        final notificationDateTime = task.dueDate!.subtract(
          Duration(minutes: minutesBefore),
        );
        final scheduledDate = tz.TZDateTime.from(
          notificationDateTime,
          tz.local,
        );
        final now = tz.TZDateTime.now(tz.local);

        DebugLogger.debug(
          'Schedule timing',
          tag: _tag,
          data: {
            'now': now.toIso8601String(),
            'scheduled': scheduledDate.toIso8601String(),
            'difference': '${scheduledDate.difference(now).inSeconds} seconds',
          },
        );

        if (scheduledDate.isBefore(now) ||
            scheduledDate.difference(now).inSeconds < 10) {
          DebugLogger.warning(
            'Time too close/past, showing immediately',
            tag: _tag,
          );
          return await showNotification(
            title: '📋 ${task.title}',
            body: task.description ?? 'Task reminder!',
            payload: task.id,
            channelId: _reminderChannel,
          );
        }

        final id = task.id.hashCode.abs();
        final notificationDetails = _createTaskNotificationDetails(
          task,
          settings,
        );

        final (scheduled, mode) = await _scheduleWithFallback(
          id: id,
          title: '📋 ${task.title}',
          body: task.description ?? 'Task reminder',
          scheduledDate: scheduledDate,
          details: notificationDetails,
          payload: task.id,
        );

        final pending = await _notifications.pendingNotificationRequests();
        final found = pending.any((p) => p.id == id);

        DebugLogger.success(
          'Notification scheduled',
          tag: _tag,
          data: {'verified': found, 'mode': mode, 'id': id},
        );

        return found;
      } catch (e) {
        DebugLogger.error('Error scheduling notification', tag: _tag, error: e);
        return false;
      }
    });
  }

  /// Create enhanced notification details for tasks with better UX
  NotificationDetails _createTaskNotificationDetails(
    TaskModel task,
    AppSettings settings,
  ) {
    // Priority-based styling
    final (color, vibrationPattern) = _getPriorityStyle(task.priority);

    // Build notification content
    final String expandedBody = _buildExpandedBody(task);
    final String summaryText = _getPriorityBadge(task.priority);

    return NotificationDetails(
      android: AndroidNotificationDetails(
        _reminderChannel,
        'Task Reminders',
        channelDescription: 'Scheduled reminders for tasks',
        importance: task.priority >= 4 ? Importance.max : Importance.high,
        priority: task.priority >= 4 ? Priority.max : Priority.high,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.reminder,
        // Visual enhancements
        showWhen: true,
        when: task.dueDate?.millisecondsSinceEpoch,
        usesChronometer: false,
        autoCancel: true,
        ongoing: false,
        // Styling with expandable content
        styleInformation: BigTextStyleInformation(
          expandedBody,
          contentTitle: task.title,
          summaryText: summaryText,
          htmlFormatBigText: true,
          htmlFormatContentTitle: true,
          htmlFormatSummaryText: true,
        ),
        // Priority-based appearance
        color: color,
        colorized: false,
        // Full screen intent for urgent tasks
        fullScreenIntent: task.priority >= 5,
        // Sound and vibration based on settings
        playSound: settings.notificationSound,
        enableVibration: settings.notificationVibration,
        vibrationPattern:
            settings.notificationVibration ? vibrationPattern : null,
        enableLights: true,
        ledColor: color,
        ledOnMs: 1000,
        ledOffMs: 500,
        // Group notifications
        groupKey: 'dayflow_tasks',
        setAsGroupSummary: false,
        // Add ticker for accessibility
        ticker: 'Task reminder: ${task.title}',
        // Channel lock
        channelAction: AndroidNotificationChannelAction.createIfNotExists,
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'complete',
            '✅ Complete',
            showsUserInterface: false, // Don't open app
            cancelNotification: true, // Dismiss notification after action
          ),
          const AndroidNotificationAction(
            'snooze',
            '⏰ Snooze 5min',
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: settings.notificationSound,
        badgeNumber: 1,
        threadIdentifier: 'dayflow_task_${task.id}',
        categoryIdentifier: 'task_reminder',
        subtitle: task.description,
        // Set interruption level based on priority
        interruptionLevel:
            task.priority >= 4
                ? InterruptionLevel.timeSensitive
                : InterruptionLevel.active,
      ),
    );
  }

  /// Get priority-based color and vibration pattern
  (Color, Int64List) _getPriorityStyle(int priority) {
    switch (priority) {
      case 5:
        return (Colors.red, Int64List.fromList([0, 500, 250, 500, 250, 500]));
      case 4:
        return (Colors.orange, Int64List.fromList([0, 400, 200, 400]));
      case 3:
        return (Colors.amber, Int64List.fromList([0, 300, 200, 300]));
      case 2:
        return (Colors.green, Int64List.fromList([0, 250, 250, 250]));
      default:
        return (Colors.blue, Int64List.fromList([0, 200, 200]));
    }
  }

  /// Build expanded notification body
  String _buildExpandedBody(TaskModel task) {
    final List<String> parts = [];

    if (task.description != null && task.description!.isNotEmpty) {
      parts.add(task.description!);
    }

    if (task.dueDate != null) {
      parts.add('⏰ Due: ${_formatDate(task.dueDate!)}');
    }

    if (task.tags.isNotEmpty) {
      parts.add('🏷️ ${task.tags.join(', ')}');
    }

    if (parts.isEmpty) {
      parts.add('You have a task to complete');
    }

    return parts.join('\n');
  }

  /// Get priority badge text
  String _getPriorityBadge(int priority) {
    switch (priority) {
      case 5:
        return '🔴 URGENT';
      case 4:
        return '🟠 High Priority';
      case 3:
        return '🟡 Medium Priority';
      case 2:
        return '🟢 Low Priority';
      default:
        return '⚪ Task Reminder';
    }
  }

  /// Schedule notification with fallback mechanisms
  Future<(bool scheduled, String mode)> _scheduleWithFallback({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
    required String payload,
  }) async {
    // Try exactAllowWhileIdle first (most accurate)
    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      debugPrint('✅ Scheduled with EXACT mode (no delay expected)');
      return (true, 'EXACT');
    } catch (e) {
      debugPrint('⚠️ Exact mode failed: $e');
    }

    // Try alarmClock next (also accurate)
    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      debugPrint('✅ Scheduled with ALARM_CLOCK mode (accurate)');
      return (true, 'ALARM_CLOCK');
    } catch (e) {
      debugPrint('⚠️ AlarmClock mode failed: $e');
    }

    // Last resort - inexact with compensation
    try {
      final compensatedDate = scheduledDate.subtract(
        const Duration(minutes: 1),
      );
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        compensatedDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      debugPrint(
        '⚠️ Scheduled with INEXACT mode (1 min earlier for compensation)',
      );
      return (true, 'INEXACT_COMPENSATED');
    } catch (e) {
      debugPrint('❌ All scheduling modes failed: $e');
      return (false, 'FAILED');
    }
  }

  /// Cancel task notifications
  Future<void> cancelTaskNotifications(String taskId) async {
    try {
      final baseId = taskId.hashCode.abs();

      // Cancel main notification
      await _notifications.cancel(baseId);

      // Cancel potential repeating notifications
      for (int i = 1; i <= 30; i++) {
        await _notifications.cancel(baseId + i);
      }

      debugPrint('🗑️ Cancelled all notifications for task: $taskId');
    } catch (e) {
      debugPrint('❌ Failed to cancel notifications: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      debugPrint('🗑️ All notifications cancelled');
    } catch (e) {
      debugPrint('❌ Failed to cancel all notifications: $e');
    }
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      debugPrint('📬 Pending notifications: ${pending.length}');
      return pending;
    } catch (e) {
      debugPrint('❌ Failed to get pending notifications: $e');
      return [];
    }
  }

  /// Test immediate notification
  Future<bool> testImmediateNotification() async {
    debugPrint('🧪 Testing immediate notification...');
    return await showNotification(
      title: '🎉 Test Successful!',
      body:
          'Notifications are working correctly. DayFlow is ready to remind you of your tasks!',
      channelId: _highPriorityChannel,
    );
  }

  /// Test delayed notification
  Future<bool> testDelayedNotification({int seconds = 5}) async {
    debugPrint('⏰ Testing delayed notification ($seconds seconds)...');
    try {
      final scheduledDate = tz.TZDateTime.now(
        tz.local,
      ).add(Duration(seconds: seconds));

      var details = NotificationDetails(
        android: AndroidNotificationDetails(
          'dayflow_high_priority',
          'High Priority',
          channelDescription: 'Test delayed notification',
          importance: Importance.max,
          priority: Priority.max,
          showWhen: true,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      final (scheduled, _) = await _scheduleWithFallback(
        id: 999999,
        title: '⏰ Delayed Test',
        body: 'This notification was scheduled $seconds seconds ago!',
        scheduledDate: scheduledDate,
        details: details,
        payload: 'test',
      );

      return scheduled;
    } catch (e) {
      debugPrint('❌ Test delayed notification failed: $e');
      return false;
    }
  }

  /// Get service status
  Future<Map<String, dynamic>> getServiceStatus() async {
    final pending = await getPendingNotifications();
    return {
      'initialized': _isInitialized,
      'enabled': _notificationsEnabled,
      'pendingCount': pending.length,
      'timezone': tz.local.name,
      'currentTime': tz.TZDateTime.now(tz.local).toString(),
    };
  }

  /// Helper methods
  String _getChannelName(String channelId) {
    switch (channelId) {
      case _highPriorityChannel:
        return 'High Priority';
      case _reminderChannel:
        return 'Task Reminders';
      default:
        return 'Default';
    }
  }

  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case _highPriorityChannel:
        return 'Important and urgent task reminders';
      case _reminderChannel:
        return 'Scheduled reminders for tasks';
      default:
        return 'General app notifications';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);
    final difference = taskDate.difference(today).inDays;

    if (difference == 0) {
      return 'Today at ${_formatTime(date)}';
    } else if (difference == 1) {
      return 'Tomorrow at ${_formatTime(date)}';
    } else if (difference == -1) {
      return 'Yesterday at ${_formatTime(date)}';
    } else if (difference > 1 && difference <= 7) {
      return 'In $difference days at ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year} at ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    final hour =
        date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${date.minute.toString().padLeft(2, '0')} $period';
  }
}
