import 'dart:convert';
import 'dart:io';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:dayflow/data/models/app_settings.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:dayflow/data/repositories/settings_repository.dart';
import 'package:dayflow/data/repositories/task_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportImportService {
  static const String _tag = 'ExportImport';

  final TaskRepository _taskRepository;
  final SettingsRepository _settingsRepository;

  // Simple cache for last export
  DateTime? _lastExportTime;

  ExportImportService({
    required TaskRepository taskRepository,
    required SettingsRepository settingsRepository,
  }) : _taskRepository = taskRepository,
       _settingsRepository = settingsRepository;

  // ============= EXPORT METHODS =============

  /// Export to JSON - Main export method
  Future<ExportResult> exportToJSON({
    bool includeCompleted = true,
    bool includeSettings = true,
  }) async {
    try {
      DebugLogger.info('Starting JSON export', tag: _tag);

      // Get app version
      final packageInfo = await PackageInfo.fromPlatform();

      // Get tasks
      final allTasks = _taskRepository.getAllTasks();
      final tasks =
          includeCompleted
              ? allTasks
              : allTasks.where((t) => !t.isCompleted).toList();

      // Get settings
      final settings =
          includeSettings ? _settingsRepository.getSettings() : null;

      // Create clean export data
      final exportData = <String, dynamic>{
        'version': 1,
        'appVersion': packageInfo.version,
        'exportDate': DateTime.now().toIso8601String(),
        'summary': <String, dynamic>{
          'totalTasks': tasks.length,
          'completedTasks': tasks.where((t) => t.isCompleted).length,
          'pendingTasks': tasks.where((t) => !t.isCompleted).length,
          'notesCount': tasks.where((t) => t.isNote).length,
        },
        'tasks': tasks.map((t) => _taskToJson(t)).toList(),
        'settings': settings?.toMap(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      final fileName = _generateFileName('backup', 'json');

      _lastExportTime = DateTime.now();

      DebugLogger.success(
        'JSON export ready',
        tag: _tag,
        data: '${tasks.length} tasks, ${jsonString.length} bytes',
      );

      return ExportResult(
        success: true,
        data: jsonString,
        fileName: fileName,
        itemCount: tasks.length,
        format: 'json',
      );
    } catch (e) {
      DebugLogger.error('Export to JSON failed', tag: _tag, error: e);
      return ExportResult(success: false, error: e.toString());
    }
  }

  /// Export to CSV
  Future<ExportResult> exportToCSV({
    bool includeCompleted = true,
    bool includeNotes = true,
  }) async {
    try {
      DebugLogger.info('Starting CSV export', tag: _tag);

      // Get tasks
      final allTasks = _taskRepository.getAllTasks();
      var tasks =
          includeCompleted
              ? allTasks
              : allTasks.where((t) => !t.isCompleted).toList();

      if (!includeNotes) {
        tasks = tasks.where((t) => !t.isNote).toList();
      }

      // Build CSV with UTF-8 BOM for Excel
      final csv = StringBuffer();
      csv.write('\uFEFF'); // UTF-8 BOM

      // Header
      csv.writeln(
        'Title,Description,Type,Priority,Status,Due Date,Created Date,Tags,Has Reminder',
      );

      // Data rows
      for (final task in tasks) {
        csv.writeln(
          [
            _escapeCsv(task.title),
            _escapeCsv(task.description ?? ''),
            task.isNote ? 'Note' : 'Task',
            'P${task.priority}',
            task.isCompleted ? 'Completed' : 'Pending',
            task.dueDate != null
                ? DateFormat('yyyy-MM-dd HH:mm').format(task.dueDate!)
                : '',
            DateFormat('yyyy-MM-dd HH:mm').format(task.createdAt),
            _escapeCsv(task.tags.join('; ')),
            task.hasNotification ? 'Yes' : 'No',
          ].join(','),
        );
      }

      final fileName = _generateFileName('tasks', 'csv');
      final csvString = csv.toString();

      _lastExportTime = DateTime.now();

      DebugLogger.success(
        'CSV export ready',
        tag: _tag,
        data: '${tasks.length} tasks',
      );

      return ExportResult(
        success: true,
        data: csvString,
        fileName: fileName,
        itemCount: tasks.length,
        format: 'csv',
      );
    } catch (e) {
      DebugLogger.error('Export to CSV failed', tag: _tag, error: e);
      return ExportResult(success: false, error: e.toString());
    }
  }

  /// Export to Markdown
  Future<ExportResult> exportToMarkdown({
    bool includeCompleted = true,
    bool groupByDate = true,
  }) async {
    try {
      DebugLogger.info('Starting Markdown export', tag: _tag);

      final tasks =
          _taskRepository
              .getAllTasks()
              .where((t) => includeCompleted || !t.isCompleted)
              .toList();

      final md = StringBuffer();
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

      // Header
      md.writeln('# DayFlow Export\n');
      md.writeln('**Generated:** ${dateFormat.format(DateTime.now())}\n');
      md.writeln('**Total Tasks:** ${tasks.length}\n');
      md.writeln('---\n');

      if (groupByDate) {
        // Group by date
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
      } else {
        // Simple list
        for (final task in tasks) {
          _writeTaskMarkdown(md, task);
        }
      }

      final fileName = _generateFileName('export', 'md');

      _lastExportTime = DateTime.now();

      return ExportResult(
        success: true,
        data: md.toString(),
        fileName: fileName,
        itemCount: tasks.length,
        format: 'markdown',
      );
    } catch (e) {
      DebugLogger.error('Export to Markdown failed', tag: _tag, error: e);
      return ExportResult(success: false, error: e.toString());
    }
  }

  // ============= IMPORT METHODS =============

  /// Import from JSON
  Future<ImportResult> importFromJSON(
    String jsonString, {
    bool merge = true,
  }) async {
    try {
      DebugLogger.info('Starting JSON import', tag: _tag);

      final Map<String, dynamic> data = jsonDecode(jsonString);

      // Check version
      final version = data['version'] ?? 0;
      if (version > 1) {
        DebugLogger.warning(
          'Import from newer version',
          tag: _tag,
          data: 'v$version',
        );
      }

      int imported = 0;
      int failed = 0;
      final errors = <String>[];

      // Clear if not merging
      if (!merge) {
        await _taskRepository.clearAllTasks();
        DebugLogger.info('Cleared existing tasks', tag: _tag);
      }

      // Import tasks
      final tasksList = data['tasks'] as List?;
      if (tasksList != null) {
        for (final taskData in tasksList) {
          try {
            final task = _taskFromJson(taskData);
            await _taskRepository.addTask(task);
            imported++;
          } catch (e) {
            failed++;
            errors.add('Failed: ${e.toString().substring(0, 50)}');
            DebugLogger.warning(
              'Task import failed',
              tag: _tag,
              data: e.toString(),
            );
          }
        }
      }

      // Import settings if available
      if (data['settings'] != null) {
        try {
          final settings = AppSettings.fromMap(data['settings']);
          await _settingsRepository.saveSettings(settings);
          DebugLogger.success('Settings imported', tag: _tag);
        } catch (e) {
          errors.add('Settings import failed');
          DebugLogger.warning(
            'Settings import failed',
            tag: _tag,
            data: e.toString(),
          );
        }
      }

      DebugLogger.success(
        'Import completed',
        tag: _tag,
        data: 'Imported: $imported, Failed: $failed',
      );

      return ImportResult(
        success: imported > 0,
        importedCount: imported,
        failedCount: failed,
        errors: errors,
      );
    } catch (e) {
      DebugLogger.error('Import from JSON failed', tag: _tag, error: e);
      return ImportResult(success: false, error: e.toString());
    }
  }

  /// Import from CSV
  Future<ImportResult> importFromCSV(String csvString) async {
    try {
      DebugLogger.info('Starting CSV import', tag: _tag);

      // Remove BOM if present
      if (csvString.startsWith('\uFEFF')) {
        csvString = csvString.substring(1);
      }

      final lines = csvString.split('\n');
      if (lines.isEmpty) {
        throw Exception('Empty CSV file');
      }

      // Skip header
      final dataLines =
          lines.skip(1).where((line) => line.trim().isNotEmpty).toList();

      int imported = 0;
      int failed = 0;
      final errors = <String>[];

      for (final line in dataLines) {
        try {
          final fields = _parseCsvLine(line);
          if (fields.length < 9) continue;

          final task = TaskModel(
            title: fields[0],
            description: fields[1].isNotEmpty ? fields[1] : null,
            isNote: fields[2].toLowerCase() == 'note',
            priority: int.tryParse(fields[3].replaceAll('P', '')) ?? 3,
            isCompleted: fields[4].toLowerCase() == 'completed',
            dueDate: fields[5].isNotEmpty ? DateTime.tryParse(fields[5]) : null,
            createdAt:
                fields[6].isNotEmpty
                    ? DateTime.tryParse(fields[6]) ?? DateTime.now()
                    : DateTime.now(),
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

          await _taskRepository.addTask(task);
          imported++;
        } catch (e) {
          failed++;
          DebugLogger.warning(
            'Failed to parse CSV line',
            tag: _tag,
            data: e.toString(),
          );
        }
      }

      DebugLogger.success(
        'CSV import completed',
        tag: _tag,
        data: 'Imported: $imported, Failed: $failed',
      );

      return ImportResult(
        success: imported > 0,
        importedCount: imported,
        failedCount: failed,
        errors: errors,
      );
    } catch (e) {
      DebugLogger.error('Import from CSV failed', tag: _tag, error: e);
      return ImportResult(success: false, error: e.toString());
    }
  }

  /// Validate import file
  Future<ImportValidation> validateImport(String data) async {
    try {
      // Check if JSON
      if (data.trim().startsWith('{')) {
        final Map<String, dynamic> jsonData = jsonDecode(data);

        return ImportValidation(
          isValid: true,
          format: 'json',
          totalItems: (jsonData['tasks'] as List?)?.length ?? 0,
          version: jsonData['version'] ?? 1,
          hasSettings: jsonData['settings'] != null,
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

  // ============= FILE OPERATIONS =============

  /// Share export file
  Future<bool> shareExport(ExportResult result) async {
    if (!result.success || result.data == null) return false;

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${result.fileName}');
      await file.writeAsString(result.data!);

      final xFile = XFile(file.path);
      final shareResult = await Share.shareXFiles(
        [xFile],
        subject: 'DayFlow Backup',
        text: 'DayFlow backup with ${result.itemCount} items',
      );

      await file.delete();

      return shareResult.status == ShareResultStatus.success;
    } catch (e) {
      DebugLogger.error('Failed to share export', tag: _tag, error: e);
      return false;
    }
  }

  /// Save to device storage
  Future<String?> saveToDevice(ExportResult result) async {
    if (!result.success || result.data == null) return null;

    try {
      DebugLogger.info('Saving to device', tag: _tag);

      Directory? directory;

      if (Platform.isAndroid) {
        // Try Documents first, then Download
        directory = Directory('/storage/emulated/0/Documents');
        if (!await directory.exists()) {
          directory = Directory('/storage/emulated/0/Download');
        }
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) return null;

      // Create DayFlow folder with month organization
      final monthFolder = DateFormat('yyyy-MM').format(DateTime.now());
      final dayflowDir = Directory('${directory.path}/DayFlow/$monthFolder');

      if (!await dayflowDir.exists()) {
        await dayflowDir.create(recursive: true);
      }

      // Save file
      final filePath = '${dayflowDir.path}/${result.fileName}';
      final file = File(filePath);
      await file.writeAsString(result.data!);

      DebugLogger.success('File saved', tag: _tag, data: filePath);
      return filePath;
    } catch (e) {
      DebugLogger.error('Failed to save to device', tag: _tag, error: e);
      return null;
    }
  }

  /// Pick file for import
  Future<String?> pickFileForImport() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'csv'],
        withData: true,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();

        DebugLogger.success(
          'File picked',
          tag: _tag,
          data: result.files.single.name,
        );
        return content;
      }

      return null;
    } catch (e) {
      DebugLogger.error('Failed to pick file', tag: _tag, error: e);
      return null;
    }
  }

  /// Clear all data with optional backup
  Future<bool> clearAllData({bool createBackup = true}) async {
    try {
      if (createBackup) {
        DebugLogger.info('Creating backup before clear', tag: _tag);

        final backup = await exportToJSON(
          includeCompleted: true,
          includeSettings: true,
        );

        if (backup.success) {
          await saveToDevice(backup);
        }
      }

      await _taskRepository.clearAllTasks();
      await _settingsRepository.clearSettings();

      DebugLogger.success('All data cleared', tag: _tag);
      return true;
    } catch (e) {
      DebugLogger.error('Failed to clear data', tag: _tag, error: e);
      return false;
    }
  }

  // ============= HELPER METHODS =============

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

  TaskModel _taskFromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled',
      description: json['description'],
      isNote: json['isNote'] ?? false,
      priority: json['priority'] ?? 3,
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

  String _generateFileName(String prefix, String extension) {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return 'dayflow_${prefix}_$timestamp.$extension';
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  List<String> _parseCsvLine(String line) {
    final fields = <String>[];
    var current = '';
    var inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current += '"';
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        fields.add(current.trim());
        current = '';
      } else {
        current += char;
      }
    }

    fields.add(current.trim());
    return fields;
  }

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
      md.writeln(
        '  📅 ${DateFormat('yyyy-MM-dd HH:mm').format(task.dueDate!)}',
      );
    }

    md.writeln();
  }

  // Getters
  bool get canQuickExport {
    if (_lastExportTime == null) return false;
    return DateTime.now().difference(_lastExportTime!).inSeconds < 30;
  }

  Duration get timeSinceLastExport {
    if (_lastExportTime == null) return const Duration(days: 999);
    return DateTime.now().difference(_lastExportTime!);
  }
}

// ============= MODELS =============

class ExportResult {
  final bool success;
  final String? data;
  final String? fileName;
  final int? itemCount;
  final String? format;
  final String? error;

  ExportResult({
    required this.success,
    this.data,
    this.fileName,
    this.itemCount,
    this.format,
    this.error,
  });

  String get formattedSize {
    if (data == null) return 'Unknown';
    final bytes = data!.length;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class ImportResult {
  final bool success;
  final int? importedCount;
  final int? failedCount;
  final List<String>? errors;
  final String? error;

  ImportResult({
    required this.success,
    this.importedCount,
    this.failedCount,
    this.errors,
    this.error,
  });

  double get successRate {
    final total = (importedCount ?? 0) + (failedCount ?? 0);
    if (total == 0) return 0;
    return (importedCount ?? 0) / total;
  }
}

class ImportValidation {
  final bool isValid;
  final String? format;
  final int? totalItems;
  final int? version;
  final bool hasSettings;
  final String? error;

  ImportValidation({
    required this.isValid,
    this.format,
    this.totalItems,
    this.version,
    this.hasSettings = false,
    this.error,
  });
}
