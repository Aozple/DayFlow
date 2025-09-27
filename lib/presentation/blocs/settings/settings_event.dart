part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

// Load and save events
class LoadSettings extends SettingsEvent {
  final bool forceRefresh;

  const LoadSettings({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

// Theme and appearance
class UpdateAccentColor extends SettingsEvent {
  final String colorHex;
  final bool saveImmediately;

  const UpdateAccentColor(this.colorHex, {this.saveImmediately = true});

  @override
  List<Object?> get props => [colorHex, saveImmediately];
}

// Calendar settings
class UpdateFirstDayOfWeek extends SettingsEvent {
  final String day;

  const UpdateFirstDayOfWeek(this.day);

  @override
  List<Object?> get props => [day];
}

// Task defaults
class UpdateDefaultPriority extends SettingsEvent {
  final int priority;

  const UpdateDefaultPriority(this.priority);

  @override
  List<Object?> get props => [priority];
}

// Notification settings
class UpdateNotificationEnabled extends SettingsEvent {
  final bool enabled;
  final NotificationType? type;

  const UpdateNotificationEnabled(this.enabled, {this.type});

  @override
  List<Object?> get props => [enabled, type];
}

class UpdateDefaultNotificationTime extends SettingsEvent {
  final int minutesBefore;

  const UpdateDefaultNotificationTime(this.minutesBefore);

  @override
  List<Object?> get props => [minutesBefore];
}

class UpdateNotificationSound extends SettingsEvent {
  final bool enabled;
  final String? soundName;

  const UpdateNotificationSound(this.enabled, {this.soundName});

  @override
  List<Object?> get props => [enabled, soundName];
}

class UpdateNotificationVibration extends SettingsEvent {
  final bool enabled;
  final VibrationType? pattern;

  const UpdateNotificationVibration(this.enabled, {this.pattern});

  @override
  List<Object?> get props => [enabled, pattern];
}

// Batch updates
class BatchUpdateSettings extends SettingsEvent {
  final Map<String, dynamic> updates;
  final bool validateBeforeSave;

  const BatchUpdateSettings(this.updates, {this.validateBeforeSave = true});

  @override
  List<Object?> get props => [updates, validateBeforeSave];
}

// Reset and export/import
class ResetSettings extends SettingsEvent {
  final SettingsResetScope scope;

  const ResetSettings({this.scope = SettingsResetScope.all});

  @override
  List<Object?> get props => [scope];
}

// Enums for settings events
enum NotificationType { all, tasks, reminders, updates }

enum VibrationType { none, light, medium, heavy, pattern }

enum SettingsResetScope { all, appearance, notifications, tasks, privacy }
