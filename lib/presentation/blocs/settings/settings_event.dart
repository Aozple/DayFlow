part of 'settings_bloc.dart';

// This is the base class for all events related to app settings.
// Events are like actions that the UI dispatches to the SettingsBloc.
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => []; // All events should be equatable for proper comparison.
}

// This event tells the SettingsBloc to load the app settings.
class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

// This event is dispatched when the user wants to change the app's accent color.
class UpdateAccentColor extends SettingsEvent {
  final String colorHex; // The new accent color, in hex format.

  const UpdateAccentColor(this.colorHex);

  @override
  List<Object?> get props => [colorHex];
}

// This event is dispatched when the user wants to change which day the week starts on.
class UpdateFirstDayOfWeek extends SettingsEvent {
  final String day; // Can be 'saturday' or 'monday'.

  const UpdateFirstDayOfWeek(this.day);

  @override
  List<Object?> get props => [day];
}

// This event is dispatched when the user wants to set a new default priority for tasks.
class UpdateDefaultPriority extends SettingsEvent {
  final int priority; // The new default priority level.

  const UpdateDefaultPriority(this.priority);

  @override
  List<Object?> get props => [priority];
}

// Event to update default notification enabled
class UpdateNotificationEnabled extends SettingsEvent {
  final bool enabled;

  const UpdateNotificationEnabled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

// Event to update default notification time
class UpdateDefaultNotificationTime extends SettingsEvent {
  final int minutesBefore;

  const UpdateDefaultNotificationTime(this.minutesBefore);

  @override
  List<Object?> get props => [minutesBefore];
}

// Event to update notification sound
class UpdateNotificationSound extends SettingsEvent {
  final bool enabled;

  const UpdateNotificationSound(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

// Event to update notification vibration
class UpdateNotificationVibration extends SettingsEvent {
  final bool enabled;

  const UpdateNotificationVibration(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

// Event to reset all settings to defaults
class ResetSettings extends SettingsEvent {
  const ResetSettings();
}

// Event to export settings data
class ExportSettings extends SettingsEvent {
  final String format; // 'json' or 'csv'

  const ExportSettings({required this.format});

  @override
  List<Object?> get props => [format];
}

// Event to import settings data
class ImportSettings extends SettingsEvent {
  final String data;
  final String format; // 'json' or 'csv'

  const ImportSettings({required this.data, required this.format});

  @override
  List<Object?> get props => [data, format];
}
