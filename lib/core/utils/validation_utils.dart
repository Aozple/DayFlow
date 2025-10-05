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

  static T _clampValue<T extends num>(
    dynamic value,
    T min,
    T max,
    T defaultValue,
  ) {
    if (value == null) return defaultValue;
    if (value is T) return (value).clamp(min, max) as T;

    try {
      if (T == int) {
        final parsed = int.parse(value.toString());
        return (parsed.clamp(min, max)) as T;
      }
      if (T == double) {
        final parsed = double.parse(value.toString());
        return (parsed.clamp(min, max)) as T;
      }
    } catch (_) {}

    return defaultValue;
  }

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
    return _clampValue(value, min, max, defaultValue);
  }

  static int? validateMinutes(dynamic value, int min, int max) {
    final result = _clampValue(value, min, max, -1);
    return result == -1 ? null : result;
  }

  static int validateHeadingLevel(dynamic level) {
    return _clampValue(level, 1, 6, 1);
  }
}
