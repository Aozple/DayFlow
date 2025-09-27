import 'package:dayflow/core/constants/app_constants.dart';
import 'package:dayflow/core/services/export_import/exporters/base_exporter.dart';
import 'package:dayflow/core/services/export_import/models/export_import_models.dart';
import 'package:dayflow/data/models/habit_model.dart';
import 'package:dayflow/data/models/habit_instance_model.dart';
import 'package:dayflow/data/repositories/habit_repository.dart';

class HabitExporter extends BaseExporter {
  final HabitRepository repository;

  HabitExporter({required this.repository}) : super(tag: 'HabitExporter');

  // MARK: - Export Methods

  /// Exports habits and their instances to a JSON map.
  Future<Map<String, dynamic>> exportToJsonMap({
    bool includeInstances = true,
  }) async {
    try {
      final habits = repository.getAllHabits();

      List<Map<String, dynamic>>? instances;
      if (includeInstances) {
        instances = [];
        for (final habit in habits) {
          final habitInstances = repository.getInstancesByHabitId(habit.id);
          instances.addAll(habitInstances.map((i) => _instanceToJson(i)));
        }
      }

      return {
        'habits': habits.map((h) => _habitToJson(h)).toList(),
        'instances': instances,
        'habitsCount': habits.length,
        'activeCount': habits.where((h) => h.isActive).length,
      };
    } catch (e) {
      logError('Failed to export habits', error: e);
      return {};
    }
  }

  /// Exports habits to a CSV string.
  Future<ExportResult> exportToCsv() async {
    try {
      logInfo('Starting habits CSV export');

      final habits = repository.getAllHabits();

      final csv = StringBuffer();
      csv.write('\uFEFF'); // UTF-8 BOM

      csv.writeln(
        'Title,Description,Frequency,Preferred Time,Current Streak,Total Completions,Tags,Has Reminder',
      );

      for (final habit in habits) {
        csv.writeln(_habitToCsvRow(habit));
      }

      final fileName = generateFileName('habits', AppConstants.csvExtension);

      logSuccess('CSV export ready', data: '${habits.length} habits');

      return ExportResult(
        success: true,
        data: csv.toString(),
        fileName: fileName,
        itemCount: habits.length,
        format: 'csv',
      );
    } catch (e) {
      logError('Export to CSV failed', error: e);
      return ExportResult(success: false, error: e.toString());
    }
  }

  /// Exports habits to a Markdown string.
  Future<ExportResult> exportToMarkdown() async {
    try {
      logInfo('Starting habits Markdown export');

      final habits = repository.getAllHabits();

      final md = StringBuffer();
      md.writeln('# ${AppConstants.appName} Habits Export\n');
      md.writeln('**Generated:** ${formatDate(DateTime.now())}\n');
      md.writeln('**Total Habits:** ${habits.length}\n');
      md.writeln('---\n');

      for (final habit in habits) {
        _writeHabitMarkdown(md, habit);
      }

      final fileName = generateFileName(
        'habits',
        AppConstants.markdownExtension,
      );

      logSuccess('Markdown export ready', data: '${habits.length} habits');

      return ExportResult(
        success: true,
        data: md.toString(),
        fileName: fileName,
        itemCount: habits.length,
        format: 'markdown',
      );
    } catch (e) {
      logError('Export to Markdown failed', error: e);
      return ExportResult(success: false, error: e.toString());
    }
  }

  // MARK: - Helper Methods

  /// Converts a HabitModel to a JSON map.
  Map<String, dynamic> _habitToJson(HabitModel habit) {
    return habit.toMap();
  }

  /// Converts a HabitInstanceModel to a JSON map.
  Map<String, dynamic> _instanceToJson(HabitInstanceModel instance) {
    return instance.toMap();
  }

  /// Converts a HabitModel to a CSV row string.
  String _habitToCsvRow(HabitModel habit) {
    return [
      escapeCsv(habit.title),
      escapeCsv(habit.description ?? ''),
      habit.frequencyLabel,
      habit.preferredTime != null
          ? '${habit.preferredTime!.hour}:${habit.preferredTime!.minute.toString().padLeft(2, '0')}'
          : '',
      habit.currentStreak.toString(),
      habit.totalCompletions.toString(),
      escapeCsv(habit.tags.join('; ')),
      habit.hasNotification ? 'Yes' : 'No',
    ].join(',');
  }

  /// Writes a habit's details to a Markdown buffer.
  void _writeHabitMarkdown(StringBuffer md, HabitModel habit) {
    md.writeln('## 🎯 ${habit.title}\n');

    if (habit.description != null && habit.description!.isNotEmpty) {
      md.writeln('${habit.description}\n');
    }

    md.writeln('- **Frequency:** ${habit.frequencyLabel}');
    md.writeln('- **Current Streak:** ${habit.currentStreak} days');
    md.writeln('- **Total Completions:** ${habit.totalCompletions}');
    md.writeln('- **Longest Streak:** ${habit.longestStreak} days');

    if (habit.tags.isNotEmpty) {
      md.writeln('- **Tags:** ${habit.tags.join(', ')}');
    }

    md.writeln();
  }
}
