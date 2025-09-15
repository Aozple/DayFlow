class AppSettings {
  final String accentColor;
  final String firstDayOfWeek;
  final int defaultTaskPriority;
  final bool defaultNotificationEnabled;
  final int defaultNotificationMinutesBefore;
  final bool notificationSound;
  final bool notificationVibration;

  // Constructor with default values
  const AppSettings({
    this.accentColor = '#0A84FF',
    this.firstDayOfWeek = 'monday',
    this.defaultTaskPriority = 3,
    this.defaultNotificationEnabled = false,
    this.defaultNotificationMinutesBefore = 5,
    this.notificationSound = true,
    this.notificationVibration = true,
  });

  // Convert settings to map with validation
  Map<String, dynamic> toMap() {
    return {
      'accentColor': validateHexColor(accentColor),
      'firstDayOfWeek': validateFirstDay(firstDayOfWeek),
      'defaultTaskPriority': validatePriority(defaultTaskPriority),
      'defaultNotificationEnabled': defaultNotificationEnabled,
      'defaultNotificationMinutesBefore': validateMinutesBefore(
        defaultNotificationMinutesBefore,
      ),
      'notificationSound': notificationSound,
      'notificationVibration': notificationVibration,
    };
  }

  // Create settings from map with validation
  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      accentColor: validateHexColor(map['accentColor'] ?? '#0A84FF'),
      firstDayOfWeek: validateFirstDay(map['firstDayOfWeek'] ?? 'monday'),
      defaultTaskPriority: validatePriority(map['defaultTaskPriority'] ?? 3),
      defaultNotificationEnabled: map['defaultNotificationEnabled'] ?? false,
      defaultNotificationMinutesBefore: validateMinutesBefore(
        map['defaultNotificationMinutesBefore'] ?? 5,
      ),
      notificationSound: map['notificationSound'] ?? true,
      notificationVibration: map['notificationVibration'] ?? true,
    );
  }

  // Validate hex color format
  static String validateHexColor(String color) {
    if (color.startsWith('#') && (color.length == 7 || color.length == 4)) {
      return color;
    }
    return '#0A84FF'; // Default fallback
  }

  // Validate first day of week
  static String validateFirstDay(String day) {
    const validDays = ['monday', 'saturday'];
    return validDays.contains(day.toLowerCase()) ? day.toLowerCase() : 'monday';
  }

  // Validate priority range (1-5)
  static int validatePriority(int priority) {
    return priority.clamp(1, 5);
  }

  // Validate notification time (0-1440 minutes)
  static int validateMinutesBefore(int minutes) {
    return minutes.clamp(0, 1440); // Max 24 hours in minutes
  }

  // Create a new instance with updated fields
  AppSettings copyWith({
    String? accentColor,
    String? firstDayOfWeek,
    int? defaultTaskPriority,
    bool? defaultNotificationEnabled,
    int? defaultNotificationMinutesBefore,
    bool? notificationSound,
    bool? notificationVibration,
  }) {
    return AppSettings(
      accentColor:
          accentColor != null
              ? validateHexColor(accentColor)
              : this.accentColor,
      firstDayOfWeek:
          firstDayOfWeek != null
              ? validateFirstDay(firstDayOfWeek)
              : this.firstDayOfWeek,
      defaultTaskPriority:
          defaultTaskPriority != null
              ? validatePriority(defaultTaskPriority)
              : this.defaultTaskPriority,
      defaultNotificationEnabled:
          defaultNotificationEnabled ?? this.defaultNotificationEnabled,
      defaultNotificationMinutesBefore:
          defaultNotificationMinutesBefore != null
              ? validateMinutesBefore(defaultNotificationMinutesBefore)
              : this.defaultNotificationMinutesBefore,
      notificationSound: notificationSound ?? this.notificationSound,
      notificationVibration:
          notificationVibration ?? this.notificationVibration,
    );
  }

  // Check if all settings are valid
  bool isValid() {
    try {
      validateHexColor(accentColor);
      validateFirstDay(firstDayOfWeek);
      validatePriority(defaultTaskPriority);
      validateMinutesBefore(defaultNotificationMinutesBefore);
      return true;
    } catch (e) {
      return false;
    }
  }
}
