import 'package:dayflow/core/constants/app_constants.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:intl/intl.dart';

abstract class BaseExporter {
  final String tag;

  BaseExporter({required this.tag});

  // MARK: - File Naming

  /// Generates a file name with a given prefix and extension.
  String generateFileName(String prefix, String extension) {
    final timestamp = DateFormat(
      AppConstants.exportDateFormat,
    ).format(DateTime.now());
    return '${AppConstants.appName.toLowerCase()}_${prefix}_$timestamp.$extension';
  }

  // MARK: - CSV Helpers

  /// Escapes a string for CSV output.
  String escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  // MARK: - Formatting

  /// Formats a DateTime object to a string.
  String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat(AppConstants.displayDateFormat).format(date);
  }

  /// Formats an integer priority to a string.
  String formatPriority(int priority) {
    return 'P$priority';
  }

  // MARK: - Logging

  /// Logs an informational message.
  void logInfo(String message, {dynamic data}) {
    DebugLogger.info(message, tag: tag, data: data);
  }

  /// Logs a success message.
  void logSuccess(String message, {dynamic data}) {
    DebugLogger.success(message, tag: tag, data: data);
  }

  /// Logs an error message.
  void logError(String message, {dynamic error}) {
    DebugLogger.error(message, tag: tag, error: error);
  }
}
