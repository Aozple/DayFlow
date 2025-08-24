import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/app_settings.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/settings_repository.dart';
import 'package:flutter/foundation.dart'; // For debug logging

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _repository;
  AppSettings? _cachedSettings; // Cache for settings to reduce repository calls

  SettingsBloc({required SettingsRepository repository})
    : _repository = repository,
      super(const SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateAccentColor>(_onUpdateAccentColor);
    on<UpdateFirstDayOfWeek>(_onUpdateFirstDayOfWeek);
    on<UpdateDefaultPriority>(_onUpdateDefaultPriority);
    on<UpdateNotificationEnabled>(_onUpdateNotificationEnabled);
    on<UpdateDefaultNotificationTime>(_onUpdateDefaultNotificationTime);
    on<UpdateNotificationSound>(_onUpdateNotificationSound);
    on<UpdateNotificationVibration>(_onUpdateNotificationVibration);
    on<ResetSettings>(_onResetSettings);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      emit(const SettingsLoading());
      
      // Initialize repository if not already initialized
      if (!_repository.isInitialized) {
        await _repository.init();
      }
      
      final settings = _repository.getSettings();
      _cachedSettings = settings; // Cache the settings
      
      // Apply the loaded accent color
      AppColors.setAccentColor(settings.accentColor);
      emit(SettingsLoaded(settings));
    } catch (e) {
      debugPrint('Failed to load settings: $e');
      emit(SettingsError('Failed to load settings: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateAccentColor(
    UpdateAccentColor event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final currentSettings = _getCurrentSettings();
      final updatedSettings = currentSettings.copyWith(accentColor: event.colorHex);
      
      // Apply color immediately for instant feedback
      AppColors.setAccentColor(event.colorHex);
      emit(SettingsLoaded(updatedSettings));
      
      // Save to persistent storage
      final success = await _repository.saveSettings(updatedSettings);
      if (success) {
        _cachedSettings = updatedSettings; // Update cache
        emit(SettingsOperationSuccess(
          message: 'Accent color updated',
          settings: updatedSettings,
        ));
      } else {
        // Revert on failure
        AppColors.setAccentColor(currentSettings.accentColor);
        emit(SettingsLoaded(currentSettings));
        emit(const SettingsError('Failed to save accent color'));
      }
    } catch (e) {
      debugPrint('Failed to update accent color: $e');
      emit(SettingsError('Color update failed: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateFirstDayOfWeek(
    UpdateFirstDayOfWeek event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final success = await _updateSetting(
        (settings) => settings.copyWith(firstDayOfWeek: event.day),
      );
      
      if (success) {
        final settings = _repository.getSettings();
        _cachedSettings = settings;
        emit(SettingsOperationSuccess(
          message: 'First day of week updated to ${event.day == 'saturday' ? 'Saturday' : 'Monday'}',
          settings: settings,
        ));
        emit(SettingsLoaded(settings));
      } else {
        emit(const SettingsError('Failed to update first day of week'));
      }
    } catch (e) {
      debugPrint('Failed to update first day of week: $e');
      emit(SettingsError('Update failed: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateDefaultPriority(
    UpdateDefaultPriority event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final success = await _updateSetting(
        (settings) => settings.copyWith(defaultTaskPriority: event.priority),
      );
      
      if (success) {
        final settings = _repository.getSettings();
        _cachedSettings = settings;
        emit(SettingsOperationSuccess(
          message: 'Default priority updated to P${event.priority}',
          settings: settings,
        ));
        emit(SettingsLoaded(settings));
      } else {
        emit(const SettingsError('Failed to update default priority'));
      }
    } catch (e) {
      debugPrint('Failed to update default priority: $e');
      emit(SettingsError('Priority update failed: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateNotificationEnabled(
    UpdateNotificationEnabled event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final success = await _updateSetting(
        (settings) => settings.copyWith(defaultNotificationEnabled: event.enabled),
      );
      
      if (success) {
        final settings = _repository.getSettings();
        _cachedSettings = settings;
        emit(SettingsOperationSuccess(
          message: 'Default reminder ${event.enabled ? 'enabled' : 'disabled'}',
          settings: settings,
        ));
        emit(SettingsLoaded(settings));
      } else {
        emit(const SettingsError('Failed to update notification setting'));
      }
    } catch (e) {
      debugPrint('Failed to update notification enabled: $e');
      emit(SettingsError('Update failed: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateDefaultNotificationTime(
    UpdateDefaultNotificationTime event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final success = await _updateSetting(
        (settings) => settings.copyWith(
          defaultNotificationMinutesBefore: event.minutesBefore,
        ),
      );
      
      if (success) {
        final settings = _repository.getSettings();
        _cachedSettings = settings;
        emit(SettingsOperationSuccess(
          message: 'Default reminder time updated',
          settings: settings,
        ));
        emit(SettingsLoaded(settings));
      } else {
        emit(const SettingsError('Failed to update reminder time'));
      }
    } catch (e) {
      debugPrint('Failed to update notification time: $e');
      emit(SettingsError('Update failed: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateNotificationSound(
    UpdateNotificationSound event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final success = await _updateSetting(
        (settings) => settings.copyWith(notificationSound: event.enabled),
      );
      
      if (success) {
        final settings = _repository.getSettings();
        _cachedSettings = settings;
        emit(SettingsOperationSuccess(
          message: 'Notification sound ${event.enabled ? 'enabled' : 'disabled'}',
          settings: settings,
        ));
        emit(SettingsLoaded(settings));
      } else {
        emit(const SettingsError('Failed to update sound setting'));
      }
    } catch (e) {
      debugPrint('Failed to update notification sound: $e');
      emit(SettingsError('Update failed: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateNotificationVibration(
    UpdateNotificationVibration event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final success = await _updateSetting(
        (settings) => settings.copyWith(notificationVibration: event.enabled),
      );
      
      if (success) {
        final settings = _repository.getSettings();
        _cachedSettings = settings;
        emit(SettingsOperationSuccess(
          message: 'Vibration ${event.enabled ? 'enabled' : 'disabled'}',
          settings: settings,
        ));
        emit(SettingsLoaded(settings));
      } else {
        emit(const SettingsError('Failed to update vibration setting'));
      }
    } catch (e) {
      debugPrint('Failed to update notification vibration: $e');
      emit(SettingsError('Update failed: ${e.toString()}'));
    }
  }

  // New event handler for resetting settings
  Future<void> _onResetSettings(
    ResetSettings event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      emit(const SettingsLoading());
      
      final defaultSettings = const AppSettings();
      final success = await _repository.saveSettings(defaultSettings);
      
      if (success) {
        _cachedSettings = defaultSettings;
        AppColors.setAccentColor(defaultSettings.accentColor);
        emit(SettingsOperationSuccess(
          message: 'Settings reset to defaults',
          settings: defaultSettings,
        ));
        emit(SettingsLoaded(defaultSettings));
      } else {
        emit(const SettingsError('Failed to reset settings'));
      }
    } catch (e) {
      debugPrint('Failed to reset settings: $e');
      emit(SettingsError('Reset failed: ${e.toString()}'));
    }
  }

  // Enhanced helper methods
  AppSettings _getCurrentSettings() {
    if (_cachedSettings != null) {
      return _cachedSettings!;
    }
    
    if (state is SettingsLoaded) {
      _cachedSettings = (state as SettingsLoaded).settings;
      return _cachedSettings!;
    }
    
    final settings = _repository.getSettings();
    _cachedSettings = settings;
    return settings;
  }

  Future<bool> _updateSetting(AppSettings Function(AppSettings) updater) async {
    try {
      final currentSettings = _getCurrentSettings();
      final updatedSettings = updater(currentSettings);
      return await _repository.saveSettings(updatedSettings);
    } catch (e) {
      debugPrint('Failed to update setting: $e');
      return false;
    }
  }
}