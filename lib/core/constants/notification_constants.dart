class NotificationChannels {
  NotificationChannels._();

  static const String taskHigh = 'dayflow_task_high';
  static const String taskDefault = 'dayflow_task_default';
  static const String habitReminder = 'dayflow_habit_reminder';
  static const String general = 'dayflow_general';

  static const Map<String, ChannelConfig> configs = {
    taskHigh: ChannelConfig(
      name: 'Urgent Tasks',
      description: 'High priority task notifications',
      importance: 5,
    ),
    taskDefault: ChannelConfig(
      name: 'Task Reminders',
      description: 'Regular task notifications',
      importance: 4,
    ),
    habitReminder: ChannelConfig(
      name: 'Habit Reminders',
      description: 'Daily habit reminders',
      importance: 4,
    ),
    general: ChannelConfig(
      name: 'General',
      description: 'General app notifications',
      importance: 3,
    ),
  };
}

class ChannelConfig {
  final String name;
  final String description;
  final int importance;

  const ChannelConfig({
    required this.name,
    required this.description,
    required this.importance,
  });
}

class NotificationPayloadKeys {
  NotificationPayloadKeys._();

  static const String id = 'id';
  static const String type = 'type';
  static const String title = 'title';
  static const String taskId = 'task_id';
  static const String habitId = 'habit_id';
}

class NotificationTypes {
  NotificationTypes._();

  static const String task = 'task';
  static const String habit = 'habit';
  static const String general = 'general';
}
