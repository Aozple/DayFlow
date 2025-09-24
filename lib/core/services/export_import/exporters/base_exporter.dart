import 'package:dayflow/core/constants/app_constants.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:intl/intl.dart';

abstract class BaseExporter {
  final String tag;

  BaseExporter({required this.tag});

  // Generate filename
  String generateFileName(String prefix, String extension) {
    final timestamp = DateFormat(
      AppConstants.exportDateFormat,
    ).format(DateTime.now());
    return '${AppConstants.appName.toLowerCase()}_${prefix}_$timestamp.$extension';
  }

  // CSV helpers
  String escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  // Date formatting
  String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat(AppConstants.displayDateFormat).format(date);
  }

  // Priority formatting
  String formatPriority(int priority) {
    return 'P$priority';
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
}
