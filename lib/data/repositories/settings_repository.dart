import 'dart:convert';
import 'package:dayflow/core/constants/app_constants.dart';
import 'package:dayflow/core/utils/app_color_utils.dart';
import 'package:dayflow/core/utils/app_date_utils.dart';
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
  static const Duration _cacheDuration = AppConstants.defaultCacheDuration;

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

    final age = AppDateUtils.now.difference(_lastCacheUpdate!);

    if (age > _cacheDuration) {
      DebugLogger.verbose(
        'Cache expired',
        tag: _tag,
        data: '${age.inSeconds}s old',
      );
      return false;
    }

    if (age > const Duration(minutes: 5)) {
      DebugLogger.warning('Cache too old, forcing refresh', tag: _tag);
      _invalidateCache();
      return false;
    }

    return true;
  }

  void _updateCache(AppSettings settings) {
    _cachedSettings = settings;
    _lastCacheUpdate = AppDateUtils.now;
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
      accentColor: AppColorUtils.validateHexWithFallback(
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
    return await _executeWithErrorHandling('save settings', () async {
      if (!settings.isValid()) {
        DebugLogger.warning('Invalid settings', tag: _tag);
        return false;
      }

      final settingsJson = jsonEncode(settings.toMap());
      final result = await _prefs!.setString(_settingsKey, settingsJson);

      if (result) {
        _updateCache(settings);
        DebugLogger.success('Settings saved', tag: _tag);
      }

      return result;
    });
  }

  @override
  Future<bool> clearSettings() async {
    return await _executeWithErrorHandling('clear settings', () async {
      final result = await _prefs!.remove(_settingsKey);

      if (result) {
        _invalidateCache();
        DebugLogger.success('Settings cleared', tag: _tag);
      }

      return result;
    });
  }

  @override
  Future<bool> updateMultiple(Map<String, dynamic> updates) async {
    return await _executeWithErrorHandling('batch update', () async {
      var currentSettings = getSettings();

      for (final entry in updates.entries) {
        switch (entry.key) {
          case 'accentColor':
            currentSettings = currentSettings.copyWith(
              accentColor: entry.value as String,
            );
            break;
          case 'firstDayOfWeek':
            currentSettings = currentSettings.copyWith(
              firstDayOfWeek: entry.value as String,
            );
            break;
          case 'defaultTaskPriority':
            currentSettings = currentSettings.copyWith(
              defaultTaskPriority: entry.value as int,
            );
            break;
          case 'defaultNotificationEnabled':
            currentSettings = currentSettings.copyWith(
              defaultNotificationEnabled: entry.value as bool,
            );
            break;
          case 'defaultNotificationMinutesBefore':
            currentSettings = currentSettings.copyWith(
              defaultNotificationMinutesBefore: entry.value as int,
            );
            break;
          case 'notificationSound':
            currentSettings = currentSettings.copyWith(
              notificationSound: entry.value as bool,
            );
            break;
          case 'notificationVibration':
            currentSettings = currentSettings.copyWith(
              notificationVibration: entry.value as bool,
            );
            break;
          default:
            DebugLogger.warning(
              'Unknown setting field: ${entry.key}',
              tag: _tag,
            );
        }
      }

      final result = await saveSettings(currentSettings);
      DebugLogger.success(
        'Batch update completed',
        tag: _tag,
        data: '${updates.length} fields',
      );
      return result;
    });
  }

  Future<bool> _updateSingleField(String field, dynamic value) async {
    return await updateMultiple({field: value});
  }

  @override
  Future<bool> updateAccentColor(String colorHex) =>
      _updateSingleField('accentColor', colorHex);

  @override
  Future<bool> updateFirstDayOfWeek(String day) =>
      _updateSingleField('firstDayOfWeek', day);

  @override
  Future<bool> updateDefaultPriority(int priority) =>
      _updateSingleField('defaultTaskPriority', priority);

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
    return await _executeWithErrorHandling('import settings', () async {
      final Map<String, dynamic> settingsMap = jsonDecode(jsonString);
      final settings = AppSettings.fromMap(settingsMap);

      if (!settings.isValid()) {
        DebugLogger.warning('Imported settings invalid', tag: _tag);
        return false;
      }

      return await saveSettings(settings);
    });
  }

  @override
  Map<String, dynamic> getStatus() {
    return {
      'initialized': _isInitialized,
      'hasPrefs': _prefs != null,
      'cacheValid': _isCacheValid(),
      'cacheAge':
          _lastCacheUpdate != null
              ? AppDateUtils.now.difference(_lastCacheUpdate!).inSeconds
              : null,
      'currentSettings': _cachedSettings?.toMap(),
    };
  }

  Future<bool> _executeWithErrorHandling(
    String operation,
    Future<bool> Function() action,
  ) async {
    if (!_isInitialized || _prefs == null) {
      DebugLogger.warning('Cannot $operation - not initialized', tag: _tag);

      try {
        await init();
        if (!_isInitialized || _prefs == null) {
          return false;
        }
      } catch (e) {
        DebugLogger.error(
          'Re-init failed during $operation',
          tag: _tag,
          error: e,
        );
        return false;
      }
    }

    try {
      return await action();
    } catch (e) {
      DebugLogger.error('Error during $operation', tag: _tag, error: e);

      if (e.toString().contains('SharedPreferences')) {
        _isInitialized = false;
        _prefs = null;
        _invalidateCache();
      }

      return false;
    }
  }
}
