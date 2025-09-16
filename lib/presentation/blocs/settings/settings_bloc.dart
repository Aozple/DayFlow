import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:dayflow/data/models/app_settings.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/settings_repository.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  static const String _tag = 'SettingsBloc';

  final SettingsRepository _repository;
  AppSettings? _cachedSettings;

  // Prevent duplicate operations
  bool _isProcessing = false;

  // Debounce timer for rapid updates
  DateTime? _lastUpdateTime;
  static const Duration _updateDebounce = Duration(milliseconds: 300);

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
    on<BatchUpdateSettings>(_onBatchUpdateSettings);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    if (_isProcessing) {
      DebugLogger.warning('Load already in progress', tag: _tag);
      return;
    }

    _isProcessing = true;

    try {
      DebugLogger.info('Loading settings', tag: _tag);
      emit(const SettingsLoading());

      // Initialize repository if needed
      if (!_repository.isInitialized) {
        await _repository.init();
      }

      final settings = _repository.getSettings();
      _cachedSettings = settings;

      // Apply accent color
      AppColors.setAccentColor(settings.accentColor);

      DebugLogger.success(
        'Settings loaded',
        tag: _tag,
        data: {
          'accentColor': settings.accentColor,
          'firstDay': settings.firstDayOfWeek,
          'defaultPriority': settings.defaultTaskPriority,
        },
      );

      emit(SettingsLoaded(settings));
    } catch (e) {
      DebugLogger.error('Failed to load settings', tag: _tag, error: e);
      emit(SettingsError('Failed to load settings: ${e.toString()}'));

      // Emit default settings after error
      await Future.delayed(const Duration(seconds: 1));
      emit(const SettingsLoaded(AppSettings()));
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _onUpdateAccentColor(
    UpdateAccentColor event,
    Emitter<SettingsState> emit,
  ) async {
    if (_shouldDebounce()) {
      DebugLogger.verbose('Debouncing accent color update', tag: _tag);
      return;
    }

    await _updateSingleSetting(
      emit,
      settingName: 'accent color',
      updater: (settings) => settings.copyWith(accentColor: event.colorHex),
      onSuccess: (settings) {
        AppColors.setAccentColor(settings.accentColor);
        DebugLogger.success(
          'Accent color updated',
          tag: _tag,
          data: settings.accentColor,
        );
      },
      onError: (currentSettings) {
        // Revert color on failure
        AppColors.setAccentColor(currentSettings.accentColor);
      },
    );
  }

  Future<void> _onUpdateFirstDayOfWeek(
    UpdateFirstDayOfWeek event,
    Emitter<SettingsState> emit,
  ) async {
    await _updateSingleSetting(
      emit,
      settingName: 'first day of week',
      updater: (settings) => settings.copyWith(firstDayOfWeek: event.day),
      successMessage: 'First day updated to ${event.day}',
    );
  }

  Future<void> _onUpdateDefaultPriority(
    UpdateDefaultPriority event,
    Emitter<SettingsState> emit,
  ) async {
    await _updateSingleSetting(
      emit,
      settingName: 'default priority',
      updater:
          (settings) => settings.copyWith(defaultTaskPriority: event.priority),
      successMessage: 'Default priority updated to P${event.priority}',
    );
  }

  Future<void> _onUpdateNotificationEnabled(
    UpdateNotificationEnabled event,
    Emitter<SettingsState> emit,
  ) async {
    await _updateSingleSetting(
      emit,
      settingName: 'notification enabled',
      updater:
          (settings) =>
              settings.copyWith(defaultNotificationEnabled: event.enabled),
      successMessage:
          'Default reminder ${event.enabled ? "enabled" : "disabled"}',
    );
  }

  Future<void> _onUpdateDefaultNotificationTime(
    UpdateDefaultNotificationTime event,
    Emitter<SettingsState> emit,
  ) async {
    await _updateSingleSetting(
      emit,
      settingName: 'notification time',
      updater:
          (settings) => settings.copyWith(
            defaultNotificationMinutesBefore: event.minutesBefore,
          ),
      successMessage: 'Default reminder time updated',
    );
  }

  Future<void> _onUpdateNotificationSound(
    UpdateNotificationSound event,
    Emitter<SettingsState> emit,
  ) async {
    await _updateSingleSetting(
      emit,
      settingName: 'notification sound',
      updater:
          (settings) => settings.copyWith(notificationSound: event.enabled),
      successMessage:
          'Notification sound ${event.enabled ? "enabled" : "disabled"}',
    );
  }

  Future<void> _onUpdateNotificationVibration(
    UpdateNotificationVibration event,
    Emitter<SettingsState> emit,
  ) async {
    await _updateSingleSetting(
      emit,
      settingName: 'notification vibration',
      updater:
          (settings) => settings.copyWith(notificationVibration: event.enabled),
      successMessage: 'Vibration ${event.enabled ? "enabled" : "disabled"}',
    );
  }

  Future<void> _onBatchUpdateSettings(
    BatchUpdateSettings event,
    Emitter<SettingsState> emit,
  ) async {
    if (_isProcessing) {
      DebugLogger.warning('Update already in progress', tag: _tag);
      return;
    }

    _isProcessing = true;

    try {
      DebugLogger.info(
        'Batch updating settings',
        tag: _tag,
        data: event.updates.keys.toList(),
      );

      final success = await _repository.updateMultiple(event.updates);

      if (success) {
        final settings = _repository.getSettings();
        _cachedSettings = settings;

        // Apply accent color if it was updated
        if (event.updates.containsKey('accentColor')) {
          AppColors.setAccentColor(settings.accentColor);
        }

        emit(
          SettingsOperationSuccess(
            message: 'Settings updated',
            operation: SettingsOperation.save,
            settings: settings,
          ),
        );
        emit(SettingsLoaded(settings));

        DebugLogger.success('Batch update completed', tag: _tag);
      } else {
        throw Exception('Batch update failed');
      }
    } catch (e) {
      DebugLogger.error('Failed to batch update settings', tag: _tag, error: e);
      emit(SettingsError('Update failed: ${e.toString()}'));
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _onResetSettings(
    ResetSettings event,
    Emitter<SettingsState> emit,
  ) async {
    if (_isProcessing) {
      DebugLogger.warning('Operation in progress', tag: _tag);
      return;
    }

    _isProcessing = true;

    try {
      DebugLogger.info('Resetting settings to defaults', tag: _tag);
      emit(const SettingsLoading());

      const defaultSettings = AppSettings();
      final success = await _repository.saveSettings(defaultSettings);

      if (success) {
        _cachedSettings = defaultSettings;
        AppColors.setAccentColor(defaultSettings.accentColor);

        emit(
          const SettingsOperationSuccess(
            message: 'Settings reset to defaults',
            operation: SettingsOperation.reset,
            settings: defaultSettings,
          ),
        );
        emit(const SettingsLoaded(defaultSettings));

        DebugLogger.success('Settings reset completed', tag: _tag);
      } else {
        throw Exception('Failed to reset settings');
      }
    } catch (e) {
      DebugLogger.error('Failed to reset settings', tag: _tag, error: e);
      emit(SettingsError('Reset failed: ${e.toString()}'));
    } finally {
      _isProcessing = false;
    }
  }

  // Helper method for single setting updates
  Future<void> _updateSingleSetting(
    Emitter<SettingsState> emit, {
    required String settingName,
    required AppSettings Function(AppSettings) updater,
    String? successMessage,
    void Function(AppSettings)? onSuccess,
    void Function(AppSettings)? onError,
  }) async {
    if (_isProcessing) {
      DebugLogger.warning('Update already in progress', tag: _tag);
      return;
    }

    _isProcessing = true;
    _lastUpdateTime = DateTime.now();

    try {
      DebugLogger.info('Updating $settingName', tag: _tag);

      final currentSettings = _getCurrentSettings();
      final updatedSettings = updater(currentSettings);

      // Optimistic update
      _cachedSettings = updatedSettings;
      emit(SettingsLoaded(updatedSettings));

      // Save to persistent storage
      final success = await _repository.saveSettings(updatedSettings);

      if (success) {
        onSuccess?.call(updatedSettings);

        emit(
          SettingsOperationSuccess(
            message: successMessage ?? '$settingName updated',
            operation: SettingsOperation.save,
            settings: updatedSettings,
          ),
        );
        emit(SettingsLoaded(updatedSettings));
      } else {
        // Revert on failure
        _cachedSettings = currentSettings;
        onError?.call(currentSettings);
        emit(SettingsLoaded(currentSettings));
        emit(SettingsError('Failed to save $settingName'));
      }
    } catch (e) {
      DebugLogger.error('Failed to update $settingName', tag: _tag, error: e);
      emit(SettingsError('$settingName update failed: ${e.toString()}'));
    } finally {
      _isProcessing = false;
    }
  }

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

  bool _shouldDebounce() {
    if (_lastUpdateTime == null) return false;

    final timeSinceLastUpdate = DateTime.now().difference(_lastUpdateTime!);
    return timeSinceLastUpdate < _updateDebounce;
  }

  @override
  Future<void> close() {
    DebugLogger.info('Closing SettingsBloc', tag: _tag);
    return super.close();
  }
}
