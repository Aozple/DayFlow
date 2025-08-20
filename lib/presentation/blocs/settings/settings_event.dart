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
