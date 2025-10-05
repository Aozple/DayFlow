import 'package:dayflow/core/utils/debug_logger.dart';

class ValidationUtils {
  ValidationUtils._();

  static const int maxTitleLength = 200;
  static const int maxDescriptionLength = 1000;
  static const int maxTagLength = 30;
  static const int minPriority = 1;
  static const int maxPriority = 5;
  static const int minEstimatedMinutes = 1;
  static const int maxEstimatedMinutes = 1440;
  static const int maxTags = 10;

  static String? validateTitle(String? title) {
    if (title == null || title.isEmpty) {
      return 'Title cannot be empty';
    }
    if (title.length > maxTitleLength) {
      return 'Title too long (max $maxTitleLength characters)';
    }
    return null;
  }

  static String? validateDescription(String? description) {
    if (description != null && description.length > maxDescriptionLength) {
      return 'Description too long (max $maxDescriptionLength characters)';
    }
    return null;
  }

  static String validateAndTrimTitle(
    String? title,
    int maxLength,
    String fallback,
  ) {
    final cleanTitle = title?.trim() ?? fallback;
    if (cleanTitle.length > maxLength) {
      DebugLogger.warning(
        'Title truncated',
        tag: 'ValidationUtils',
        data: '${cleanTitle.length} -> $maxLength',
      );
      return cleanTitle.substring(0, maxLength);
    }
    return cleanTitle;
  }

  static int validatePriority(
    dynamic value,
    int min,
    int max,
    int defaultValue,
  ) {
    if (value == null) return defaultValue;
    if (value is int) {
      return value.clamp(min, max);
    }
    try {
      final parsed = int.parse(value.toString());
      return parsed.clamp(min, max);
    } catch (_) {
      return defaultValue;
    }
  }

  static int? validateMinutes(dynamic value, int min, int max) {
    if (value == null) return null;
    if (value is int) {
      return value.clamp(min, max);
    }
    try {
      final parsed = int.parse(value.toString());
      return parsed.clamp(min, max);
    } catch (_) {
      return null;
    }
  }

  static int validateHeadingLevel(dynamic level) {
    if (level == null) return 1;
    if (level is int) {
      return level.clamp(1, 6);
    }
    try {
      final parsed = int.parse(level.toString());
      return parsed.clamp(1, 6);
    } catch (_) {
      return 1;
    }
  }
}
