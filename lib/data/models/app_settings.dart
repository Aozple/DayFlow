import 'package:dayflow/core/utils/debug_logger.dart';

class AppSettings {
  static const String _tag = 'AppSettings';

  final String accentColor;
  final String firstDayOfWeek;
  final int defaultTaskPriority;
  final bool defaultNotificationEnabled;
  final int defaultNotificationMinutesBefore;
  final bool notificationSound;
  final bool notificationVibration;

  // Default values
  static const String defaultAccentColor = '#0A84FF';
  static const String defaultFirstDay = 'monday';
  static const int defaultPriority = 3;
  static const bool defaultNotificationState = false;
  static const int defaultMinutesBefore = 5;
  static const bool defaultSound = true;
  static const bool defaultVibration = true;

  // Valid options
  static const List<String> validFirstDays = ['monday', 'saturday'];
  static const List<int> validMinutesOptions = [
    0,
    5,
    10,
    15,
    30,
    60,
    120,
    240,
    1440,
  ];

  // Predefined accent colors for quick selection
  static const Map<String, String> predefinedColors = {
    'blue': '#0A84FF',
    'purple': '#6C63FF',
    'green': '#34C759',
    'red': '#FF3B30',
    'orange': '#FF9500',
    'pink': '#FF2D55',
    'teal': '#5AC8FA',
    'indigo': '#5856D6',
    'yellow': '#FFCC00',
  };

  const AppSettings({
    this.accentColor = defaultAccentColor,
    this.firstDayOfWeek = defaultFirstDay,
    this.defaultTaskPriority = defaultPriority,
    this.defaultNotificationEnabled = defaultNotificationState,
    this.defaultNotificationMinutesBefore = defaultMinutesBefore,
    this.notificationSound = defaultSound,
    this.notificationVibration = defaultVibration,
  });

  Map<String, dynamic> toMap() {
    try {
      final map = {
        'accentColor': validateHexColor(accentColor),
        'firstDayOfWeek': validateFirstDay(firstDayOfWeek),
        'defaultTaskPriority': validatePriority(defaultTaskPriority),
        'defaultNotificationEnabled': defaultNotificationEnabled,
        'defaultNotificationMinutesBefore': validateMinutesBefore(
          defaultNotificationMinutesBefore,
        ),
        'notificationSound': notificationSound,
        'notificationVibration': notificationVibration,
        '_version': 1, // For future migrations
      };

      DebugLogger.verbose('Settings serialized', tag: _tag);
      return map;
    } catch (e) {
      DebugLogger.error('Failed to serialize settings', tag: _tag, error: e);
      return _getDefaultMap();
    }
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    try {
      // Check version for future migrations
      final version = map['_version'] as int? ?? 0;
      if (version > 1) {
        DebugLogger.warning(
          'Settings from newer version',
          tag: _tag,
          data: 'v$version',
        );
      }

      return AppSettings(
        accentColor: validateHexColor(
          map['accentColor'] as String? ?? defaultAccentColor,
        ),
        firstDayOfWeek: validateFirstDay(
          map['firstDayOfWeek'] as String? ?? defaultFirstDay,
        ),
        defaultTaskPriority: validatePriority(
          _parseIntSafe(map['defaultTaskPriority']) ?? defaultPriority,
        ),
        defaultNotificationEnabled:
            map['defaultNotificationEnabled'] as bool? ??
            defaultNotificationState,
        defaultNotificationMinutesBefore: validateMinutesBefore(
          _parseIntSafe(map['defaultNotificationMinutesBefore']) ??
              defaultMinutesBefore,
        ),
        notificationSound: map['notificationSound'] as bool? ?? defaultSound,
        notificationVibration:
            map['notificationVibration'] as bool? ?? defaultVibration,
      );
    } catch (e) {
      DebugLogger.error('Failed to deserialize settings', tag: _tag, error: e);
      return const AppSettings();
    }
  }

  static int? _parseIntSafe(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;

    try {
      return int.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _getDefaultMap() {
    return const AppSettings().toMap();
  }

  // Enhanced validation with logging
  static String validateHexColor(String color) {
    // Try predefined colors first
    final predefinedColor =
        predefinedColors.entries
            .firstWhere(
              (entry) => entry.value.toLowerCase() == color.toLowerCase(),
              orElse: () => const MapEntry('', ''),
            )
            .value;

    if (predefinedColor.isNotEmpty) {
      return predefinedColor;
    }

    // Validate hex format
    final hexRegex = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$');

    if (hexRegex.hasMatch(color)) {
      // Normalize 3-digit hex to 6-digit
      if (color.length == 4) {
        final r = color[1];
        final g = color[2];
        final b = color[3];
        return '#$r$r$g$g$b$b';
      }
      return color.toUpperCase();
    }

    DebugLogger.warning('Invalid color, using default', tag: _tag, data: color);
    return defaultAccentColor;
  }

  static String validateFirstDay(String day) {
    final normalized = day.toLowerCase().trim();
    if (validFirstDays.contains(normalized)) {
      return normalized;
    }

    DebugLogger.warning(
      'Invalid first day, using default',
      tag: _tag,
      data: day,
    );
    return defaultFirstDay;
  }

  static int validatePriority(int priority) {
    if (priority >= 1 && priority <= 5) {
      return priority;
    }

    DebugLogger.warning(
      'Invalid priority, using default',
      tag: _tag,
      data: priority,
    );
    return defaultPriority.clamp(1, 5);
  }

  static int validateMinutesBefore(int minutes) {
    // Allow any value between 0 and 1440 (24 hours)
    final clamped = minutes.clamp(0, 1440);

    if (clamped != minutes) {
      DebugLogger.warning(
        'Minutes clamped',
        tag: _tag,
        data: '$minutes -> $clamped',
      );
    }

    return clamped;
  }

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

  // Validation
  bool isValid() {
    try {
      // Validate all fields
      validateHexColor(accentColor);
      validateFirstDay(firstDayOfWeek);
      validatePriority(defaultTaskPriority);
      validateMinutesBefore(defaultNotificationMinutesBefore);
      return true;
    } catch (e) {
      DebugLogger.error('Settings validation failed', tag: _tag, error: e);
      return false;
    }
  }

  // Helper getters
  bool get isSaturdayFirst => firstDayOfWeek == 'saturday';
  bool get isMondayFirst => firstDayOfWeek == 'monday';

  String get firstDayLabel => isSaturdayFirst ? 'Saturday' : 'Monday';

  String get priorityLabel {
    switch (defaultTaskPriority) {
      case 1:
        return 'Low';
      case 2:
        return 'Normal';
      case 3:
        return 'Medium';
      case 4:
        return 'High';
      case 5:
        return 'Urgent';
      default:
        return 'Medium';
    }
  }

  String get notificationTimeLabel {
    if (defaultNotificationMinutesBefore == 0) return 'At time';
    if (defaultNotificationMinutesBefore < 60) {
      return '$defaultNotificationMinutesBefore min before';
    }

    final hours = defaultNotificationMinutesBefore ~/ 60;
    final minutes = defaultNotificationMinutesBefore % 60;

    if (minutes == 0) {
      return hours == 1 ? '1 hour before' : '$hours hours before';
    } else {
      return '$hours hr $minutes min before';
    }
  }

  // Color helpers
  int get accentColorValue {
    try {
      return int.parse(accentColor.substring(1), radix: 16) | 0xFF000000;
    } catch (_) {
      return 0xFF0A84FF; // Default blue
    }
  }

  bool isDefaultSettings() {
    return accentColor == defaultAccentColor &&
        firstDayOfWeek == defaultFirstDay &&
        defaultTaskPriority == defaultPriority &&
        defaultNotificationEnabled == defaultNotificationState &&
        defaultNotificationMinutesBefore == defaultMinutesBefore &&
        notificationSound == defaultSound &&
        notificationVibration == defaultVibration;
  }

  Map<String, dynamic> getDifferencesFrom(AppSettings other) {
    final differences = <String, dynamic>{};

    if (accentColor != other.accentColor) {
      differences['accentColor'] = {
        'old': other.accentColor,
        'new': accentColor,
      };
    }
    if (firstDayOfWeek != other.firstDayOfWeek) {
      differences['firstDayOfWeek'] = {
        'old': other.firstDayOfWeek,
        'new': firstDayOfWeek,
      };
    }
    if (defaultTaskPriority != other.defaultTaskPriority) {
      differences['defaultTaskPriority'] = {
        'old': other.defaultTaskPriority,
        'new': defaultTaskPriority,
      };
    }
    if (defaultNotificationEnabled != other.defaultNotificationEnabled) {
      differences['defaultNotificationEnabled'] = {
        'old': other.defaultNotificationEnabled,
        'new': defaultNotificationEnabled,
      };
    }
    if (defaultNotificationMinutesBefore !=
        other.defaultNotificationMinutesBefore) {
      differences['defaultNotificationMinutesBefore'] = {
        'old': other.defaultNotificationMinutesBefore,
        'new': defaultNotificationMinutesBefore,
      };
    }
    if (notificationSound != other.notificationSound) {
      differences['notificationSound'] = {
        'old': other.notificationSound,
        'new': notificationSound,
      };
    }
    if (notificationVibration != other.notificationVibration) {
      differences['notificationVibration'] = {
        'old': other.notificationVibration,
        'new': notificationVibration,
      };
    }

    return differences;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppSettings &&
        other.accentColor == accentColor &&
        other.firstDayOfWeek == firstDayOfWeek &&
        other.defaultTaskPriority == defaultTaskPriority &&
        other.defaultNotificationEnabled == defaultNotificationEnabled &&
        other.defaultNotificationMinutesBefore ==
            defaultNotificationMinutesBefore &&
        other.notificationSound == notificationSound &&
        other.notificationVibration == notificationVibration;
  }

  @override
  int get hashCode {
    return Object.hash(
      accentColor,
      firstDayOfWeek,
      defaultTaskPriority,
      defaultNotificationEnabled,
      defaultNotificationMinutesBefore,
      notificationSound,
      notificationVibration,
    );
  }

  @override
  String toString() {
    return 'AppSettings('
        'color: $accentColor, '
        'firstDay: $firstDayOfWeek, '
        'priority: $defaultTaskPriority, '
        'notification: $defaultNotificationEnabled'
        ')';
  }
}
