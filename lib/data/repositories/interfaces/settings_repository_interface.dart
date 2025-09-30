import 'package:dayflow/data/models/app_settings.dart';

abstract class ISettingsRepository {
  Future<void> init();
  bool get isInitialized;

  AppSettings getSettings();
  Future<bool> saveSettings(AppSettings settings);
  Future<bool> clearSettings();

  Future<bool> updateAccentColor(String colorHex);
  Future<bool> updateFirstDayOfWeek(String day);
  Future<bool> updateDefaultPriority(int priority);
  Future<bool> updateMultiple(Map<String, dynamic> updates);

  String exportSettings();
  Future<bool> importSettings(String jsonString);

  Map<String, dynamic> getStatus();
}
