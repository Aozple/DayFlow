import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/app_settings.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/settings_repository.dart';

part 'settings_event.dart';
part 'settings_state.dart';

// This is our SettingsBloc, responsible for managing all app settings.
// It takes SettingsEvent (actions) and emits SettingsState (UI updates).
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  // We need a SettingsRepository to handle saving and loading settings.
  final SettingsRepository _repository;

  // The constructor sets up the repository and registers all event handlers.
  SettingsBloc({required SettingsRepository repository})
    : _repository = repository,
      super(const SettingsInitial()) {
    // When a LoadSettings event comes in, call _onLoadSettings.
    on<LoadSettings>(_onLoadSettings);
    // When an UpdateAccentColor event comes in, call _onUpdateAccentColor.
    on<UpdateAccentColor>(_onUpdateAccentColor);
    // When an UpdateFirstDayOfWeek event comes in, call _onUpdateFirstDayOfWeek.
    on<UpdateFirstDayOfWeek>(_onUpdateFirstDayOfWeek);
    // When an UpdateDefaultPriority event comes in, call _onUpdateDefaultPriority.
    on<UpdateDefaultPriority>(_onUpdateDefaultPriority);
  }

  // This method handles the `LoadSettings` event.
  // It fetches settings from the repository and updates the app's accent color.
  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      emit(const SettingsLoading()); // Indicate that settings are being loaded.
      await _repository.init(); // Make sure the repository is initialized.
      final settings = _repository.getSettings(); // Get the current settings.

      // Apply the loaded accent color to our global AppColors.
      AppColors.setAccentColor(settings.accentColor);

      emit(SettingsLoaded(settings)); // Emit the loaded settings state.
    } catch (e) {
      emit(SettingsError('Failed to load settings: ${e.toString()}')); // Handle any errors.
    }
  }

  // This method handles the `UpdateAccentColor` event.
  // It updates the accent color in settings and immediately applies it.
  Future<void> _onUpdateAccentColor(
    UpdateAccentColor event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final currentSettings = _getCurrentSettings(); // Get the current settings.
      // Create a new settings object with the updated accent color.
      final updatedSettings = currentSettings.copyWith(
        accentColor: event.colorHex,
      );

      // Immediately update the AppColors for instant UI feedback.
      AppColors.setAccentColor(event.colorHex);

      // Emit the updated settings state right away.
      emit(SettingsLoaded(updatedSettings));

      // Now, save the updated settings to persistent storage.
      final success = await _repository.saveSettings(updatedSettings);

      if (success) {
        // If saving was successful, emit a success message.
        emit(
          SettingsOperationSuccess(
            message: 'Accent color updated',
            settings: updatedSettings,
          ),
        );
        emit(SettingsLoaded(updatedSettings)); // Re-emit loaded state to ensure consistency.
      } else {
        // If saving failed, revert the accent color and emit an error.
        AppColors.setAccentColor(currentSettings.accentColor);
        emit(const SettingsError('Failed to save accent color'));
        emit(SettingsLoaded(currentSettings)); // Revert to previous state.
      }
    } catch (e) {
      emit(SettingsError('Color update failed: ${e.toString()}')); // Handle any exceptions.
    }
  }

  // This method handles the `UpdateFirstDayOfWeek` event.
  // It updates the setting for which day the week starts on.
  Future<void> _onUpdateFirstDayOfWeek(
    UpdateFirstDayOfWeek event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final currentSettings = _getCurrentSettings(); // Get current settings.
      // Create a new settings object with the updated first day of the week.
      final updatedSettings = currentSettings.copyWith(
        firstDayOfWeek: event.day,
      );

      // Save the updated settings to storage.
      final success = await _repository.saveSettings(updatedSettings);

      if (success) {
        // If successful, emit a success message and the new loaded state.
        emit(
          SettingsOperationSuccess(
            message:
                'First day of week updated to ${event.day == 'saturday' ? 'Saturday' : 'Monday'}',
            settings: updatedSettings,
          ),
        );
        emit(SettingsLoaded(updatedSettings));
      } else {
        emit(const SettingsError('Failed to update first day of week')); // Emit error on failure.
      }
    } catch (e) {
      emit(SettingsError('Update failed: ${e.toString()}')); // Handle any exceptions.
    }
  }

  // This method handles the `UpdateDefaultPriority` event.
  // It updates the default priority for new tasks.
  Future<void> _onUpdateDefaultPriority(
    UpdateDefaultPriority event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      // Use a generic helper to update and save the setting.
      final success = await _updateSetting(
        (settings) => settings.copyWith(defaultTaskPriority: event.priority),
      );

      if (success) {
        final settings = _repository.getSettings(); // Get the latest settings.
        // Emit a success message and the new loaded state.
        emit(
          SettingsOperationSuccess(
            message: 'Default priority updated to P${event.priority}',
            settings: settings,
          ),
        );
        emit(SettingsLoaded(settings));
      } else {
        emit(const SettingsError('Failed to update default priority')); // Emit error on failure.
      }
    } catch (e) {
      emit(SettingsError('Priority update failed: ${e.toString()}')); // Handle any exceptions.
    }
  }

  // Helper method to get the current settings, either from the bloc's state
  // or directly from the repository if the state isn't loaded yet.
  AppSettings _getCurrentSettings() {
    if (state is SettingsLoaded) {
      return (state as SettingsLoaded).settings;
    }
    return _repository.getSettings();
  }

  // A generic helper method to update a setting.
  // It takes a function that modifies the settings and then saves them.
  Future<bool> _updateSetting(AppSettings Function(AppSettings) updater) async {
    final currentSettings = _getCurrentSettings(); // Get the current settings.
    final updatedSettings = updater(currentSettings); // Apply the update function.
    return await _repository.saveSettings(updatedSettings); // Save the modified settings.
  }
}
