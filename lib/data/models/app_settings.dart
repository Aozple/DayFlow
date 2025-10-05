import 'package:dayflow/core/utils/color_utils.dart';
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

  static const String defaultAccentColor = '#0A84FF';
  static const String defaultFirstDay = 'monday';
  static const int defaultPriority = 3;
  static const bool defaultNotificationState = false;
  static const int defaultMinutesBefore = 5;
  static const bool defaultSound = true;
  static const bool defaultVibration = true;

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
        'accentColor':
            ColorUtils.validateHex(accentColor) ?? defaultAccentColor,
        'firstDayOfWeek': validateFirstDay(firstDayOfWeek),
        'defaultTaskPriority': validatePriority(defaultTaskPriority),
        'defaultNotificationEnabled': defaultNotificationEnabled,
        'defaultNotificationMinutesBefore': validateMinutesBefore(
          defaultNotificationMinutesBefore,
        ),
        'notificationSound': notificationSound,
        'notificationVibration': notificationVibration,
        '_version': 1,
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
      final version = map['_version'] as int? ?? 0;
      if (version > 1) {
        DebugLogger.warning(
          'Settings from newer version',
          tag: _tag,
          data: 'v$version',
        );
      }

      return AppSettings(
        accentColor:
            ColorUtils.validateHex(
              map['accentColor'] as String? ?? defaultAccentColor,
            ) ??
            defaultAccentColor,
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
    return defaultPriority;
  }

  static int validateMinutesBefore(int minutes) {
    if (validMinutesOptions.contains(minutes)) {
      return minutes;
    }

    final nearest = validMinutesOptions.reduce((a, b) {
      return (a - minutes).abs() < (b - minutes).abs() ? a : b;
    });

    DebugLogger.warning(
      'Minutes adjusted to nearest valid option',
      tag: _tag,
      data: '$minutes -> $nearest',
    );

    return nearest;
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
      accentColor: accentColor ?? this.accentColor,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      defaultTaskPriority: defaultTaskPriority ?? this.defaultTaskPriority,
      defaultNotificationEnabled:
          defaultNotificationEnabled ?? this.defaultNotificationEnabled,
      defaultNotificationMinutesBefore:
          defaultNotificationMinutesBefore ??
          this.defaultNotificationMinutesBefore,
      notificationSound: notificationSound ?? this.notificationSound,
      notificationVibration:
          notificationVibration ?? this.notificationVibration,
    );
  }

  bool isValid() {
    try {
      ColorUtils.validateHex(accentColor) ?? defaultAccentColor;
      validateFirstDay(firstDayOfWeek);
      validatePriority(defaultTaskPriority);
      validateMinutesBefore(defaultNotificationMinutesBefore);
      return true;
    } catch (e) {
      DebugLogger.error('Settings validation failed', tag: _tag, error: e);
      return false;
    }
  }

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

  int get accentColorValue {
    try {
      return ColorUtils.fromHex(accentColor).toARGB32();
    } catch (_) {
      return 0xFF0A84FF;
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
