part of 'settings_bloc.dart';

// Base class for all settings states
abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

// Initial state when app starts
class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

// Loading state during operations
class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

// State with loaded settings data
class SettingsLoaded extends SettingsState {
  final AppSettings settings;
  const SettingsLoaded(this.settings);

  @override
  List<Object?> get props => [settings];

  // Convenience getters for settings values
  String get accentColor => settings.accentColor;
  String get firstDayOfWeek => settings.firstDayOfWeek;
  int get defaultPriority => settings.defaultTaskPriority;
  bool get defaultNotificationEnabled => settings.defaultNotificationEnabled;
  int get defaultNotificationMinutesBefore =>
      settings.defaultNotificationMinutesBefore;
  bool get notificationSound => settings.notificationSound;
  bool get notificationVibration => settings.notificationVibration;

  // Human-readable first day label
  String get firstDayLabel {
    return settings.firstDayOfWeek == 'saturday' ? 'Saturday' : 'Monday';
  }

  // Human-readable priority label
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

  // Human-readable notification time label
  String get notificationTimeLabel {
    if (settings.defaultNotificationMinutesBefore == 0) return 'At time';
    if (settings.defaultNotificationMinutesBefore == 5) return '5 min before';
    if (settings.defaultNotificationMinutesBefore == 10) return '10 min before';
    if (settings.defaultNotificationMinutesBefore == 15) return '15 min before';
    if (settings.defaultNotificationMinutesBefore == 30) return '30 min before';
    if (settings.defaultNotificationMinutesBefore == 60) return '1 hour before';
    return '${settings.defaultNotificationMinutesBefore} min before';
  }

  // Helper methods for first day of week
  bool get isSaturdayFirst => settings.firstDayOfWeek == 'saturday';
  bool get isMondayFirst => settings.firstDayOfWeek == 'monday';
}

// Error state
class SettingsError extends SettingsState {
  final String message;
  const SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Success state after operation
class SettingsOperationSuccess extends SettingsState {
  final String message;
  final AppSettings settings;

  const SettingsOperationSuccess({
    required this.message,
    required this.settings,
  });

  @override
  List<Object?> get props => [message, settings];
}

// Special state for accent color updates
class SettingsAccentColorUpdated extends SettingsState {
  final AppSettings settings;
  final String previousColor;

  const SettingsAccentColorUpdated({
    required this.settings,
    required this.previousColor,
  });

  @override
  List<Object?> get props => [settings, previousColor];
}

// State for settings export
class SettingsExportReady extends SettingsState {
  final String exportData;
  final AppSettings settings;

  const SettingsExportReady({required this.exportData, required this.settings});

  @override
  List<Object?> get props => [exportData, settings];
}

// State for settings import
class SettingsImportSuccess extends SettingsState {
  final AppSettings settings;
  final int itemsImported;

  const SettingsImportSuccess({
    required this.settings,
    required this.itemsImported,
  });

  @override
  List<Object?> get props => [settings, itemsImported];
}
