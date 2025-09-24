import 'package:dayflow/core/constants/app_constants.dart';
import 'package:dayflow/core/services/export_import/importers/base_importer.dart';
import 'package:dayflow/core/services/export_import/models/export_import_models.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:dayflow/data/repositories/task_repository.dart';

class TaskImporter extends BaseImporter {
  final TaskRepository repository;

  TaskImporter({required this.repository}) : super(tag: 'TaskImporter');

  // Import from JSON data
  Future<ImportResult> importFromJson(
    List<dynamic> tasksData, {
    bool merge = true,
  }) async {
    try {
      logInfo('Starting tasks import', data: '${tasksData.length} tasks');

      if (!merge) {
        await repository.clearAllTasks();
        logInfo('Cleared existing tasks');
      }

      int imported = 0;
      int failed = 0;
      final errors = <String>[];

      for (final taskData in tasksData) {
        try {
          final task = _taskFromJson(taskData);
          await repository.addTask(task);
          imported++;
        } catch (e) {
          failed++;
          errors.add('Task import failed: ${e.toString()}');
          logWarning('Failed to import task', data: e.toString());
        }
      }

      logSuccess(
        'Tasks import completed',
        data: 'Imported: $imported, Failed: $failed',
      );

      return ImportResult(
        success: imported > 0,
        importedCount: imported,
        failedCount: failed,
        errors: errors,
        type: ImportType.tasks,
      );
    } catch (e) {
      logError('Import from JSON failed', error: e);
      return ImportResult(
        success: false,
        error: e.toString(),
        type: ImportType.tasks,
      );
    }
  }

  // Import from CSV
  Future<ImportResult> importFromCsv(String csvString) async {
    try {
      logInfo('Starting CSV import');

      // Remove BOM if present
      if (csvString.startsWith('\uFEFF')) {
        csvString = csvString.substring(1);
      }

      final lines = csvString.split('\n');
      if (lines.isEmpty) {
        throw Exception('Empty CSV file');
      }

      final dataLines =
          lines.skip(1).where((line) => line.trim().isNotEmpty).toList();

      int imported = 0;
      int failed = 0;
      final errors = <String>[];

      for (final line in dataLines) {
        try {
          final fields = parseCsvLine(line);
          if (fields.length < 9) continue;

          final task = TaskModel(
            title: fields[0],
            description: fields[1].isNotEmpty ? fields[1] : null,
            isNote: fields[2].toLowerCase() == 'note',
            priority:
                parseInt(
                  fields[3],
                  defaultValue: AppConstants.defaultPriority,
                ) ??
                AppConstants.defaultPriority,
            isCompleted: fields[4].toLowerCase() == 'completed',
            dueDate: parseDate(fields[5]),
            createdAt: parseDate(fields[6]) ?? DateTime.now(),
            tags:
                fields[7].isNotEmpty
                    ? fields[7]
                        .split(';')
                        .map((t) => t.trim())
                        .where((t) => t.isNotEmpty)
                        .toList()
                    : [],
            hasNotification: fields[8].toLowerCase() == 'yes',
          );

          await repository.addTask(task);
          imported++;
        } catch (e) {
          failed++;
          logWarning('Failed to parse CSV line', data: e.toString());
        }
      }

      logSuccess(
        'CSV import completed',
        data: 'Imported: $imported, Failed: $failed',
      );

      return ImportResult(
        success: imported > 0,
        importedCount: imported,
        failedCount: failed,
        errors: errors,
        type: ImportType.tasks,
      );
    } catch (e) {
      logError('Import from CSV failed', error: e);
      return ImportResult(
        success: false,
        error: e.toString(),
        type: ImportType.tasks,
      );
    }
  }

  TaskModel _taskFromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled',
      description: json['description'],
      isNote: json['isNote'] ?? false,
      priority: json['priority'] ?? AppConstants.defaultPriority,
      isCompleted: json['isCompleted'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      completedAt:
          json['completedAt'] != null
              ? DateTime.parse(json['completedAt'])
              : null,
      tags: List<String>.from(json['tags'] ?? []),
      color: json['color'] ?? '#6C63FF',
      hasNotification: json['hasNotification'] ?? false,
      notificationMinutesBefore: json['notificationMinutesBefore'],
      estimatedMinutes: json['estimatedMinutes'],
      actualMinutes: json['actualMinutes'],
      noteContent: json['noteContent'],
      markdownContent: json['markdownContent'],
    );
  }
}
