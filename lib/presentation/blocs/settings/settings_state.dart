part of 'settings_bloc.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  final String? message;

  const SettingsLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class SettingsLoaded extends SettingsState {
  final AppSettings settings;

  const SettingsLoaded(this.settings);

  @override
  List<Object?> get props => [settings];

  String get accentColor => settings.accentColor;
  String get firstDayOfWeek => settings.firstDayOfWeek;
  int get defaultPriority => settings.defaultTaskPriority;
  bool get defaultNotificationEnabled => settings.defaultNotificationEnabled;
  int get defaultNotificationMinutesBefore =>
      settings.defaultNotificationMinutesBefore;
  bool get notificationSound => settings.notificationSound;
  bool get notificationVibration => settings.notificationVibration;

  String get firstDayLabel {
    return settings.firstDayOfWeek == 'saturday' ? 'Saturday' : 'Monday';
  }

  String get priorityLabel {
    switch (settings.defaultTaskPriority) {
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
    final minutes = settings.defaultNotificationMinutesBefore;
    if (minutes == 0) return 'At time';
    if (minutes < 60) return '$minutes min before';

    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (mins == 0) {
      return hours == 1 ? '1 hour before' : '$hours hours before';
    }
    return '$hours hr $mins min before';
  }

  bool get isSaturdayFirst => settings.firstDayOfWeek == 'saturday';
  bool get isMondayFirst => settings.firstDayOfWeek == 'monday';

  SettingsLoaded copyWith({AppSettings? settings}) {
    return SettingsLoaded(settings ?? this.settings);
  }
}

class SettingsError extends SettingsState {
  final String message;
  final dynamic error;

  const SettingsError(this.message, {this.error});

  @override
  List<Object?> get props => [message, error];
}
