class AppConstants {
  AppConstants._();

  // MARK: - Box Names
  static const String tasksBox = 'tasks';
  static const String habitsBox = 'habits';
  static const String habitInstancesBox = 'habit_instances';
  static const String settingsBox = 'settings';

  // MARK: - Default Values
  static const int defaultDaysAhead = 30;
  static const int defaultPriority = 3;
  static const int defaultNotificationMinutes = 5;

  // MARK: - Cache Durations
  static const Duration defaultCacheDuration = Duration(seconds: 30);
  static const Duration quickExportDuration = Duration(seconds: 30);

  // MARK: - Export/Import
  static const String appName = 'DayFlow';
  static const int currentDataVersion = 1;
  static const String exportDateFormat = 'yyyyMMdd_HHmmss';
  static const String displayDateFormat = 'yyyy-MM-dd HH:mm';

  // MARK: - File Extensions
  static const List<String> importExtensions = ['json', 'csv'];
  static const String jsonExtension = 'json';
  static const String csvExtension = 'csv';
  static const String markdownExtension = 'md';
}
