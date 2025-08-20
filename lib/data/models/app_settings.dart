// This class defines the structure for our application's settings.
// It holds user preferences like accent color, first day of the week, and default task priority.
class AppSettings {
  // The user's chosen accent color, stored as a hex string.
  final String accentColor;
  // Specifies whether the week starts on 'saturday' or 'monday'.
  final String firstDayOfWeek;
  // The default priority level for any new tasks created.
  final int defaultTaskPriority;

  // Constructor with default values for all settings.
  const AppSettings({
    this.accentColor = '#0A84FF', // Default to iOS blue.
    this.firstDayOfWeek = 'monday', // Default to Monday.
    this.defaultTaskPriority = 3, // Default task priority is 3 (medium).
  });

  // Converts this AppSettings object into a Map.
  // This is used for storing the settings in persistent storage (like SharedPreferences or Hive).
  Map<String, dynamic> toMap() {
    return {
      'accentColor': accentColor,
      'firstDayOfWeek': firstDayOfWeek,
      'defaultTaskPriority': defaultTaskPriority,
    };
  }

  // Creates an AppSettings object from a Map.
  // This is used when reading settings data back from storage.
  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      accentColor: map['accentColor'] ?? '#0A84FF', // Provide default if value is null.
      firstDayOfWeek: map['firstDayOfWeek'] ?? 'monday', // Provide default if value is null.
      defaultTaskPriority: map['defaultTaskPriority'] ?? 3, // Provide default if value is null.
    );
  }

  // Creates a new AppSettings instance by copying existing values,
  // but allowing specific fields to be overridden.
  // This is handy for updating just a few settings without recreating the whole object.
  AppSettings copyWith({
    String? accentColor,
    String? firstDayOfWeek,
    int? defaultTaskPriority,
  }) {
    return AppSettings(
      accentColor: accentColor ?? this.accentColor, // Use new value if provided, otherwise keep old.
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek, // Use new value if provided, otherwise keep old.
      defaultTaskPriority: defaultTaskPriority ?? this.defaultTaskPriority, // Use new value if provided, otherwise keep old.
    );
  }
}
