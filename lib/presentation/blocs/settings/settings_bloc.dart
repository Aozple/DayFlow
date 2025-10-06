import 'package:dayflow/core/utils/app_date_utils.dart';
import 'package:dayflow/data/models/app_settings.dart';
import 'package:dayflow/data/repositories/settings_repository.dart';
import 'package:dayflow/presentation/blocs/base/base_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends BaseBloc<SettingsEvent, SettingsState> {
  final SettingsRepository _repository = GetIt.I<SettingsRepository>();
  AppSettings? _cachedSettings;
  DateTime? _lastUpdateTime;
  static const Duration _updateDebounce = Duration(milliseconds: 300);

  SettingsBloc()
    : super(tag: 'SettingsBloc', initialState: const SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateAccentColor>(_onUpdateAnySetting);
    on<UpdateFirstDayOfWeek>(_onUpdateAnySetting);
    on<UpdateDefaultPriority>(_onUpdateAnySetting);
    on<UpdateNotificationEnabled>(_onUpdateAnySetting);
    on<UpdateDefaultNotificationTime>(_onUpdateAnySetting);
    on<UpdateNotificationSound>(_onUpdateAnySetting);
    on<UpdateNotificationVibration>(_onUpdateAnySetting);
    on<ResetSettings>(_onResetSettings);
    on<BatchUpdateSettings>(_onBatchUpdateSettings);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    if (!canProcess()) return;

    await performOperation(
      operationName: 'Load Settings',
      operation: () async {
        if (!_repository.isInitialized) {
          await _repository.init();
        }

        final settings = _repository.getSettings();
        _cachedSettings = settings;

        return settings;
      },
      emit: emit,
      loadingState: const SettingsLoading(),
      successState: (settings) => SettingsLoaded(settings),
      errorState: (error) => const SettingsLoaded(AppSettings()),
      fallbackState: const SettingsLoaded(AppSettings()),
    );
  }

  Future<void> _onUpdateAnySetting(
    SettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (_shouldDebounce()) {
      logVerbose('Debouncing update');
      return;
    }

    if (event is UpdateAccentColor) {
      await _updateSingleSetting(
        emit,
        settingName: 'accent color',
        updater: (settings) => settings.copyWith(accentColor: event.colorHex),
        onSuccess: (settings) {
          logSuccess('Accent color updated to ${settings.accentColor}');
        },
      );
    } else if (event is UpdateFirstDayOfWeek) {
      await _updateSingleSetting(
        emit,
        settingName: 'first day of week',
        updater: (settings) => settings.copyWith(firstDayOfWeek: event.day),
      );
    } else if (event is UpdateDefaultPriority) {
      await _updateSingleSetting(
        emit,
        settingName: 'default priority',
        updater:
            (settings) =>
                settings.copyWith(defaultTaskPriority: event.priority),
      );
    } else if (event is UpdateNotificationEnabled) {
      await _updateSingleSetting(
        emit,
        settingName: 'notification enabled',
        updater:
            (settings) =>
                settings.copyWith(defaultNotificationEnabled: event.enabled),
      );
    } else if (event is UpdateDefaultNotificationTime) {
      await _updateSingleSetting(
        emit,
        settingName: 'notification time',
        updater:
            (settings) => settings.copyWith(
              defaultNotificationMinutesBefore: event.minutesBefore,
            ),
      );
    } else if (event is UpdateNotificationSound) {
      await _updateSingleSetting(
        emit,
        settingName: 'notification sound',
        updater:
            (settings) => settings.copyWith(notificationSound: event.enabled),
      );
    } else if (event is UpdateNotificationVibration) {
      await _updateSingleSetting(
        emit,
        settingName: 'notification vibration',
        updater:
            (settings) =>
                settings.copyWith(notificationVibration: event.enabled),
      );
    }
  }

  Future<void> _onBatchUpdateSettings(
    BatchUpdateSettings event,
    Emitter<SettingsState> emit,
  ) async {
    if (!canProcess()) return;

    await performOperation(
      operationName: 'Batch Update Settings',
      operation: () async {
        final success = await _repository.updateMultiple(event.updates);

        if (!success) {
          throw Exception('Batch update failed');
        }

        final settings = _repository.getSettings();
        _cachedSettings = settings;
        return settings;
      },
      emit: emit,
      successState: (settings) => SettingsLoaded(settings),
      errorState: (error) => const SettingsError('Batch update failed'),
      fallbackState: state,
    );
  }

  Future<void> _onResetSettings(
    ResetSettings event,
    Emitter<SettingsState> emit,
  ) async {
    if (!canProcess()) return;

    await performOperation(
      operationName: 'Reset Settings',
      operation: () async {
        const defaultSettings = AppSettings();
        final success = await _repository.saveSettings(defaultSettings);

        if (!success) {
          throw Exception('Reset failed');
        }

        _cachedSettings = defaultSettings;

        return defaultSettings;
      },
      emit: emit,
      loadingState: const SettingsLoading(),
      successState: (settings) => SettingsLoaded(settings),
      errorState: (error) => const SettingsError('Reset failed'),
    );
  }

  Future<void> _updateSingleSetting(
    Emitter<SettingsState> emit, {
    required String settingName,
    required AppSettings Function(AppSettings) updater,
    void Function(AppSettings)? onSuccess,
    void Function(AppSettings)? onError,
  }) async {
    if (!canProcess()) return;

    _lastUpdateTime = AppDateUtils.now;

    await performOperation(
      operationName: 'Update $settingName',
      operation: () async {
        final currentSettings = _getCurrentSettings();
        final updatedSettings = updater(currentSettings);
        _cachedSettings = updatedSettings;

        final success = await _repository.saveSettings(updatedSettings);

        if (!success) {
          _cachedSettings = currentSettings;
          onError?.call(currentSettings);
          throw Exception('Failed to save $settingName');
        }

        onSuccess?.call(updatedSettings);
        return updatedSettings;
      },
      emit: emit,
      successState: (settings) => SettingsLoaded(settings),
      errorState: (error) => SettingsError('Failed to update $settingName'),
    );
  }

  AppSettings _getCurrentSettings() {
    if (_cachedSettings != null) {
      final cacheAge = AppDateUtils.now.difference(
        _lastUpdateTime ?? AppDateUtils.now,
      );
      if (cacheAge > const Duration(minutes: 5)) {
        _cachedSettings = null;
      }
    }

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
    final timeSinceLastUpdate = AppDateUtils.now.difference(_lastUpdateTime!);
    return timeSinceLastUpdate < _updateDebounce;
  }

  @override
  Future<void> close() {
    _cachedSettings = null;
    _lastUpdateTime = null;
    return super.close();
  }
}
