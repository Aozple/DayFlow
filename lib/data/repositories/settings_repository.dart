import 'dart:convert'; // For encoding and decoding JSON.
import 'package:shared_preferences/shared_preferences.dart'; // For local key-value storage.
import '../models/app_settings.dart'; // Our custom settings model.

// This class handles saving and loading application settings using SharedPreferences.
// It acts as a data layer for user preferences.
class SettingsRepository {
  // The key under which our settings JSON will be stored in SharedPreferences.
  static const String _settingsKey = 'app_settings';
  // An instance of SharedPreferences to interact with local storage.
  late SharedPreferences _prefs;

  // Initializes SharedPreferences. This must be called before using other methods.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Retrieves the current application settings.
  // If no settings are found or an error occurs, it returns default settings.
  AppSettings getSettings() {
    try {
      final settingsJson = _prefs.getString(_settingsKey); // Try to get the settings JSON string.
      if (settingsJson != null) {
        // If found, decode the JSON string into a Map.
        final Map<String, dynamic> settingsMap = jsonDecode(settingsJson);
        // Convert the Map into an AppSettings object.
        return AppSettings.fromMap(settingsMap);
      }
    } catch (e) {
      // Log any errors during loading, but don't crash the app.
      print('Error loading settings: $e');
    }

    // If anything goes wrong or no settings are saved yet, return default settings.
    return const AppSettings();
  }

  // Saves the provided AppSettings object to SharedPreferences.
  // Returns true if successful, false otherwise.
  Future<bool> saveSettings(AppSettings settings) async {
    try {
      // Encode the AppSettings object into a JSON string.
      final settingsJson = jsonEncode(settings.toMap());
      // Save the JSON string to SharedPreferences.
      return await _prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      print('Error saving settings: $e');
      return false;
    }
  }

  // Clears all saved application settings.
  // This is useful for a "reset to default" feature.
  Future<bool> clearSettings() async {
    try {
      return await _prefs.remove(_settingsKey); // Remove the settings entry.
    } catch (e) {
      print('Error clearing settings: $e');
      return false;
    }
  }

  // Updates only the accent color setting.
  // It fetches current settings, updates the color, and saves the new settings.
  Future<bool> updateAccentColor(String colorHex) async {
    final currentSettings = getSettings(); // Get the current settings.
    final updatedSettings = currentSettings.copyWith(accentColor: colorHex); // Create a copy with the new color.
    return await saveSettings(updatedSettings); // Save the updated settings.
  }

  // Updates only the first day of the week setting.
  Future<bool> updateFirstDayOfWeek(String day) async {
    final currentSettings = getSettings();
    final updatedSettings = currentSettings.copyWith(firstDayOfWeek: day);
    return await saveSettings(updatedSettings);
  }

  // Updates only the default task priority setting.
  Future<bool> updateDefaultPriority(int priority) async {
    final currentSettings = getSettings();
    final updatedSettings = currentSettings.copyWith(
      defaultTaskPriority: priority,
    );
    return await saveSettings(updatedSettings);
  }

  // Exports the current settings as a JSON string.
  // Useful for backup or sharing settings.
  String exportSettings() {
    try {
      final settings = getSettings(); // Get the current settings.
      return jsonEncode(settings.toMap()); // Encode them to a JSON string.
    } catch (e) {
      print('Error exporting settings: $e');
      return '{}'; // Return an empty JSON object on error.
    }
  }

  // Imports settings from a provided JSON string.
  // It decodes the JSON, converts it to AppSettings, and saves it.
  Future<bool> importSettings(String jsonString) async {
    try {
      final Map<String, dynamic> settingsMap = jsonDecode(jsonString); // Decode the JSON string.
      final settings = AppSettings.fromMap(settingsMap); // Convert to AppSettings object.
      return await saveSettings(settings); // Save the imported settings.
    } catch (e) {
      print('Error importing settings: $e');
      return false;
    }
  }
}
