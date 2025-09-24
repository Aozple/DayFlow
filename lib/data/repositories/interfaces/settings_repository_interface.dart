import 'package:dayflow/data/models/app_settings.dart';

abstract class ISettingsRepository {
  // Initialize
  Future<void> init();
  bool get isInitialized;

  // CRUD operations
  AppSettings getSettings();
  Future<bool> saveSettings(AppSettings settings);
  Future<bool> clearSettings();

  // Update specific settings
  Future<bool> updateAccentColor(String colorHex);
  Future<bool> updateFirstDayOfWeek(String day);
  Future<bool> updateDefaultPriority(int priority);
  Future<bool> updateMultiple(Map<String, dynamic> updates);

  // Export/Import
  String exportSettings();
  Future<bool> importSettings(String jsonString);

  // Status
  Map<String, dynamic> getStatus();
}
