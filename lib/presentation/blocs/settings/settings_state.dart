part of 'settings_bloc.dart';

// This is the base class for all states related to app settings.
// States represent the different conditions or data the UI can be in.
abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => []; // All states should be equatable for proper comparison.
}

// The initial state of the settings bloc when the app first starts.
class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

// This state indicates that settings are currently being loaded or saved.
class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

// This state holds the successfully loaded application settings.
// It's the main state when settings are ready for display or use.
class SettingsLoaded extends SettingsState {
  final AppSettings settings; // The actual settings data.

  const SettingsLoaded(this.settings);

  @override
  List<Object?> get props => [settings];

  // Convenience getters to easily access individual setting values.
  String get accentColor => settings.accentColor;
  String get firstDayOfWeek => settings.firstDayOfWeek;
  int get defaultPriority => settings.defaultTaskPriority;

  // Returns a human-readable label for the first day of the week.
  String get firstDayLabel {
    return settings.firstDayOfWeek == 'saturday' ? 'Saturday' : 'Monday';
  }

  // Returns a human-readable label for the default task priority.
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
        return 'Medium'; // Fallback for unexpected values.
    }
  }

  // Checks if Saturday is set as the first day of the week.
  bool get isSaturdayFirst => settings.firstDayOfWeek == 'saturday';

  // Checks if Monday is set as the first day of the week.
  bool get isMondayFirst => settings.firstDayOfWeek == 'monday';
}

// This state is emitted when an error occurs during settings operations.
class SettingsError extends SettingsState {
  final String message; // A message describing the error.

  const SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}

// This state is used to indicate a successful operation, often with a message
// to show to the user (e.g., "Settings saved!").
class SettingsOperationSuccess extends SettingsState {
  final String message; // The success message.
  final AppSettings settings; // The current settings after the successful operation.

  const SettingsOperationSuccess({
    required this.message,
    required this.settings,
  });

  @override
  List<Object?> get props => [message, settings];
}

// This state is specifically for when the accent color has been updated.
// It might be used for immediate UI feedback before full persistence.
class SettingsAccentColorUpdated extends SettingsState {
  final AppSettings settings; // The new settings with the updated color.
  final String previousColor; // The color before the update.

  const SettingsAccentColorUpdated({
    required this.settings,
    required this.previousColor,
  });

  @override
  List<Object?> get props => [settings, previousColor];
}

// This state is emitted when settings data is ready to be exported.
class SettingsExportReady extends SettingsState {
  final String exportData; // The settings data as a JSON string.
  final AppSettings settings; // The current settings.

  const SettingsExportReady({required this.exportData, required this.settings});

  @override
  List<Object?> get props => [exportData, settings];
}

// This state indicates that settings have been successfully imported.
class SettingsImportSuccess extends SettingsState {
  final AppSettings settings; // The settings after a successful import.
  final int itemsImported; // Number of items (e.g., tasks, notes) imported.

  const SettingsImportSuccess({
    required this.settings,
    required this.itemsImported,
  });

  @override
  List<Object?> get props => [settings, itemsImported];
}
