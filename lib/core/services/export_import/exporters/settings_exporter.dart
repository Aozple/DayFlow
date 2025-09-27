import 'package:dayflow/core/constants/app_constants.dart';
import 'package:dayflow/core/services/export_import/exporters/base_exporter.dart';
import 'package:dayflow/core/services/export_import/models/export_import_models.dart';
import 'package:dayflow/data/repositories/settings_repository.dart';

class SettingsExporter extends BaseExporter {
  final SettingsRepository repository;

  SettingsExporter({required this.repository}) : super(tag: 'SettingsExporter');

  // MARK: - Export Methods

  /// Exports settings to a JSON map.
  Map<String, dynamic> exportToJsonMap() {
    try {
      final settings = repository.getSettings();
      return {
        'settings': settings.toMap(),
        'exportDate': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      logError('Failed to export settings', error: e);
      return {};
    }
  }

  /// Exports settings to a readable text format.
  Future<ExportResult> exportToText() async {
    try {
      logInfo('Starting settings text export');

      final settings = repository.getSettings();
      final text = StringBuffer();

      text.writeln('${AppConstants.appName} Settings Export');
      text.writeln('=' * 40);
      text.writeln('Export Date: ${formatDate(DateTime.now())}');
      text.writeln('');

      text.writeln('Theme & Appearance:');
      text.writeln('  Accent Color: ${settings.accentColor}');
      text.writeln('');

      text.writeln('Calendar:');
      text.writeln('  First Day of Week: ${settings.firstDayLabel}');
      text.writeln('');

      text.writeln('Tasks:');
      text.writeln(
        '  Default Priority: ${settings.priorityLabel}',
      );
      text.writeln('');

      text.writeln('Notifications:');
      text.writeln(
        '  Default Enabled: ${settings.defaultNotificationEnabled ? "Yes" : "No"}',
      );
      text.writeln('  Default Time: ${settings.notificationTimeLabel}');
      text.writeln('  Sound: ${settings.notificationSound ? "On" : "Off"}');
      text.writeln(
        '  Vibration: ${settings.notificationVibration ? "On" : "Off"}',
      );

      final fileName = generateFileName('settings', 'txt');

      logSuccess('Settings text export ready');

      return ExportResult(
        success: true,
        data: text.toString(),
        fileName: fileName,
        itemCount: 1,
        format: 'text',
      );
    } catch (e) {
      logError('Export to text failed', error: e);
      return ExportResult(success: false, error: e.toString());
    }
  }
}
