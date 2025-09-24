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
  final ImportType? type;

  ImportResult({
    required this.success,
    this.importedCount,
    this.failedCount,
    this.errors,
    this.error,
    this.type,
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
  final bool hasTasks;
  final bool hasHabits;
  final String? error;

  ImportValidation({
    required this.isValid,
    this.format,
    this.totalItems,
    this.version,
    this.hasSettings = false,
    this.hasTasks = false,
    this.hasHabits = false,
    this.error,
  });
}

enum ImportType { tasks, habits, all }

enum ExportFormat { json, csv, markdown }
