import 'package:dayflow/core/constants/app_constants.dart';
import 'package:dayflow/core/services/export_import/exporters/base_exporter.dart';
import 'package:dayflow/core/services/export_import/models/export_import_models.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:dayflow/data/repositories/task_repository.dart';
import 'package:intl/intl.dart';

class TaskExporter extends BaseExporter {
  final TaskRepository repository;

  TaskExporter({required this.repository}) : super(tag: 'TaskExporter');

  // MARK: - Export Methods

  /// Exports tasks to a JSON map.
  Future<Map<String, dynamic>> exportToJsonMap({
    bool includeCompleted = true,
  }) async {
    try {
      final allTasks = repository.getAllTasks();
      final tasks =
          includeCompleted
              ? allTasks
              : allTasks.where((t) => !t.isCompleted).toList();

      return {
        'tasks': tasks.map((t) => _taskToJson(t)).toList(),
        'tasksCount': tasks.length,
        'completedCount': tasks.where((t) => t.isCompleted).length,
        'notesCount': tasks.where((t) => t.isNote).length,
      };
    } catch (e) {
      logError('Failed to export tasks', error: e);
      return {};
    }
  }

  /// Exports tasks to a CSV string.
  Future<ExportResult> exportToCsv({
    bool includeCompleted = true,
    bool includeNotes = true,
  }) async {
    try {
      logInfo('Starting CSV export');

      final allTasks = repository.getAllTasks();
      var tasks =
          includeCompleted
              ? allTasks
              : allTasks.where((t) => !t.isCompleted).toList();

      if (!includeNotes) {
        tasks = tasks.where((t) => !t.isNote).toList();
      }

      final csv = StringBuffer();
      csv.write('\uFEFF'); // UTF-8 BOM

      csv.writeln(
        'Title,Description,Type,Priority,Status,Due Date,Created Date,Tags,Has Reminder',
      );

      for (final task in tasks) {
        csv.writeln(_taskToCsvRow(task));
      }

      final fileName = generateFileName('tasks', AppConstants.csvExtension);

      logSuccess('CSV export ready', data: '${tasks.length} tasks');

      return ExportResult(
        success: true,
        data: csv.toString(),
        fileName: fileName,
        itemCount: tasks.length,
        format: 'csv',
      );
    } catch (e) {
      logError('Export to CSV failed', error: e);
      return ExportResult(success: false, error: e.toString());
    }
  }

  /// Exports tasks to a Markdown string.
  Future<ExportResult> exportToMarkdown({
    bool includeCompleted = true,
    bool groupByDate = true,
  }) async {
    try {
      logInfo('Starting Markdown export');

      final tasks =
          repository
              .getAllTasks()
              .where((t) => includeCompleted || !t.isCompleted)
              .toList();

      final md = StringBuffer();
      md.writeln('# ${AppConstants.appName} Tasks Export\n');
      md.writeln('**Generated:** ${formatDate(DateTime.now())}\n');
      md.writeln('**Total Tasks:** ${tasks.length}\n');
      md.writeln('---\n');

      if (groupByDate) {
        _writeGroupedMarkdown(md, tasks);
      } else {
        _writeSimpleMarkdown(md, tasks);
      }

      final fileName = generateFileName(
        'tasks',
        AppConstants.markdownExtension,
      );

      logSuccess('Markdown export ready', data: '${tasks.length} tasks');

      return ExportResult(
        success: true,
        data: md.toString(),
        fileName: fileName,
        itemCount: tasks.length,
        format: 'markdown',
      );
    } catch (e) {
      logError('Export to Markdown failed', error: e);
      return ExportResult(success: false, error: e.toString());
    }
  }

  // MARK: - Helper Methods

  /// Converts a TaskModel to a JSON map.
  Map<String, dynamic> _taskToJson(TaskModel task) {
    return {
      'id': task.id,
      'title': task.title,
      'description': task.description,
      'isNote': task.isNote,
      'priority': task.priority,
      'isCompleted': task.isCompleted,
      'isDeleted': task.isDeleted,
      'dueDate': task.dueDate?.toIso8601String(),
      'createdAt': task.createdAt.toIso8601String(),
      'completedAt': task.completedAt?.toIso8601String(),
      'tags': task.tags,
      'color': task.color,
      'hasNotification': task.hasNotification,
      'notificationMinutesBefore': task.notificationMinutesBefore,
      'estimatedMinutes': task.estimatedMinutes,
      'actualMinutes': task.actualMinutes,
      'noteContent': task.noteContent,
      'markdownContent': task.markdownContent,
    };
  }

  /// Converts a TaskModel to a CSV row string.
  String _taskToCsvRow(TaskModel task) {
    return [
      escapeCsv(task.title),
      escapeCsv(task.description ?? ''),
      task.isNote ? 'Note' : 'Task',
      formatPriority(task.priority),
      task.isCompleted ? 'Completed' : 'Pending',
      formatDate(task.dueDate),
      formatDate(task.createdAt),
      escapeCsv(task.tags.join('; ')),
      task.hasNotification ? 'Yes' : 'No',
    ].join(',');
  }

  /// Writes tasks to a Markdown buffer, grouped by date.
  void _writeGroupedMarkdown(StringBuffer md, List<TaskModel> tasks) {
    final tasksByDate = <String, List<TaskModel>>{};

    for (final task in tasks) {
      final dateKey =
          task.dueDate != null
              ? DateFormat('yyyy-MM-dd').format(task.dueDate!)
              : 'No Due Date';
      tasksByDate.putIfAbsent(dateKey, () => []).add(task);
    }

    final sortedDates = tasksByDate.keys.toList()..sort();

    for (final date in sortedDates) {
      md.writeln('## 📅 $date\n');
      for (final task in tasksByDate[date]!) {
        _writeTaskMarkdown(md, task);
      }
      md.writeln();
    }
  }

  /// Writes tasks to a Markdown buffer in a simple list.
  void _writeSimpleMarkdown(StringBuffer md, List<TaskModel> tasks) {
    for (final task in tasks) {
      _writeTaskMarkdown(md, task);
    }
  }

  /// Writes a single task's details to a Markdown buffer.
  void _writeTaskMarkdown(StringBuffer md, TaskModel task) {
    md.write(task.isCompleted ? '- [x] ' : '- [ ] ');
    md.write('**${task.title}**');

    if (task.priority >= 4) {
      md.write(' 🔴');
    } else if (task.priority == 3) {
      md.write(' 🟡');
    }

    md.writeln();

    if (task.description != null && task.description!.isNotEmpty) {
      md.writeln('  ${task.description}');
    }

    if (task.tags.isNotEmpty) {
      md.writeln('  🏷️ ${task.tags.join(', ')}');
    }

    if (task.dueDate != null) {
      md.writeln('  📅 ${formatDate(task.dueDate)}');
    }

    md.writeln();
  }
}
