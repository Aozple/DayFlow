part of 'settings_bloc.dart';

// Base class for all settings events
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

// Load settings from storage
class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

// Update app accent color
class UpdateAccentColor extends SettingsEvent {
  final String colorHex;

  const UpdateAccentColor(this.colorHex);

  @override
  List<Object?> get props => [colorHex];
}

// Change first day of week
class UpdateFirstDayOfWeek extends SettingsEvent {
  final String day; // 'saturday' or 'monday'

  const UpdateFirstDayOfWeek(this.day);

  @override
  List<Object?> get props => [day];
}

// Set default task priority
class UpdateDefaultPriority extends SettingsEvent {
  final int priority;

  const UpdateDefaultPriority(this.priority);

  @override
  List<Object?> get props => [priority];
}

// Toggle default notification setting
class UpdateNotificationEnabled extends SettingsEvent {
  final bool enabled;

  const UpdateNotificationEnabled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

// Change default notification time
class UpdateDefaultNotificationTime extends SettingsEvent {
  final int minutesBefore;

  const UpdateDefaultNotificationTime(this.minutesBefore);

  @override
  List<Object?> get props => [minutesBefore];
}

// Toggle notification sound
class UpdateNotificationSound extends SettingsEvent {
  final bool enabled;

  const UpdateNotificationSound(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

// Toggle notification vibration
class UpdateNotificationVibration extends SettingsEvent {
  final bool enabled;

  const UpdateNotificationVibration(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

// Reset all settings to defaults
class ResetSettings extends SettingsEvent {
  const ResetSettings();
}

// Export settings to file
class ExportSettings extends SettingsEvent {
  final String format; // 'json' or 'csv'

  const ExportSettings({required this.format});

  @override
  List<Object?> get props => [format];
}

// Import settings from file
class ImportSettings extends SettingsEvent {
  final String data;
  final String format; // 'json' or 'csv'

  const ImportSettings({required this.data, required this.format});

  @override
  List<Object?> get props => [data, format];
}
