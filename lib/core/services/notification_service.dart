import 'dart:io';
import 'dart:typed_data';
import 'package:dayflow/data/models/app_settings.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';

/// Notification Service for managing all notification operations
class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Plugin instance
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // State flags
  bool _isInitialized = false;
  bool _notificationsEnabled = true;

  // Channel IDs
  static const String _highPriorityChannel = 'dayflow_high_priority';
  static const String _defaultChannel = 'dayflow_default';
  static const String _reminderChannel = 'dayflow_reminders';

  // Getters
  bool get isInitialized => _isInitialized;
  bool get notificationsEnabled => _notificationsEnabled;

  /// Initialize notification service
  Future<bool> initialize() async {
    if (_isInitialized) {
      debugPrint('⚠️ NotificationService already initialized');
      return true;
    }

    try {
      debugPrint('🔧 Initializing NotificationService...');

      // Initialize timezone
      await _initializeTimezone();

      // Check permissions
      _notificationsEnabled = await _checkAndRequestPermissions();
      if (!_notificationsEnabled) {
        debugPrint('❌ Notification permissions not granted');
      }

      // Initialize plugin
      await _initializePlugin();

      // Create notification channels for Android
      if (Platform.isAndroid) {
        await _createNotificationChannels();
      }

      _isInitialized = true;
      debugPrint('✅ NotificationService initialized successfully');

      // Test notification channels
      await _verifyChannels();

      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to initialize NotificationService: $e');
      debugPrint('Stack trace: $stackTrace');
      _isInitialized = false;
      return false;
    }
  }

  /// Initialize timezone settings
  Future<void> _initializeTimezone() async {
    try {
      tz.initializeTimeZones();

      // Get device timezone or fallback to UTC
      final timeZoneName = await _getDeviceTimezone() ?? 'UTC';

      // Validate and set timezone
      try {
        final location = tz.getLocation(timeZoneName);
        tz.setLocalLocation(location);
        debugPrint('✅ Timezone set to: $timeZoneName');
        debugPrint('🕐 Current time: ${tz.TZDateTime.now(tz.local)}');
      } catch (e) {
        debugPrint('❌ Invalid timezone: $timeZoneName, using UTC');
        tz.setLocalLocation(tz.UTC);
      }
    } catch (e) {
      debugPrint('❌ Timezone initialization failed: $e');
      tz.setLocalLocation(tz.UTC);
    }
  }

  /// Get device timezone with fallback
  Future<String?> _getDeviceTimezone() async {
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      debugPrint('🌍 Device timezone: $timeZoneName');
      return timeZoneName;
    } catch (e) {
      debugPrint('⚠️ Failed to get device timezone: $e');
      return null;
    }
  }

  /// Check and request permissions
  Future<bool> _checkAndRequestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final sdkInt = await _getAndroidSdkInt();

        // Handle notification permission for Android 13+
        if (sdkInt >= 33) {
          final status = await Permission.notification.status;
          if (!status.isGranted) {
            if (status.isPermanentlyDenied) {
              debugPrint('❌ Notification permission permanently denied');
              return false;
            }
            final result = await Permission.notification.request();
            if (!result.isGranted) {
              debugPrint('❌ Notification permission denied');
              return false;
            }
          }
        }

        // Handle exact alarm permission for Android 12+
        if (sdkInt >= 31) {
          await _requestExactAlarmPermission();
        }
      }

      // iOS permissions are handled in initialization settings
      return true;
    } catch (e) {
      debugPrint('❌ Permission check failed: $e');
      return false;
    }
  }

  /// Request exact alarm permission for Android 12+
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
          debugPrint('⚠️ Exact alarm permission not granted');
          final granted = await androidPlugin.requestExactAlarmsPermission();
          if (!granted!) {
            debugPrint(
              '⚠️ Exact alarm permission denied, notifications may be delayed',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to request exact alarm permission: $e');
    }
  }

  /// Get Android SDK version
  Future<int> _getAndroidSdkInt() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt;
    } catch (e) {
      debugPrint('❌ Failed to get Android SDK version: $e');
      return 29; // Default to Android 10
    }
  }

  /// Initialize plugin
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
              'Mark as Complete',
              options: {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain('snooze', 'Snooze'),
          ],
        ),
      ],
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationTapped,
    );
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    final androidPlugin =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin == null) return;

    try {
      // Create all notification channels
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

      debugPrint('✅ Notification channels created');
    } catch (e) {
      debugPrint('❌ Failed to create notification channels: $e');
    }
  }

  /// Verify channels
  Future<void> _verifyChannels() async {
    if (!Platform.isAndroid) return;

    try {
      final androidPlugin =
          _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidPlugin != null) {
        debugPrint('📱 Notification channels ready');
      }
    } catch (e) {
      debugPrint('⚠️ Channel verification failed: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('👆 Notification tapped:');
    debugPrint('  - Action: ${response.actionId}');
    debugPrint('  - Payload: ${response.payload}');
    debugPrint('  - Input: ${response.input}');
    // TODO: Navigate to task details using payload (task ID)
  }

  /// Handle background notification tap
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    debugPrint('👆 Background notification tapped: ${response.payload}');
  }

  /// Show immediate notification
  Future<bool> showNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = _defaultChannel,
  }) async {
    if (!_isInitialized || !_notificationsEnabled) {
      debugPrint('⚠️ Notifications not initialized or disabled');
      return false;
    }

    try {
      // Enhanced Android notification details with better styling
      final androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelName(channelId),
        channelDescription: _getChannelDescription(channelId),
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        // Enhanced UI with big text style
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'DayFlow',
          htmlFormatBigText: true,
          htmlFormatContentTitle: true,
          htmlFormatSummaryText: true,
        ),
        // Enhanced visual elements
        color: Colors.blue.shade500,
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        subText: 'Task Reminder',
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        // Better sound and vibration patterns
        sound: const RawResourceAndroidNotificationSound('notification_sound'),
        vibrationPattern: Int64List.fromList([
          0,
          500,
          200,
          500,
        ]), // Fixed: converted to Int64List
        enableLights: true,
        ledColor: Colors.blue,
        ledOnMs: 1000,
        ledOffMs: 500,
      );

      // Enhanced iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'task_reminder',
        // Attachments for better UI
        attachments: <DarwinNotificationAttachment>[
          DarwinNotificationAttachment(
            'notification_icon',
            identifier: 'icon',
            hideThumbnail: false,
          ),
        ],
        // Better sound
        sound: 'notification_sound.wav',
        threadIdentifier: 'dayflow_notifications',
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _notifications.show(id, title, body, details, payload: payload);
      debugPrint('✅ Notification shown with ID: $id');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to show notification: $e');
      return false;
    }
  }

  /// Schedule notification for task
  Future<bool> scheduleTaskNotification({
    required TaskModel task,
    required AppSettings settings,
  }) async {
    if (!_isInitialized || !_notificationsEnabled) {
      debugPrint('⚠️ Notifications not initialized or disabled');
      return false;
    }

    debugPrint('\n📅 === SCHEDULING TASK NOTIFICATION ===');
    debugPrint('📋 Task: ${task.title}');
    debugPrint('📅 Due date: ${task.dueDate}');

    try {
      if (!task.hasNotification || task.dueDate == null) {
        debugPrint('❌ Task has no notification or due date');
        return false;
      }

      // Cancel any existing notifications for this task
      await cancelTaskNotifications(task.id);

      // Calculate notification time
      final minutesBefore = task.notificationMinutesBefore ?? 0;
      final notificationDateTime = task.dueDate!.subtract(
        Duration(minutes: minutesBefore),
      );

      // Use device's local timezone for scheduling
      final scheduledDate = tz.TZDateTime.from(notificationDateTime, tz.local);
      final now = tz.TZDateTime.now(tz.local);

      debugPrint('🕐 Current: $now');
      debugPrint('🔔 Schedule for: $scheduledDate');
      debugPrint(
        '⏱️ Time difference: ${scheduledDate.difference(now).inSeconds} seconds',
      );

      // Check if scheduled time is in the past or too close
      if (scheduledDate.isBefore(now) ||
          scheduledDate.difference(now).inSeconds < 10) {
        debugPrint('⚠️ Time too close/past, showing immediately');
        return await showNotification(
          title: '📋 ${task.title}',
          body: task.description ?? 'Task reminder!',
          payload: task.id,
          channelId: _reminderChannel,
        );
      }

      // Generate unique ID and create notification details
      final id = task.id.hashCode.abs();
      final notificationDetails = _createTaskNotificationDetails(task);

      // Schedule notification with fallback mechanisms
      final (scheduled, mode) = await _scheduleWithFallback(
        id: id,
        title: '📋 ${task.title}',
        body: task.description ?? 'Task reminder',
        scheduledDate: scheduledDate,
        details: notificationDetails,
        payload: task.id,
      );

      // Verify the notification was scheduled
      final pending = await _notifications.pendingNotificationRequests();
      final found = pending.any((p) => p.id == id);

      debugPrint('📬 Verification: ${found ? "✅ Found" : "❌ Not found"}');
      debugPrint('📱 Mode used: $mode');

      return found;
    } catch (e) {
      debugPrint('❌ Error scheduling notification: $e');
      return false;
    }
  }

  /// Create notification details for task
  NotificationDetails _createTaskNotificationDetails(TaskModel task) {
    // Create priority-based color
    Color priorityColor = Colors.blue;
    if (task.priority >= 4) {
      priorityColor = Colors.red;
    } else if (task.priority == 3) {
      priorityColor = Colors.orange;
    } else if (task.priority <= 2) {
      priorityColor = Colors.green;
    }

    // Create priority-based sound
    String sound = 'notification_sound';
    if (task.priority >= 4) {
      sound = 'urgent_notification';
    }

    return NotificationDetails(
      android: AndroidNotificationDetails(
        _reminderChannel,
        'Task Reminders',
        channelDescription: 'Scheduled reminders for tasks',
        importance: Importance.max,
        priority: Priority.max,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.reminder,
        enableLights: true,
        enableVibration: true,
        playSound: true,
        showWhen: true,
        autoCancel: true,
        fullScreenIntent: task.priority >= 4, // Full screen for high priority
        // Enhanced UI with big text style
        styleInformation: BigTextStyleInformation(
          task.description ?? 'Task reminder',
          contentTitle: '📋 ${task.title}',
          summaryText: 'Priority: ${_getPriorityText(task.priority)}',
          htmlFormatBigText: true,
          htmlFormatContentTitle: true,
          htmlFormatSummaryText: true,
        ),
        // Visual enhancements
        color: priorityColor,
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        subText:
            'Due: ${task.dueDate != null ? _formatDate(task.dueDate!) : 'No due date'}',
        // Sound and vibration based on priority
        sound: RawResourceAndroidNotificationSound(sound),
        vibrationPattern:
            task.priority >= 4
                ? Int64List.fromList([
                  0,
                  1000,
                  500,
                  1000,
                ]) // Fixed: converted to Int64List
                : Int64List.fromList([
                  0,
                  500,
                  200,
                  500,
                ]), // Fixed: converted to Int64List
        ledColor: priorityColor,
        ledOnMs: 1000,
        ledOffMs: 500,
        // Add actions for task notifications
        actions: [
          const AndroidNotificationAction(
            'complete',
            'Mark Complete',
            icon: DrawableResourceAndroidBitmap('ic_complete'),
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'snooze',
            'Snooze',
            icon: DrawableResourceAndroidBitmap('ic_snooze'),
            showsUserInterface: true,
          ),
        ],
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'task_reminder',
        // Attachments for better UI
        attachments: <DarwinNotificationAttachment>[
          const DarwinNotificationAttachment(
            'notification_icon',
            identifier: 'icon',
            hideThumbnail: false,
          ),
        ],
        // Sound based on priority
        sound: '$sound.wav',
        threadIdentifier: 'dayflow_task_${task.id}',
      ),
    );
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
      final baseId = taskId.hashCode;

      // Cancel main notification
      await _notifications.cancel(baseId);

      // Cancel repeating notifications
      await Future.wait([
        for (int i = 1; i <= 100; i++) _notifications.cancel(baseId + i),
        for (int i = 1; i <= 100; i++)
          _notifications.cancel(baseId + (i * 100)), // For monthly
      ]);

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
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _highPriorityChannel,
          'High Priority',
          channelDescription: 'Test delayed notification',
          importance: Importance.max,
          priority: Priority.max,
          showWhen: true,
          when: scheduledDate.millisecondsSinceEpoch,
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
    final difference = date.difference(now);

    if (difference.inDays == 0) {
      return 'Today at ${_formatTime(date)}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow at ${_formatTime(date)}';
    } else if (difference.inDays == -1) {
      return 'Yesterday at ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year} at ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${date.minute.toString().padLeft(2, '0')} $period';
  }

  String _getPriorityText(int priority) {
    switch (priority) {
      case 5:
        return '🔴 Very High Priority';
      case 4:
        return '🟠 High Priority';
      case 3:
        return '🟡 Medium Priority';
      case 2:
        return '🟢 Low Priority';
      default:
        return '⚪ Very Low Priority';
    }
  }
}
