import 'dart:io';
import 'dart:typed_data';
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

  Future<void> _initializeTimezone() async {
    try {
      // Load timezone data with explicit path
      tz.initializeTimeZones();

      try {
        String timeZoneName;

        // Try multiple approaches to get timezone
        try {
          timeZoneName = await FlutterTimezone.getLocalTimezone();
        } catch (_) {
          // Fallback to DateTime's timezone
          timeZoneName = DateTime.now().timeZoneName;
        }

        // Validate timezone
        try {
          final location = tz.getLocation(timeZoneName);
          tz.setLocalLocation(location);
          debugPrint('✅ Timezone set to: $timeZoneName');
        } catch (_) {
          // If invalid, try common formats
          final fixedName = _fixTimezoneName(timeZoneName);
          try {
            final location = tz.getLocation(fixedName);
            tz.setLocalLocation(location);
            debugPrint('✅ Timezone set to: $fixedName (corrected)');
          } catch (_) {
            // Ultimate fallback
            tz.setLocalLocation(tz.UTC);
            debugPrint('⚠️ Using UTC as timezone');
          }
        }
      } catch (e) {
        tz.setLocalLocation(tz.UTC);
        debugPrint('⚠️ Timezone error, using UTC: $e');
      }
    } catch (e) {
      tz.setLocalLocation(tz.UTC);
      debugPrint('❌ Timezone initialization failed, using UTC: $e');
    }
  }

  // Helper to fix common timezone name issues
  String _fixTimezoneName(String original) {
    // Handle Android timezone names that need conversion
    if (original.startsWith('GMT')) {
      return original.replaceFirst('GMT', 'Etc/GMT');
    }
    return original;
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

    // iOS settings with action categories
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
              options: {
                DarwinNotificationActionOption.destructive, // Red color
              },
            ),
            DarwinNotificationAction.plain(
              'snooze',
              'Snooze 5min',
              options: {
                DarwinNotificationActionOption.foreground, // Blue color
              },
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

    // Handle different actions
    if (response.actionId == 'complete') {
      _handleCompleteAction(response.payload);
    } else if (response.actionId == 'snooze') {
      _handleSnoozeAction(response.payload);
    } else {
      // Regular tap - open app or navigate to task
      _handleDefaultTap(response.payload);
    }
  }

  /// Handle complete action
  Future<void> _handleCompleteAction(String? taskId) async {
    if (taskId == null || taskId.isEmpty) return;

    debugPrint('✅ Marking task as complete: $taskId');

    try {
      // Import TaskRepository
      final taskRepo = TaskRepository();

      // Toggle task completion
      await taskRepo.toggleTaskComplete(taskId);

      // Cancel future notifications for this task
      await cancelTaskNotifications(taskId);

      // Show success notification
      await showNotification(
        title: '✅ Task Completed!',
        body: 'Great job! Task has been marked as complete.',
        channelId: _defaultChannel,
      );

      debugPrint('✅ Task marked as complete successfully');
    } catch (e) {
      debugPrint('❌ Failed to complete task: $e');
    }
  }

  /// Handle snooze action
  Future<void> _handleSnoozeAction(String? taskId) async {
    if (taskId == null || taskId.isEmpty) return;

    debugPrint('⏰ Snoozing task: $taskId');

    try {
      // Get task from repository
      final taskRepo = TaskRepository();
      final task = taskRepo.getTask(taskId);

      if (task == null) {
        debugPrint('❌ Task not found');
        return;
      }

      // Cancel current notification
      await cancelTaskNotifications(taskId);

      // Snooze duration (5 minutes default, can be customizable)
      const snoozeMinutes = 5;
      final snoozeTime = DateTime.now().add(
        const Duration(minutes: snoozeMinutes),
      );

      // Create snoozed task with new time
      final snoozedTask = task.copyWith(
        dueDate: snoozeTime,
        hasNotification: true,
        notificationMinutesBefore: 0, // At exact time
      );

      // Get settings
      final settingsRepo = SettingsRepository();
      await settingsRepo.init();
      final settings = settingsRepo.getSettings();

      // Schedule new notification
      await scheduleTaskNotification(task: snoozedTask, settings: settings);

      // Show confirmation
      await showNotification(
        title: '⏰ Reminder Snoozed',
        body: 'I\'ll remind you again in $snoozeMinutes minutes',
        channelId: _defaultChannel,
      );

      debugPrint('✅ Task snoozed for $snoozeMinutes minutes');
    } catch (e) {
      debugPrint('❌ Failed to snooze task: $e');
    }
  }

  /// Handle default tap (open app)
  void _handleDefaultTap(String? taskId) {
    debugPrint('📱 Opening task: $taskId');
    // TODO: Navigate to task details
    // This needs to be connected with your navigation system
  }

  /// Handle background notification tap
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(
    NotificationResponse response,
  ) async {
    try {
      // Remove debug prints in release for background handlers
      if (response.actionId == 'complete') {
        // Use a simpler approach without full app initialization
        await _handleBackgroundCompleteAction(response.payload);
      } else if (response.actionId == 'snooze') {
        await _handleBackgroundSnoozeAction(response.payload);
      }
    } catch (e, stackTrace) {
      // Log errors without crashing
      debugPrint('❌ Background notification error: $e');
      debugPrint(stackTrace.toString());
    }
  }

  // Simplified background handlers that don't require full initialization
  static Future<void> _handleBackgroundCompleteAction(String? taskId) async {
    if (taskId == null || taskId.isEmpty) return;

    try {
      // Minimal initialization
      await Hive.initFlutter();
      await Hive.openBox('tasks');

      final taskRepo = TaskRepository();
      await taskRepo.toggleTaskComplete(taskId);
    } catch (e) {
      debugPrint('❌ Background complete action failed: $e');
    }
  }

  static Future<void> _handleBackgroundSnoozeAction(String? taskId) async {
    if (taskId == null || taskId.isEmpty) return;

    try {
      // Minimal initialization
      await Hive.initFlutter();
      await Hive.openBox('tasks');
      await Hive.openBox('settings');

      final taskRepo = TaskRepository();
      final task = taskRepo.getTask(taskId);
      if (task == null) return;

      // Simple snooze logic without full notification rescheduling
      final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
      final snoozedTask = task.copyWith(dueDate: snoozeTime);
      await taskRepo.updateTask(snoozedTask);
    } catch (e) {
      debugPrint('❌ Background snooze action failed: $e');
    }
  }

  /// Show immediate notification with improved UI
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
      // Enhanced Android notification with system defaults
      final androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelName(channelId),
        channelDescription: _getChannelDescription(channelId),
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        // Enhanced UI with expandable content
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'DayFlow',
          htmlFormatBigText: true,
          htmlFormatContentTitle: true,
          htmlFormatSummaryText: true,
        ),
        // Visual enhancements using system colors
        color: const Color(0xFF2196F3),
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        // Use system default sound and vibration
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

      // iOS notification details
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
      final notificationDetails = _createTaskNotificationDetails(
        task,
        settings,
      );

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
