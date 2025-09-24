import 'package:dayflow/core/utils/debug_logger.dart';

abstract class BaseImporter {
  final String tag;

  BaseImporter({required this.tag});

  // Parse CSV line
  List<String> parseCsvLine(String line) {
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

  // Safe date parsing
  DateTime? parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      logWarning('Invalid date format: $dateStr');
      return null;
    }
  }

  // Safe int parsing
  int? parseInt(String? value, {int? defaultValue}) {
    if (value == null || value.isEmpty) return defaultValue;
    return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ??
        defaultValue;
  }

  // Log helpers
  void logInfo(String message, {dynamic data}) {
    DebugLogger.info(message, tag: tag, data: data);
  }

  void logSuccess(String message, {dynamic data}) {
    DebugLogger.success(message, tag: tag, data: data);
  }

  void logError(String message, {dynamic error}) {
    DebugLogger.error(message, tag: tag, error: error);
  }

  void logWarning(String message, {dynamic data}) {
    DebugLogger.warning(message, tag: tag, data: data);
  }
}
