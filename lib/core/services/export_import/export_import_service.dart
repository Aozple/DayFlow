import 'package:dayflow/core/services/export_import/export_service.dart';
import 'package:dayflow/core/services/export_import/file_manager.dart';
import 'package:dayflow/core/services/export_import/import_service.dart';
import 'package:dayflow/core/services/export_import/models/export_import_models.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:dayflow/data/repositories/habit_repository.dart';
import 'package:dayflow/data/repositories/settings_repository.dart';
import 'package:dayflow/data/repositories/task_repository.dart';
import 'package:get_it/get_it.dart';

class ExportImportService {
  static const String _tag = 'ExportImportService';

  final ExportService _exportService = ExportService();
  final ImportService _importService = ImportService();

  bool get canQuickExport => _exportService.canQuickExport;

  Future<ExportResult> exportAllToJson({
    bool includeCompletedTasks = true,
    bool includeHabitInstances = true,
    bool includeSettings = true,
  }) async {
    return await _exportService.exportAllToJson(
      includeCompletedTasks: includeCompletedTasks,
      includeHabitInstances: includeHabitInstances,
      includeSettings: includeSettings,
    );
  }

  Future<ExportResult> exportTasksOnly(
    ExportFormat format, {
    bool includeCompleted = true,
  }) async {
    return await _exportService.exportTasksOnly(
      format,
      includeCompleted: includeCompleted,
    );
  }

  Future<ExportResult> exportHabitsOnly(ExportFormat format) async {
    return await _exportService.exportHabitsOnly(format);
  }

  Future<ImportValidation> validateImport(String data) async {
    return await _importService.validateImport(data);
  }

  Future<ImportResult> importFromJson(
    String jsonString, {
    bool merge = true,
    bool importTasks = true,
    bool importHabits = true,
    bool importSettings = true,
  }) async {
    return await _importService.importFromJson(
      jsonString,
      merge: merge,
      importTasks: importTasks,
      importHabits: importHabits,
      importSettings: importSettings,
    );
  }

  Future<ImportResult> importFromCsv(String csvString, ImportType type) async {
    return await _importService.importFromCsv(csvString, type);
  }

  Future<bool> quickBackup() async {
    try {
      DebugLogger.info('Starting quick backup', tag: _tag);

      final result = await _exportService.exportAllToJson();

      if (result.success) {
        final filePath = await FileManager.saveToDevice(result);
        return filePath != null;
      }

      return false;
    } catch (e) {
      DebugLogger.error('Quick backup failed', tag: _tag, error: e);
      return false;
    }
  }

  Future<bool> backupAndShare() async {
    try {
      final result = await _exportService.exportAllToJson();

      if (result.success) {
        return await FileManager.shareExport(result);
      }

      return false;
    } catch (e) {
      DebugLogger.error('Backup and share failed', tag: _tag, error: e);
      return false;
    }
  }

  Future<ImportResult> restoreFromFile() async {
    try {
      final content = await FileManager.pickFileForImport();

      if (content == null) {
        return ImportResult(success: false, error: 'No file selected');
      }

      final validation = await _importService.validateImport(content);

      if (!validation.isValid) {
        return ImportResult(
          success: false,
          error: validation.error ?? 'Invalid file format',
        );
      }

      if (validation.format == 'json') {
        return await _importService.importFromJson(content, merge: true);
      } else {
        return await _importService.importFromCsv(content, ImportType.tasks);
      }
    } catch (e) {
      DebugLogger.error('Restore failed', tag: _tag, error: e);
      return ImportResult(success: false, error: e.toString());
    }
  }

  Future<bool> clearAllDataWithBackup() async {
    try {
      DebugLogger.info('Creating backup before clear', tag: _tag);

      final backup = await _exportService.exportAllToJson();

      if (backup.success) {
        await FileManager.saveToDevice(backup);
      }

      final taskRepo = GetIt.I<TaskRepository>();
      final habitRepo = GetIt.I<HabitRepository>();
      final settingsRepo = GetIt.I<SettingsRepository>();

      await taskRepo.clearAllTasks();
      await habitRepo.clearAllHabits();
      await settingsRepo.clearSettings();

      DebugLogger.success('All data cleared', tag: _tag);
      return true;
    } catch (e) {
      DebugLogger.error('Failed to clear data', tag: _tag, error: e);
      return false;
    }
  }

  Future<ExportResult> exportTasks(ExportFormat format) async {
    return await _exportService.exportTasksOnly(format);
  }

  Future<ExportResult> exportHabits(ExportFormat format) async {
    return await _exportService.exportHabitsOnly(format);
  }
}
