import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import 'package:flutter/foundation.dart'; // For debug logging

class SettingsRepository {
  static const String _settingsKey = 'app_settings';
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // Initialize the repository with SharedPreferences
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize SharedPreferences: $e');
      rethrow;
    }
  }

  // Get current app settings with validation
  AppSettings getSettings() {
    if (!_isInitialized) {
      debugPrint('Warning: SettingsRepository not initialized');
      return const AppSettings();
    }

    try {
      final settingsJson = _prefs.getString(_settingsKey);
      if (settingsJson != null) {
        final Map<String, dynamic> settingsMap = jsonDecode(settingsJson);
        final settings = AppSettings.fromMap(settingsMap);

        // Auto-fix invalid settings
        if (!settings.isValid()) {
          debugPrint('Invalid settings detected, using defaults');
          final fixedSettings = _fixInvalidSettings(settings);
          saveSettings(fixedSettings);
          return fixedSettings;
        }

        return settings;
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }

    return const AppSettings();
  }

  // Fix invalid settings with default values
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

  // Save settings with validation
  Future<bool> saveSettings(AppSettings settings) async {
    if (!_isInitialized) {
      debugPrint('Warning: SettingsRepository not initialized');
      return false;
    }

    try {
      // Validate before saving
      if (!settings.isValid()) {
        debugPrint('Attempted to save invalid settings');
        return false;
      }

      final settingsJson = jsonEncode(settings.toMap());
      final result = await _prefs.setString(_settingsKey, settingsJson);

      if (result) {
        debugPrint('Settings saved successfully');
      } else {
        debugPrint('Failed to save settings');
      }

      return result;
    } catch (e) {
      debugPrint('Error saving settings: $e');
      return false;
    }
  }

  // Reset settings to default
  Future<bool> clearSettings() async {
    if (!_isInitialized) {
      debugPrint('Warning: SettingsRepository not initialized');
      return false;
    }

    try {
      final result = await _prefs.remove(_settingsKey);
      if (result) {
        debugPrint('Settings cleared successfully');
      } else {
        debugPrint('Failed to clear settings');
      }
      return result;
    } catch (e) {
      debugPrint('Error clearing settings: $e');
      return false;
    }
  }

  // Update accent color with validation
  Future<bool> updateAccentColor(String colorHex) async {
    try {
      final validatedColor = AppSettings.validateHexColor(colorHex);
      final currentSettings = getSettings();
      final updatedSettings = currentSettings.copyWith(
        accentColor: validatedColor,
      );
      return await saveSettings(updatedSettings);
    } catch (e) {
      debugPrint('Error updating accent color: $e');
      return false;
    }
  }

  // Update first day of week with validation
  Future<bool> updateFirstDayOfWeek(String day) async {
    try {
      final validatedDay = AppSettings.validateFirstDay(day);
      final currentSettings = getSettings();
      final updatedSettings = currentSettings.copyWith(
        firstDayOfWeek: validatedDay,
      );
      return await saveSettings(updatedSettings);
    } catch (e) {
      debugPrint('Error updating first day of week: $e');
      return false;
    }
  }

  // Update default priority with validation
  Future<bool> updateDefaultPriority(int priority) async {
    try {
      final validatedPriority = AppSettings.validatePriority(priority);
      final currentSettings = getSettings();
      final updatedSettings = currentSettings.copyWith(
        defaultTaskPriority: validatedPriority,
      );
      return await saveSettings(updatedSettings);
    } catch (e) {
      debugPrint('Error updating default priority: $e');
      return false;
    }
  }

  // Export settings as JSON string
  String exportSettings() {
    try {
      final settings = getSettings();
      if (!settings.isValid()) {
        debugPrint('Cannot export invalid settings');
        return '{}';
      }
      return jsonEncode(settings.toMap());
    } catch (e) {
      debugPrint('Error exporting settings: $e');
      return '{}';
    }
  }

  // Import settings from JSON string
  Future<bool> importSettings(String jsonString) async {
    try {
      final Map<String, dynamic> settingsMap = jsonDecode(jsonString);
      final settings = AppSettings.fromMap(settingsMap);

      if (!settings.isValid()) {
        debugPrint('Imported settings are invalid');
        return false;
      }

      return await saveSettings(settings);
    } catch (e) {
      debugPrint('Error importing settings: $e');
      return false;
    }
  }

  // Check if repository is initialized
  bool get isInitialized => _isInitialized;
}
