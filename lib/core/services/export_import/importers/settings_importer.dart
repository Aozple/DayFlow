import 'package:dayflow/core/services/export_import/importers/base_importer.dart';
import 'package:dayflow/data/models/app_settings.dart';
import 'package:dayflow/data/repositories/settings_repository.dart';

class SettingsImporter extends BaseImporter {
  final SettingsRepository repository;

  SettingsImporter({required this.repository}) : super(tag: 'SettingsImporter');

  // Import settings from JSON
  Future<bool> importFromJson(Map<String, dynamic> settingsData) async {
    try {
      logInfo('Importing settings');

      final settings = AppSettings.fromMap(settingsData);

      if (!settings.isValid()) {
        logWarning('Invalid settings, attempting to fix');
        // Settings repository will fix invalid settings
      }

      final success = await repository.saveSettings(settings);

      if (success) {
        logSuccess('Settings imported successfully');
      } else {
        logError('Failed to save imported settings');
      }

      return success;
    } catch (e) {
      logError('Settings import failed', error: e);
      return false;
    }
  }
}
