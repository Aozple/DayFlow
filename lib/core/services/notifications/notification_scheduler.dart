import 'dart:convert';
import 'dart:ui';
import 'package:dayflow/core/constants/notification_constants.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:dayflow/data/models/habit_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationScheduler {
  static const String _tag = 'NotificationScheduler';
  static const int _taskIdBase = 100000;
  static const int _habitIdBase = 200000;
  static const int _idRange = 100000;

  final FlutterLocalNotificationsPlugin _plugin;

  NotificationScheduler(this._plugin);

  // MARK: - Scheduling Methods

  /// Schedules a notification for a given task.
  Future<bool> scheduleTaskNotification(TaskModel task) async {
    if (!_isTaskEligible(task)) return false;

    try {
      final notificationTime = _calculateTaskNotificationTime(task);
      if (notificationTime == null || _isTimeInPast(notificationTime)) {
        return false;
      }

      final payload = _createTaskPayload(task);
      final details = _createTaskNotificationDetails(task);
      final notificationId = _generateId(task.id, _taskIdBase);

      await _plugin.zonedSchedule(
        notificationId,
        _getTaskTitle(task),
        _getTaskBody(task),
        tz.TZDateTime.from(notificationTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      DebugLogger.success(
        'Task notification scheduled',
        tag: _tag,
        data: task.id,
      );
      return true;
    } catch (e) {
      DebugLogger.error(
        'Failed to schedule task notification',
        tag: _tag,
        error: e,
      );
      return false;
    }
  }

  /// Schedules a notification for a given habit.
  Future<bool> scheduleHabitNotification(
    HabitModel habit, {
    DateTime? specificDate,
  }) async {
    if (!_isHabitEligible(habit)) return false;

    try {
      final notificationTime = _calculateHabitNotificationTime(
        habit,
        specificDate,
      );
      if (notificationTime == null) return false;

      final payload = _createHabitPayload(habit);
      final details = _createHabitNotificationDetails(habit);
      final notificationId = _generateId(habit.id, _habitIdBase);

      await _plugin.zonedSchedule(
        notificationId,
        _getHabitTitle(habit),
        _getHabitBody(habit),
        tz.TZDateTime.from(notificationTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      DebugLogger.success(
        'Habit notification scheduled',
        tag: _tag,
        data: habit.id,
      );
      return true;
    } catch (e) {
      DebugLogger.error(
        'Failed to schedule habit notification',
        tag: _tag,
        error: e,
      );
      return false;
    }
  }

  /// Cancels a scheduled notification.
  Future<void> cancelNotification(String entityId, String type) async {
    final baseId = type == NotificationTypes.habit ? _habitIdBase : _taskIdBase;
    final notificationId = _generateId(entityId, baseId);
    await _plugin.cancel(notificationId);
    DebugLogger.info('Notification cancelled', tag: _tag, data: entityId);
  }

  // MARK: - Content Generation

  /// Generates the title for a task notification.
  String _getTaskTitle(TaskModel task) {
    final priorityEmoji = _getPriorityEmoji(task.priority);
    final timeInfo = _getTimeInfo(task.dueDate);
    return '$priorityEmoji ${task.title} $timeInfo';
  }

  /// Generates the body for a task notification.
  String _getTaskBody(TaskModel task) {
    final parts = <String>[];

    if (task.description != null && task.description!.isNotEmpty) {
      parts.add(task.description!);
    }

    if (task.priority >= 4) {
      parts.add('🔥 High Priority Task');
    }

    if (task.tags.isNotEmpty) {
      parts.add('🏷️ ${task.tags.take(2).join(', ')}');
    }

    final estimatedTime = task.estimatedMinutes;
    if (estimatedTime != null) {
      final hours = estimatedTime ~/ 60;
      final minutes = estimatedTime % 60;
      final timeStr = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
      parts.add('⏱️ Est. $timeStr');
    }

    return parts.isNotEmpty
        ? parts.join(' • ')
        : 'Tap to view details and complete this task';
  }

  /// Generates the title for a habit notification.
  String _getHabitTitle(HabitModel habit) {
    final streakInfo =
        habit.currentStreak > 0 ? '🔥${habit.currentStreak}' : '🎯';
    return '$streakInfo ${habit.title}';
  }

  /// Generates the body for a habit notification.
  String _getHabitBody(HabitModel habit) {
    final parts = <String>[];

    if (habit.description != null && habit.description!.isNotEmpty) {
      parts.add(habit.description!);
    }

    if (habit.currentStreak > 0) {
      if (habit.currentStreak >= 30) {
        parts.add('🏆 Amazing ${habit.currentStreak}-day streak!');
      } else if (habit.currentStreak >= 7) {
        parts.add('💪 ${habit.currentStreak} days strong!');
      } else {
        parts.add('🔥 ${habit.currentStreak}-day streak');
      }
    } else {
      parts.add('💫 Start your streak today!');
    }

    parts.add('📅 ${habit.frequencyLabel}');

    if (habit.habitType == HabitType.quantifiable &&
        habit.targetValue != null &&
        habit.unit != null) {
      parts.add('🎯 ${habit.targetValue} ${habit.unit}');
    }

    return parts.join(' • ');
  }

  /// Returns an emoji based on task priority.
  String _getPriorityEmoji(int priority) {
    return switch (priority) {
      5 => '🚨',
      4 => '🔴',
      3 => '🟡',
      2 => '🟢',
      _ => '📋',
    };
  }

  /// Returns time information based on a due date.
  String _getTimeInfo(DateTime? dueDate) {
    if (dueDate == null) return '';

    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.inDays > 0) {
      return '📅 ${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '⏰ ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '⏱️ ${difference.inMinutes}m';
    } else {
      return '🔔 Now';
    }
  }

  // MARK: - Notification Details

  /// Creates notification details for a task.
  NotificationDetails _createTaskNotificationDetails(TaskModel task) {
    final channelId =
        task.priority >= 4
            ? NotificationChannels.taskHigh
            : NotificationChannels.taskDefault;
    final config = NotificationChannels.configs[channelId]!;

    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        config.name,
        channelDescription: config.description,
        importance: _mapImportance(config.importance),
        priority: _mapPriority(task.priority),
        category: AndroidNotificationCategory.reminder,
        enableVibration: true,
        enableLights: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(
          _getTaskBody(task),
          htmlFormatBigText: false,
          contentTitle: _getTaskTitle(task),
          htmlFormatContentTitle: false,
          summaryText: _getTaskSummary(task),
          htmlFormatSummaryText: false,
        ),
        color: _parseColor(task.color),
        ledColor: _parseColor(task.color),
        ledOnMs: 1000,
        ledOffMs: 500,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        subtitle: _getTaskSummary(task),
        threadIdentifier: 'task_${task.id}',
      ),
    );
  }

  /// Creates notification details for a habit.
  NotificationDetails _createHabitNotificationDetails(HabitModel habit) {
    final config =
        NotificationChannels.configs[NotificationChannels.habitReminder]!;

    return NotificationDetails(
      android: AndroidNotificationDetails(
        NotificationChannels.habitReminder,
        config.name,
        channelDescription: config.description,
        importance: _mapImportance(config.importance),
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        enableVibration: true,
        enableLights: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(
          _getHabitBody(habit),
          htmlFormatBigText: false,
          contentTitle: _getHabitTitle(habit),
          htmlFormatContentTitle: false,
          summaryText: _getHabitSummary(habit),
          htmlFormatSummaryText: false,
        ),
        color: _parseColor(habit.color),
        ledColor: _parseColor(habit.color),
        ledOnMs: 1000,
        ledOffMs: 500,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        subtitle: _getHabitSummary(habit),
        threadIdentifier: 'habit_${habit.id}',
      ),
    );
  }

  /// Generates a summary for a task notification.
  String _getTaskSummary(TaskModel task) {
    if (task.priority >= 4) return 'High Priority';
    if (task.dueDate != null) {
      final now = DateTime.now();
      final isToday =
          task.dueDate!.year == now.year &&
          task.dueDate!.month == now.month &&
          task.dueDate!.day == now.day;
      return isToday ? 'Due Today' : 'Upcoming Task';
    }
    return 'Task Reminder';
  }

  /// Generates a summary for a habit notification.
  String _getHabitSummary(HabitModel habit) {
    if (habit.currentStreak >= 7) return 'Streak Active';
    if (habit.habitType == HabitType.quantifiable) return 'Measurable Goal';
    return 'Daily Habit';
  }

  /// Parses a color string (hex) into a Color object.
  Color? _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return null;
    }
  }

  // MARK: - Eligibility & Time Calculation

  /// Checks if a task is eligible for notification.
  bool _isTaskEligible(TaskModel task) {
    return task.hasNotification && task.dueDate != null;
  }

  /// Checks if a habit is eligible for notification.
  bool _isHabitEligible(HabitModel habit) {
    return habit.hasNotification && habit.preferredTime != null;
  }

  /// Calculates the notification time for a task.
  DateTime? _calculateTaskNotificationTime(TaskModel task) {
    if (task.dueDate == null) return null;
    final minutesBefore = task.notificationMinutesBefore ?? 0;
    return task.dueDate!.subtract(Duration(minutes: minutesBefore));
  }

  /// Calculates the notification time for a habit.
  DateTime? _calculateHabitNotificationTime(
    HabitModel habit,
    DateTime? specificDate,
  ) {
    if (habit.preferredTime == null) return null;
    final baseDate = specificDate ?? DateTime.now();
    final notificationTime = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      habit.preferredTime!.hour,
      habit.preferredTime!.minute,
    );
    return _isTimeInPast(notificationTime)
        ? notificationTime.add(const Duration(days: 1))
        : notificationTime;
  }

  /// Checks if a given time is in the past.
  bool _isTimeInPast(DateTime time) {
    return time.isBefore(DateTime.now());
  }

  // MARK: - Payload & ID Generation

  /// Creates a JSON payload for a task notification.
  String _createTaskPayload(TaskModel task) {
    return jsonEncode({
      NotificationPayloadKeys.type: NotificationTypes.task,
      NotificationPayloadKeys.taskId: task.id,
      NotificationPayloadKeys.title: task.title,
    });
  }

  /// Creates a JSON payload for a habit notification.
  String _createHabitPayload(HabitModel habit) {
    return jsonEncode({
      NotificationPayloadKeys.type: NotificationTypes.habit,
      NotificationPayloadKeys.habitId: habit.id,
      NotificationPayloadKeys.title: habit.title,
    });
  }

  /// Generates a unique notification ID.
  int _generateId(String entityId, int baseId) {
    return baseId + (entityId.hashCode.abs() % _idRange);
  }

  // MARK: - Mapping Helpers

  /// Maps an integer importance level to an Android Importance enum.
  Importance _mapImportance(int level) {
    return switch (level) {
      5 => Importance.max,
      4 => Importance.high,
      3 => Importance.defaultImportance,
      2 => Importance.low,
      _ => Importance.min,
    };
  }

  /// Maps an integer priority level to an Android Priority enum.
  Priority _mapPriority(int level) {
    return switch (level) {
      >= 4 => Priority.max,
      >= 3 => Priority.high,
      _ => Priority.defaultPriority,
    };
  }
}
