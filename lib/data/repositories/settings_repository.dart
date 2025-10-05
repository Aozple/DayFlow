import 'dart:convert';
import 'package:dayflow/core/utils/color_utils.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:dayflow/data/repositories/interfaces/settings_repository_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class SettingsRepository implements ISettingsRepository {
  static const String _tag = 'SettingsRepo';
  static const String _settingsKey = 'app_settings';

  SharedPreferences? _prefs;
  bool _isInitialized = false;
  AppSettings? _cachedSettings;
  DateTime? _lastCacheUpdate;
  static const Duration _cacheDuration = Duration(minutes: 5);

  SettingsRepository();

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> init() async {
    if (_isInitialized && _prefs != null) {
      DebugLogger.verbose('Already initialized', tag: _tag);
      return;
    }

    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      DebugLogger.success('Settings repository initialized', tag: _tag);
    } catch (e) {
      DebugLogger.error('Failed to initialize', tag: _tag, error: e);
      _isInitialized = false;
      rethrow;
    }
  }

  bool _isCacheValid() {
    if (_cachedSettings == null || _lastCacheUpdate == null) return false;
    final age = DateTime.now().difference(_lastCacheUpdate!);
    return age < _cacheDuration;
  }

  void _updateCache(AppSettings settings) {
    _cachedSettings = settings;
    _lastCacheUpdate = DateTime.now();
  }

  void _invalidateCache() {
    _cachedSettings = null;
    _lastCacheUpdate = null;
  }

  @override
  AppSettings getSettings() {
    if (!_isInitialized || _prefs == null) {
      DebugLogger.warning('Not initialized, returning defaults', tag: _tag);
      return const AppSettings();
    }

    if (_isCacheValid() && _cachedSettings != null) {
      DebugLogger.verbose('Returning cached settings', tag: _tag);
      return _cachedSettings!;
    }

    try {
      final settingsJson = _prefs!.getString(_settingsKey);

      if (settingsJson != null) {
        final Map<String, dynamic> settingsMap = jsonDecode(settingsJson);
        final settings = AppSettings.fromMap(settingsMap);

        if (!settings.isValid()) {
          DebugLogger.warning('Invalid settings, fixing', tag: _tag);
          final fixed = _fixInvalidSettings(settings);
          saveSettings(fixed);
          _updateCache(fixed);
          return fixed;
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

  AppSettings _fixInvalidSettings(AppSettings settings) {
    return AppSettings(
      accentColor: ColorUtils.validateHexWithFallback(
        settings.accentColor,
        AppSettings.defaultAccentColor,
      ),
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

  @override
  Future<bool> saveSettings(AppSettings settings) async {
    if (!_isInitialized || _prefs == null) {
      DebugLogger.warning('Cannot save - not initialized', tag: _tag);
      return false;
    }

    try {
      if (!settings.isValid()) {
        DebugLogger.warning('Invalid settings', tag: _tag);
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
  }

  @override
  Future<bool> clearSettings() async {
    if (!_isInitialized || _prefs == null) {
      DebugLogger.warning('Cannot clear - not initialized', tag: _tag);
      return false;
    }

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
  }

  @override
  Future<bool> updateMultiple(Map<String, dynamic> updates) async {
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
      DebugLogger.success('Batch update completed', tag: _tag);
      return result;
    } catch (e) {
      DebugLogger.error('Batch update failed', tag: _tag, error: e);
      return false;
    }
  }

  @override
  Future<bool> updateAccentColor(String colorHex) async {
    final currentSettings = getSettings();
    final updated = currentSettings.copyWith(accentColor: colorHex);
    return await saveSettings(updated);
  }

  @override
  Future<bool> updateFirstDayOfWeek(String day) async {
    final currentSettings = getSettings();
    final updated = currentSettings.copyWith(firstDayOfWeek: day);
    return await saveSettings(updated);
  }

  @override
  Future<bool> updateDefaultPriority(int priority) async {
    final currentSettings = getSettings();
    final updated = currentSettings.copyWith(defaultTaskPriority: priority);
    return await saveSettings(updated);
  }

  @override
  String exportSettings() {
    try {
      final settings = getSettings();
      return jsonEncode(settings.toMap());
    } catch (e) {
      DebugLogger.error('Error exporting settings', tag: _tag, error: e);
      return '{}';
    }
  }

  @override
  Future<bool> importSettings(String jsonString) async {
    try {
      final Map<String, dynamic> settingsMap = jsonDecode(jsonString);
      final settings = AppSettings.fromMap(settingsMap);

      if (!settings.isValid()) {
        DebugLogger.warning('Imported settings invalid', tag: _tag);
        return false;
      }

      return await saveSettings(settings);
    } catch (e) {
      DebugLogger.error('Error importing settings', tag: _tag, error: e);
      return false;
    }
  }

  @override
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
