import 'package:flutter/foundation.dart';

enum LogLevel { verbose, debug, info, warning, error, success }

class DebugLogger {
  static const bool _enableLogging = kDebugMode;
  static const LogLevel _minLevel = LogLevel.debug;

  static final Map<LogLevel, String> _levelEmojis = {
    LogLevel.verbose: '🔍',
    LogLevel.debug: '🐛',
    LogLevel.info: '📋',
    LogLevel.warning: '⚠️',
    LogLevel.error: '❌',
    LogLevel.success: '✅',
  };

  static final Map<LogLevel, String> _levelColors = {
    LogLevel.verbose: '\x1B[90m', // Gray
    LogLevel.debug: '\x1B[36m', // Cyan
    LogLevel.info: '\x1B[34m', // Blue
    LogLevel.warning: '\x1B[33m', // Yellow
    LogLevel.error: '\x1B[31m', // Red
    LogLevel.success: '\x1B[32m', // Green
  };

  static const String _resetColor = '\x1B[0m';

  static void log(
    String message, {
    LogLevel level = LogLevel.info,
    String? tag,
    dynamic data,
  }) {
    if (!_enableLogging) return;
    if (level.index < _minLevel.index) return;

    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final emoji = _levelEmojis[level] ?? '';
    final color = _levelColors[level] ?? '';
    final tagStr = tag != null ? '[$tag] ' : '';

    final logMessage = '$color$timestamp $emoji $tagStr$message$_resetColor';

    debugPrint(logMessage);

    if (data != null) {
      debugPrint('$color   └─> Data: $data$_resetColor');
    }
  }

  static void verbose(String message, {String? tag, dynamic data}) {
    log(message, level: LogLevel.verbose, tag: tag, data: data);
  }

  static void debug(String message, {String? tag, dynamic data}) {
    log(message, level: LogLevel.debug, tag: tag, data: data);
  }

  static void info(String message, {String? tag, dynamic data}) {
    log(message, level: LogLevel.info, tag: tag, data: data);
  }

  static void warning(String message, {String? tag, dynamic data}) {
    log(message, level: LogLevel.warning, tag: tag, data: data);
  }

  static void error(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    log(message, level: LogLevel.error, tag: tag, data: error);
    if (stackTrace != null && kDebugMode) {
      debugPrint(
        '$_levelColors[LogLevel.error]Stack trace:\n$stackTrace$_resetColor',
      );
    }
  }

  static void success(String message, {String? tag, dynamic data}) {
    log(message, level: LogLevel.success, tag: tag, data: data);
  }

  // Utility method for operation timing
  static Future<T> timeOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await operation();
      stopwatch.stop();
      success(
        '$operationName completed',
        tag: 'Performance',
        data: '${stopwatch.elapsedMilliseconds}ms',
      );
      return result;
    } catch (e) {
      stopwatch.stop();
      error('$operationName failed', tag: 'Performance', error: e);
      rethrow;
    }
  }
}
