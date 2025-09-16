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

class SaveSettings extends SettingsEvent {
  final AppSettings settings;

  const SaveSettings(this.settings);

  @override
  List<Object?> get props => [settings];
}

// Theme and appearance
class UpdateAccentColor extends SettingsEvent {
  final String colorHex;
  final bool saveImmediately;

  const UpdateAccentColor(this.colorHex, {this.saveImmediately = true});

  @override
  List<Object?> get props => [colorHex, saveImmediately];
}

class UpdateThemeMode extends SettingsEvent {
  final ThemeMode mode;

  const UpdateThemeMode(this.mode);

  @override
  List<Object?> get props => [mode];
}

// Calendar settings
class UpdateFirstDayOfWeek extends SettingsEvent {
  final String day;

  const UpdateFirstDayOfWeek(this.day);

  @override
  List<Object?> get props => [day];
}

class UpdateCalendarView extends SettingsEvent {
  final CalendarView view;

  const UpdateCalendarView(this.view);

  @override
  List<Object?> get props => [view];
}

// Task defaults
class UpdateDefaultPriority extends SettingsEvent {
  final int priority;

  const UpdateDefaultPriority(this.priority);

  @override
  List<Object?> get props => [priority];
}

class UpdateDefaultTaskDuration extends SettingsEvent {
  final int minutes;

  const UpdateDefaultTaskDuration(this.minutes);

  @override
  List<Object?> get props => [minutes];
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

class UpdateQuietHours extends SettingsEvent {
  final bool enabled;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;

  const UpdateQuietHours({required this.enabled, this.startTime, this.endTime});

  @override
  List<Object?> get props => [enabled, startTime, endTime];
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

class ExportSettings extends SettingsEvent {
  final String format;
  final bool includeStatistics;

  const ExportSettings({this.format = 'json', this.includeStatistics = false});

  @override
  List<Object?> get props => [format, includeStatistics];
}

class ImportSettings extends SettingsEvent {
  final String data;
  final String format;
  final bool merge;

  const ImportSettings({
    required this.data,
    required this.format,
    this.merge = false,
  });

  @override
  List<Object?> get props => [data, format, merge];
}

// Privacy and data
class UpdateDataCollection extends SettingsEvent {
  final bool allowAnalytics;
  final bool allowCrashReports;

  const UpdateDataCollection({
    required this.allowAnalytics,
    required this.allowCrashReports,
  });

  @override
  List<Object?> get props => [allowAnalytics, allowCrashReports];
}

class ClearUserData extends SettingsEvent {
  final DataClearScope scope;
  final bool keepSettings;

  const ClearUserData({required this.scope, this.keepSettings = true});

  @override
  List<Object?> get props => [scope, keepSettings];
}

// Sync settings
class UpdateSyncEnabled extends SettingsEvent {
  final bool enabled;
  final SyncProvider? provider;

  const UpdateSyncEnabled(this.enabled, {this.provider});

  @override
  List<Object?> get props => [enabled, provider];
}

class SyncSettingsNow extends SettingsEvent {
  final SyncDirection direction;

  const SyncSettingsNow({this.direction = SyncDirection.both});

  @override
  List<Object?> get props => [direction];
}

// Enums for settings events
enum NotificationType { all, tasks, reminders, updates }

enum VibrationType { none, light, medium, heavy, pattern }

enum CalendarView { day, week, month, agenda }

enum SettingsResetScope { all, appearance, notifications, tasks, privacy }

enum DataClearScope { cache, downloads, userData, all }

enum SyncProvider { google, icloud, dropbox, custom }

enum SyncDirection { upload, download, both }
