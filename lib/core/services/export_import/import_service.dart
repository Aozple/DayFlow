import 'dart:convert';
import 'package:dayflow/core/constants/app_constants.dart';
import 'package:dayflow/core/services/export_import/importers/habit_importer.dart';
import 'package:dayflow/core/services/export_import/importers/settings_importer.dart';
import 'package:dayflow/core/services/export_import/importers/task_importer.dart';
import 'package:dayflow/core/services/export_import/models/export_import_models.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:dayflow/data/repositories/habit_repository.dart';
import 'package:dayflow/data/repositories/settings_repository.dart';
import 'package:dayflow/data/repositories/task_repository.dart';
import 'package:get_it/get_it.dart';

class ImportService {
  static const String _tag = 'ImportService';

  final TaskRepository _taskRepository = GetIt.I<TaskRepository>();
  final HabitRepository _habitRepository = GetIt.I<HabitRepository>();
  final SettingsRepository _settingsRepository = GetIt.I<SettingsRepository>();

  late final TaskImporter _taskImporter;
  late final HabitImporter _habitImporter;
  late final SettingsImporter _settingsImporter;

  ImportService() {
    _taskImporter = TaskImporter(repository: _taskRepository);
    _habitImporter = HabitImporter(repository: _habitRepository);
    _settingsImporter = SettingsImporter(repository: _settingsRepository);
  }

  // Validate import data
  Future<ImportValidation> validateImport(String data) async {
    try {
      // Check if JSON
      if (data.trim().startsWith('{')) {
        final Map<String, dynamic> jsonData = jsonDecode(data);

        return ImportValidation(
          isValid: true,
          format: 'json',
          totalItems: _countItems(jsonData),
          version: jsonData['version'] ?? 1,
          hasSettings: jsonData['settings'] != null,
          hasTasks:
              jsonData['tasks'] != null &&
              (jsonData['tasks'] as List).isNotEmpty,
          hasHabits:
              jsonData['habits'] != null &&
              (jsonData['habits'] as List).isNotEmpty,
        );
      }

      // Check if CSV
      if (data.contains(',') && data.contains('\n')) {
        final lines = data.split('\n');
        final dataLines =
            lines.where((l) => l.trim().isNotEmpty).skip(1).toList();

        return ImportValidation(
          isValid: true,
          format: 'csv',
          totalItems: dataLines.length,
        );
      }

      return ImportValidation(isValid: false, error: 'Unknown file format');
    } catch (e) {
      return ImportValidation(isValid: false, error: e.toString());
    }
  }

  // Import from JSON
  Future<ImportResult> importFromJson(
    String jsonString, {
    bool merge = true,
    bool importTasks = true,
    bool importHabits = true,
    bool importSettings = true,
  }) async {
    try {
      DebugLogger.info('Starting JSON import', tag: _tag);

      final Map<String, dynamic> data = jsonDecode(jsonString);

      // Check version
      final version = data['version'] ?? 0;
      if (version > AppConstants.currentDataVersion) {
        DebugLogger.warning(
          'Import from newer version',
          tag: _tag,
          data: 'v$version',
        );
      }

      int totalImported = 0;
      int totalFailed = 0;
      final errors = <String>[];

      // Import tasks
      if (importTasks && data['tasks'] != null) {
        final tasksResult = await _taskImporter.importFromJson(
          data['tasks'] as List,
          merge: merge,
        );
        totalImported += tasksResult.importedCount ?? 0;
        totalFailed += tasksResult.failedCount ?? 0;
        if (tasksResult.errors != null) errors.addAll(tasksResult.errors!);
      }

      // Import habits
      if (importHabits && data['habits'] != null) {
        final habitsResult = await _habitImporter.importFromJson(
          data['habits'] as List,
          instancesData: data['habitInstances'] as List?,
          merge: merge,
        );
        totalImported += habitsResult.importedCount ?? 0;
        totalFailed += habitsResult.failedCount ?? 0;
        if (habitsResult.errors != null) errors.addAll(habitsResult.errors!);
      }

      // Import settings
      if (importSettings && data['settings'] != null) {
        final settingsSuccess = await _settingsImporter.importFromJson(
          data['settings'],
        );
        if (!settingsSuccess) {
          errors.add('Settings import failed');
        }
      }

      DebugLogger.success(
        'Import completed',
        tag: _tag,
        data: 'Imported: $totalImported, Failed: $totalFailed',
      );

      return ImportResult(
        success: totalImported > 0,
        importedCount: totalImported,
        failedCount: totalFailed,
        errors: errors,
        type: ImportType.all,
      );
    } catch (e) {
      DebugLogger.error('Import from JSON failed', tag: _tag, error: e);
      return ImportResult(
        success: false,
        error: e.toString(),
        type: ImportType.all,
      );
    }
  }

  // Import from CSV (tasks or habits)
  Future<ImportResult> importFromCsv(String csvString, ImportType type) async {
    switch (type) {
      case ImportType.tasks:
        return _taskImporter.importFromCsv(csvString);
      case ImportType.habits:
        return _habitImporter.importFromCsv(csvString);
      default:
        return ImportResult(
          success: false,
          error: 'CSV import only supports tasks or habits individually',
          type: type,
        );
    }
  }

  int _countItems(Map<String, dynamic> data) {
    int count = 0;
    if (data['tasks'] != null) {
      count += (data['tasks'] as List).length;
    }
    if (data['habits'] != null) {
      count += (data['habits'] as List).length;
    }
    return count;
  }
}
