import 'dart:convert';
import 'package:dayflow/core/constants/app_constants.dart';
import 'package:dayflow/core/services/export_import/exporters/habit_exporter.dart';
import 'package:dayflow/core/services/export_import/exporters/task_exporter.dart';
import 'package:dayflow/core/services/export_import/models/export_import_models.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:dayflow/data/repositories/habit_repository.dart';
import 'package:dayflow/data/repositories/settings_repository.dart';
import 'package:dayflow/data/repositories/task_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ExportService {
  static const String _tag = 'ExportService';

  final TaskRepository _taskRepository = GetIt.I<TaskRepository>();
  final HabitRepository _habitRepository = GetIt.I<HabitRepository>();
  final SettingsRepository _settingsRepository = GetIt.I<SettingsRepository>();

  late final TaskExporter _taskExporter;
  late final HabitExporter _habitExporter;

  DateTime? _lastExportTime;

  ExportService() {
    _taskExporter = TaskExporter(repository: _taskRepository);
    _habitExporter = HabitExporter(repository: _habitRepository);
  }

  /// Checks if a quick export is possible based on the last export time.
  bool get canQuickExport {
    if (_lastExportTime == null) return false;
    return DateTime.now().difference(_lastExportTime!).inSeconds <
        AppConstants.quickExportDuration.inSeconds;
  }

  // MARK: - Export Methods

  /// Exports all application data to a JSON string.
  Future<ExportResult> exportAllToJson({
    bool includeCompletedTasks = true,
    bool includeHabitInstances = true,
    bool includeSettings = true,
  }) async {
    try {
      DebugLogger.info('Starting full JSON export', tag: _tag);

      final packageInfo = await PackageInfo.fromPlatform();

      final tasksData = await _taskExporter.exportToJsonMap(
        includeCompleted: includeCompletedTasks,
      );

      final habitsData = await _habitExporter.exportToJsonMap(
        includeInstances: includeHabitInstances,
      );

      final settings =
          includeSettings ? _settingsRepository.getSettings() : null;

      final exportData = {
        'version': AppConstants.currentDataVersion,
        'appVersion': packageInfo.version,
        'exportDate': DateTime.now().toIso8601String(),
        'summary': {
          'tasksCount': tasksData['tasksCount'] ?? 0,
          'habitsCount': habitsData['habitsCount'] ?? 0,
          'totalItems':
              (tasksData['tasksCount'] ?? 0) + (habitsData['habitsCount'] ?? 0),
        },
        'tasks': tasksData['tasks'],
        'habits': habitsData['habits'],
        'habitInstances': habitsData['instances'],
        'settings': settings?.toMap(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      final fileName = _generateFileName('backup', AppConstants.jsonExtension);

      _lastExportTime = DateTime.now();

      DebugLogger.success('JSON export ready', tag: _tag);

      return ExportResult(
        success: true,
        data: jsonString,
        fileName: fileName,
        itemCount: exportData['summary']['totalItems'] as int,
        format: 'json',
      );
    } catch (e) {
      DebugLogger.error('Export failed', tag: _tag, error: e);
      return ExportResult(success: false, error: e.toString());
    }
  }

  /// Exports only tasks in the specified format.
  Future<ExportResult> exportTasksOnly(
    ExportFormat format, {
    bool includeCompleted = true,
  }) async {
    switch (format) {
      case ExportFormat.csv:
        return _taskExporter.exportToCsv(includeCompleted: includeCompleted);
      case ExportFormat.markdown:
        return _taskExporter.exportToMarkdown(
          includeCompleted: includeCompleted,
        );
      default:
        final data = await _taskExporter.exportToJsonMap(
          includeCompleted: includeCompleted,
        );
        final jsonString = const JsonEncoder.withIndent('  ').convert(data);
        return ExportResult(
          success: true,
          data: jsonString,
          fileName: _generateFileName('tasks', AppConstants.jsonExtension),
          itemCount: data['tasksCount'] as int,
          format: 'json',
        );
    }
  }

  /// Exports only habits in the specified format.
  Future<ExportResult> exportHabitsOnly(ExportFormat format) async {
    switch (format) {
      case ExportFormat.csv:
        return _habitExporter.exportToCsv();
      case ExportFormat.markdown:
        return _habitExporter.exportToMarkdown();
      default:
        final data = await _habitExporter.exportToJsonMap();
        final jsonString = const JsonEncoder.withIndent('  ').convert(data);
        return ExportResult(
          success: true,
          data: jsonString,
          fileName: _generateFileName('habits', AppConstants.jsonExtension),
          itemCount: data['habitsCount'] as int,
          format: 'json',
        );
    }
  }

  // MARK: - Helper Methods

  /// Generates a file name with a prefix and extension.
  String _generateFileName(String prefix, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${AppConstants.appName.toLowerCase()}_${prefix}_$timestamp.$extension';
  }
}
