class AppConstants {
  AppConstants._();

  // Box names
  static const String tasksBox = 'tasks';
  static const String habitsBox = 'habits';
  static const String habitInstancesBox = 'habit_instances';
  static const String settingsBox = 'settings';

  // Default values
  static const int defaultDaysAhead = 30;
  static const int defaultPriority = 3;
  static const int defaultNotificationMinutes = 5;

  // Cache durations
  static const Duration defaultCacheDuration = Duration(seconds: 30);
  static const Duration quickExportDuration = Duration(seconds: 30);

  // Export/Import
  static const String appName = 'DayFlow';
  static const int currentDataVersion = 1;
  static const String exportDateFormat = 'yyyyMMdd_HHmmss';
  static const String displayDateFormat = 'yyyy-MM-dd HH:mm';

  // File extensions
  static const List<String> importExtensions = ['json', 'csv'];
  static const String jsonExtension = 'json';
  static const String csvExtension = 'csv';
  static const String markdownExtension = 'md';
}
