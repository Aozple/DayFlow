import 'dart:convert';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class SettingsRepository {
  static const String _tag = 'SettingsRepo';
  static const String _settingsKey = 'app_settings';

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  // Cache for settings
  AppSettings? _cachedSettings;
  DateTime? _lastCacheUpdate;
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Singleton pattern
  static final SettingsRepository _instance = SettingsRepository._internal();
  factory SettingsRepository() => _instance;
  SettingsRepository._internal();

  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized && _prefs != null) {
      DebugLogger.verbose('Already initialized', tag: _tag);
      return;
    }

    return DebugLogger.timeOperation('Initialize SettingsRepository', () async {
      try {
        _prefs = await SharedPreferences.getInstance();
        _isInitialized = true;
        DebugLogger.success('Settings repository initialized', tag: _tag);
      } catch (e) {
        DebugLogger.error(
          'Failed to initialize SharedPreferences',
          tag: _tag,
          error: e,
        );
        _isInitialized = false;
        rethrow;
      }
    });
  }

  bool _isCacheValid() {
    if (_cachedSettings == null || _lastCacheUpdate == null) return false;
    final age = DateTime.now().difference(_lastCacheUpdate!);
    return age < _cacheDuration;
  }

  void _invalidateCache() {
    _cachedSettings = null;
    _lastCacheUpdate = null;
    DebugLogger.verbose('Settings cache invalidated', tag: _tag);
  }

  AppSettings getSettings() {
    if (!_isInitialized || _prefs == null) {
      DebugLogger.warning(
        'Repository not initialized, returning defaults',
        tag: _tag,
      );
      return const AppSettings();
    }

    // Return cached if valid
    if (_isCacheValid() && _cachedSettings != null) {
      DebugLogger.verbose('Returning cached settings', tag: _tag);
      return _cachedSettings!;
    }

    try {
      final settingsJson = _prefs!.getString(_settingsKey);

      if (settingsJson != null) {
        DebugLogger.debug('Loading settings from storage', tag: _tag);

        final Map<String, dynamic> settingsMap = jsonDecode(settingsJson);
        final settings = AppSettings.fromMap(settingsMap);

        // Validate and fix if needed
        if (!settings.isValid()) {
          DebugLogger.warning(
            'Invalid settings detected, fixing...',
            tag: _tag,
          );
          final fixedSettings = _fixInvalidSettings(settings);

          // Save fixed settings
          saveSettings(fixedSettings).then((_) {
            DebugLogger.success('Fixed settings saved', tag: _tag);
          });

          _updateCache(fixedSettings);
          return fixedSettings;
        }

        _updateCache(settings);
        DebugLogger.success('Settings loaded', tag: _tag);
        return settings;
      }

      DebugLogger.info('No saved settings, using defaults', tag: _tag);
      const defaultSettings = AppSettings();
      _updateCache(defaultSettings);
      return defaultSettings;
    } catch (e) {
      DebugLogger.error('Error loading settings', tag: _tag, error: e);
      const fallback = AppSettings();
      _updateCache(fallback);
      return fallback;
    }
  }

  void _updateCache(AppSettings settings) {
    _cachedSettings = settings;
    _lastCacheUpdate = DateTime.now();
  }

  AppSettings _fixInvalidSettings(AppSettings settings) {
    return AppSettings(
      accentColor: AppSettings.validateHexColor(settings.accentColor),
      firstDayOfWeek: AppSettings.validateFirstDay(settings.firstDayOfWeek),
      defaultTaskPriority: AppSettings.validatePriority(
        settings.defaultTaskPriority,
      ),
      defaultNotificationEnabled: settings.defaultNotificationEnabled,
      defaultNotificationMinutesBefore: AppSettings.validateMinutesBefore(
        settings.defaultNotificationMinutesBefore,
      ),
      notificationSound: settings.notificationSound,
      notificationVibration: settings.notificationVibration,
    );
  }

  Future<bool> saveSettings(AppSettings settings) async {
    if (!_isInitialized || _prefs == null) {
      DebugLogger.warning(
        'Cannot save - repository not initialized',
        tag: _tag,
      );
      return false;
    }

    return DebugLogger.timeOperation('Save settings', () async {
      try {
        // Validate before saving
        if (!settings.isValid()) {
          DebugLogger.warning('Attempted to save invalid settings', tag: _tag);
          return false;
        }

        final settingsJson = jsonEncode(settings.toMap());
        final result = await _prefs!.setString(_settingsKey, settingsJson);

        if (result) {
          _updateCache(settings);
          DebugLogger.success('Settings saved', tag: _tag);
        } else {
          DebugLogger.error('Failed to save settings', tag: _tag);
        }

        return result;
      } catch (e) {
        DebugLogger.error('Error saving settings', tag: _tag, error: e);
        return false;
      }
    });
  }

  Future<bool> clearSettings() async {
    if (!_isInitialized || _prefs == null) {
      DebugLogger.warning(
        'Cannot clear - repository not initialized',
        tag: _tag,
      );
      return false;
    }

    return DebugLogger.timeOperation('Clear settings', () async {
      try {
        final result = await _prefs!.remove(_settingsKey);

        if (result) {
          _invalidateCache();
          DebugLogger.success('Settings cleared', tag: _tag);
        } else {
          DebugLogger.warning('Failed to clear settings', tag: _tag);
        }

        return result;
      } catch (e) {
        DebugLogger.error('Error clearing settings', tag: _tag, error: e);
        return false;
      }
    });
  }

  // Batch update for better performance
  Future<bool> updateMultiple(Map<String, dynamic> updates) async {
    return DebugLogger.timeOperation('Batch update settings', () async {
      try {
        var currentSettings = getSettings();

        updates.forEach((key, value) {
          switch (key) {
            case 'accentColor':
              currentSettings = currentSettings.copyWith(
                accentColor: value as String,
              );
              break;
            case 'firstDayOfWeek':
              currentSettings = currentSettings.copyWith(
                firstDayOfWeek: value as String,
              );
              break;
            case 'defaultTaskPriority':
              currentSettings = currentSettings.copyWith(
                defaultTaskPriority: value as int,
              );
              break;
            case 'defaultNotificationEnabled':
              currentSettings = currentSettings.copyWith(
                defaultNotificationEnabled: value as bool,
              );
              break;
            case 'defaultNotificationMinutesBefore':
              currentSettings = currentSettings.copyWith(
                defaultNotificationMinutesBefore: value as int,
              );
              break;
            case 'notificationSound':
              currentSettings = currentSettings.copyWith(
                notificationSound: value as bool,
              );
              break;
            case 'notificationVibration':
              currentSettings = currentSettings.copyWith(
                notificationVibration: value as bool,
              );
              break;
          }
        });

        final result = await saveSettings(currentSettings);
        DebugLogger.success(
          'Batch update completed',
          tag: _tag,
          data: '${updates.length} fields',
        );
        return result;
      } catch (e) {
        DebugLogger.error('Batch update failed', tag: _tag, error: e);
        return false;
      }
    });
  }

  Future<bool> updateAccentColor(String colorHex) async {
    try {
      final validatedColor = AppSettings.validateHexColor(colorHex);
      final currentSettings = getSettings();
      final updatedSettings = currentSettings.copyWith(
        accentColor: validatedColor,
      );

      DebugLogger.info(
        'Updating accent color',
        tag: _tag,
        data: validatedColor,
      );
      return await saveSettings(updatedSettings);
    } catch (e) {
      DebugLogger.error('Error updating accent color', tag: _tag, error: e);
      return false;
    }
  }

  Future<bool> updateFirstDayOfWeek(String day) async {
    try {
      final validatedDay = AppSettings.validateFirstDay(day);
      final currentSettings = getSettings();
      final updatedSettings = currentSettings.copyWith(
        firstDayOfWeek: validatedDay,
      );

      DebugLogger.info(
        'Updating first day of week',
        tag: _tag,
        data: validatedDay,
      );
      return await saveSettings(updatedSettings);
    } catch (e) {
      DebugLogger.error(
        'Error updating first day of week',
        tag: _tag,
        error: e,
      );
      return false;
    }
  }

  Future<bool> updateDefaultPriority(int priority) async {
    try {
      final validatedPriority = AppSettings.validatePriority(priority);
      final currentSettings = getSettings();
      final updatedSettings = currentSettings.copyWith(
        defaultTaskPriority: validatedPriority,
      );

      DebugLogger.info(
        'Updating default priority',
        tag: _tag,
        data: validatedPriority,
      );
      return await saveSettings(updatedSettings);
    } catch (e) {
      DebugLogger.error('Error updating default priority', tag: _tag, error: e);
      return false;
    }
  }

  String exportSettings() {
    try {
      final settings = getSettings();
      if (!settings.isValid()) {
        DebugLogger.warning('Cannot export invalid settings', tag: _tag);
        return '{}';
      }

      final json = jsonEncode(settings.toMap());
      DebugLogger.success(
        'Settings exported',
        tag: _tag,
        data: '${json.length} chars',
      );
      return json;
    } catch (e) {
      DebugLogger.error('Error exporting settings', tag: _tag, error: e);
      return '{}';
    }
  }

  Future<bool> importSettings(String jsonString) async {
    return DebugLogger.timeOperation('Import settings', () async {
      try {
        final Map<String, dynamic> settingsMap = jsonDecode(jsonString);
        final settings = AppSettings.fromMap(settingsMap);

        if (!settings.isValid()) {
          DebugLogger.warning('Imported settings are invalid', tag: _tag);
          return false;
        }

        final result = await saveSettings(settings);
        if (result) {
          DebugLogger.success('Settings imported', tag: _tag);
        }
        return result;
      } catch (e) {
        DebugLogger.error('Error importing settings', tag: _tag, error: e);
        return false;
      }
    });
  }

  // Get service status for debugging
  Map<String, dynamic> getStatus() {
    return {
      'initialized': _isInitialized,
      'hasPrefs': _prefs != null,
      'cacheValid': _isCacheValid(),
      'cacheAge':
          _lastCacheUpdate != null
              ? DateTime.now().difference(_lastCacheUpdate!).inSeconds
              : null,
      'currentSettings': _cachedSettings?.toMap(),
    };
  }
}
