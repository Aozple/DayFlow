import 'package:dayflow/core/utils/app_color_utils.dart';
import 'package:dayflow/core/utils/app_date_utils.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class HabitModel {
  static const String _tag = 'HabitModel';

  static final Map<String, bool> _validationCache = {};

  static final Map<String, HabitFrequency> _frequencyMap = {
    for (var f in HabitFrequency.values) f.name: f,
  };

  static final Map<String, HabitEndCondition> _endConditionMap = {
    for (var e in HabitEndCondition.values) e.name: e,
  };

  static final Map<String, HabitType> _habitTypeMap = {
    for (var t in HabitType.values) t.name: t,
  };

  final String id;
  final String title;
  final String? description;
  final DateTime createdAt;
  final DateTime startDate;
  final bool isDeleted;
  final String color;
  final List<String> tags;
  final bool hasNotification;
  final int? notificationMinutesBefore;

  final HabitFrequency frequency;
  final List<int>? weekdays;
  final int? monthDay;
  final int? customInterval;
  final TimeOfDay? preferredTime;

  final HabitEndCondition endCondition;
  final DateTime? endDate;
  final int? targetCount;

  final HabitType habitType;
  final int? targetValue;
  final String? unit;

  final int currentStreak;
  final int longestStreak;
  final int totalCompletions;
  final DateTime? lastCompletedDate;

  String? _cachedFrequencyLabel;
  String? _lastFrequencyKey;

  static const int maxTitleLength = 200;
  static const int maxDescriptionLength = 1000;
  static const int maxTags = 10;
  static const int maxTagLength = 30;
  static const int maxTargetValue = 9999;
  static const int maxCustomInterval = 365;

  HabitModel({
    String? id,
    required this.title,
    this.description,
    DateTime? createdAt,
    DateTime? startDate,
    this.isDeleted = false,
    this.color = '#6C63FF',
    List<String>? tags,
    this.hasNotification = false,
    this.notificationMinutesBefore,
    required this.frequency,
    this.weekdays,
    this.monthDay,
    this.customInterval,
    this.preferredTime,
    this.endCondition = HabitEndCondition.never,
    this.endDate,
    this.targetCount,
    this.habitType = HabitType.simple,
    this.targetValue,
    this.unit,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalCompletions = 0,
    this.lastCompletedDate,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? AppDateUtils.now,
       startDate = startDate ?? createdAt ?? AppDateUtils.now,
       tags = tags ?? [] {
    _validateModel();
  }

  void _validateModel() {
    final validationKey =
        '${title.length}-$color-${tags.length}-${frequency.name}-${habitType.name}';

    if (_validationCache.containsKey(validationKey)) {
      if (!_validationCache[validationKey]!) {
        throw ArgumentError('Invalid model data (cached)');
      }
      return;
    }

    try {
      if (title.isEmpty) {
        _cacheInvalidResult(validationKey);
        throw ArgumentError('Title cannot be empty');
      }

      if (title.length > maxTitleLength) {
        _cacheInvalidResult(validationKey);
        throw ArgumentError('Title too long (max $maxTitleLength characters)');
      }

      if (tags.length > maxTags) {
        _cacheInvalidResult(validationKey);
        throw ArgumentError('Too many tags (max $maxTags)');
      }

      if (!AppColorUtils.isValidHex(color)) {
        _cacheInvalidResult(validationKey);
        throw ArgumentError('Invalid color format');
      }

      if (description != null && description!.length > maxDescriptionLength) {
        _cacheInvalidResult(validationKey);
        throw ArgumentError(
          'Description too long (max $maxDescriptionLength characters)',
        );
      }

      for (int i = 0; i < tags.length; i++) {
        if (tags[i].length > maxTagLength) {
          _cacheInvalidResult(validationKey);
          throw ArgumentError(
            'Tag "${tags[i]}" too long (max $maxTagLength characters)',
          );
        }
      }

      _validateFrequency();
      _validateEndCondition();
      _validateHabitType();

      _cacheValidResult(validationKey);
    } catch (e) {
      _cacheInvalidResult(validationKey);
      rethrow;
    }
  }

  void _cacheValidResult(String key) {
    if (_validationCache.length < 100) {
      _validationCache[key] = true;
    }
  }

  void _cacheInvalidResult(String key) {
    if (_validationCache.length < 100) {
      _validationCache[key] = false;
    }
  }

  static void clearValidationCache() {
    _validationCache.clear();
  }

  void _validateFrequency() {
    switch (frequency) {
      case HabitFrequency.weekly:
        if (weekdays == null || weekdays!.isEmpty) {
          throw ArgumentError('Weekly habits must have weekdays specified');
        }
        if (weekdays!.any((day) => day < 1 || day > 7)) {
          throw ArgumentError('Weekdays must be between 1-7');
        }
        break;
      case HabitFrequency.monthly:
        if (monthDay == null || monthDay! < 1 || monthDay! > 31) {
          throw ArgumentError(
            'Monthly habits must have valid month day (1-31)',
          );
        }
        break;
      case HabitFrequency.custom:
        if (customInterval == null ||
            customInterval! < 1 ||
            customInterval! > maxCustomInterval) {
          throw ArgumentError(
            'Custom interval must be between 1-$maxCustomInterval days',
          );
        }
        break;
      case HabitFrequency.daily:
        break;
    }
  }

  void _validateEndCondition() {
    switch (endCondition) {
      case HabitEndCondition.onDate:
        if (endDate == null) {
          throw ArgumentError(
            'End date must be specified for date-based end condition',
          );
        }
        if (endDate!.isBefore(AppDateUtils.now)) {
          throw ArgumentError('End date cannot be in the past');
        }
        break;
      case HabitEndCondition.afterCount:
        if (targetCount == null || targetCount! < 1) {
          throw ArgumentError('Target count must be specified and positive');
        }
        break;
      case HabitEndCondition.never:
      case HabitEndCondition.manual:
        break;
    }
  }

  void _validateHabitType() {
    if (habitType == HabitType.quantifiable) {
      if (targetValue == null ||
          targetValue! < 1 ||
          targetValue! > maxTargetValue) {
        throw ArgumentError(
          'Target value must be between 1-$maxTargetValue for quantifiable habits',
        );
      }
      if (unit == null || unit!.isEmpty) {
        throw ArgumentError('Unit must be specified for quantifiable habits');
      }
    }
  }

  Map<String, dynamic> toMap() {
    try {
      final map = {
        'id': id,
        'title': title,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'startDate': startDate.toIso8601String(),
        'isDeleted': isDeleted,
        'color': color,
        'tags': tags,
        'hasNotification': hasNotification,
        'notificationMinutesBefore': notificationMinutesBefore,
        'frequency': frequency.name,
        'weekdays': weekdays,
        'monthDay': monthDay,
        'customInterval': customInterval,
        'preferredTime':
            preferredTime != null
                ? {'hour': preferredTime!.hour, 'minute': preferredTime!.minute}
                : null,
        'endCondition': endCondition.name,
        'endDate': endDate?.toIso8601String(),
        'targetCount': targetCount,
        'habitType': habitType.name,
        'targetValue': targetValue,
        'unit': unit,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'totalCompletions': totalCompletions,
        'lastCompletedDate': lastCompletedDate?.toIso8601String(),
      };

      DebugLogger.verbose('Habit serialized', tag: _tag, data: 'ID: $id');
      return map;
    } catch (e) {
      DebugLogger.error('Failed to serialize habit', tag: _tag, error: e);
      rethrow;
    }
  }

  factory HabitModel.fromMap(Map<String, dynamic> map) {
    try {
      TimeOfDay? parseTime(dynamic timeData) {
        if (timeData is! Map<String, dynamic>) return null;

        try {
          final hour = timeData['hour'];
          final minute = timeData['minute'];

          if (hour is int &&
              minute is int &&
              hour >= 0 &&
              hour <= 23 &&
              minute >= 0 &&
              minute <= 59) {
            return TimeOfDay(hour: hour, minute: minute);
          }
        } catch (e) {
          DebugLogger.warning('Invalid time format', tag: _tag, data: timeData);
        }
        return null;
      }

      List<String> parseTags() {
        final tagsData = map['tags'];
        if (tagsData is! List) return [];

        final result = <String>[];

        for (int i = 0; i < tagsData.length && result.length < maxTags; i++) {
          final tag = tagsData[i]?.toString();
          if (tag != null && tag.isNotEmpty && tag.length <= maxTagLength) {
            result.add(tag);
          }
        }

        return result;
      }

      List<int>? parseWeekdays() {
        final weekdaysData = map['weekdays'];
        if (weekdaysData is! List) return null;

        final result = <int>[];

        for (final day in weekdaysData) {
          if (day is int && day >= 1 && day <= 7) {
            result.add(day);
          }
        }

        return result.isNotEmpty ? result : null;
      }

      int? parseIntSafe(dynamic value, {int? min, int? max}) {
        if (value == null) return null;

        int? result;
        if (value is int) {
          result = value;
        } else {
          try {
            result = int.parse(value.toString());
          } catch (_) {
            return null;
          }
        }

        if (min != null && result < min) return null;
        if (max != null && result > max) return null;

        return result;
      }

      String parseStringSafe(dynamic value, String fallback, {int? maxLength}) {
        if (value is! String) return fallback;

        final trimmed = value.trim();
        if (trimmed.isEmpty) return fallback;

        if (maxLength != null && trimmed.length > maxLength) {
          DebugLogger.warning(
            'String truncated',
            tag: _tag,
            data: '${trimmed.length} -> $maxLength',
          );
          return trimmed.substring(0, maxLength);
        }

        return trimmed;
      }

      var endCondition =
          _endConditionMap[map['endCondition']] ?? HabitEndCondition.never;
      var endDate = AppDateUtils.tryParse(map['endDate'] as String?);

      if (endDate != null && endDate.isBefore(AppDateUtils.now)) {
        endCondition = HabitEndCondition.never;
        endDate = null;
        DebugLogger.warning(
          'Fixed corrupted habit with past end date',
          tag: _tag,
        );
      }

      final createdAt =
          AppDateUtils.tryParse(map['createdAt'] as String?) ??
          AppDateUtils.now;
      final startDate =
          AppDateUtils.tryParse(map['startDate'] as String?) ?? createdAt;

      final habit = HabitModel(
        id: map['id'] as String? ?? const Uuid().v4(),

        title: parseStringSafe(
          map['title'],
          'Untitled Habit',
          maxLength: maxTitleLength,
        ),

        description:
            map['description'] is String
                ? parseStringSafe(
                  map['description'],
                  '',
                  maxLength: maxDescriptionLength,
                )
                : null,

        createdAt: createdAt,
        startDate: startDate,
        isDeleted: map['isDeleted'] as bool? ?? false,

        color: AppColorUtils.validateHex(map['color'] as String?) ?? '#6C63FF',

        tags: parseTags(),

        hasNotification: map['hasNotification'] as bool? ?? false,
        notificationMinutesBefore: parseIntSafe(
          map['notificationMinutesBefore'],
          min: 0,
          max: 1440,
        ),

        frequency: _frequencyMap[map['frequency']] ?? HabitFrequency.daily,

        weekdays: parseWeekdays(),

        monthDay: parseIntSafe(map['monthDay'], min: 1, max: 31),

        customInterval: parseIntSafe(
          map['customInterval'],
          min: 1,
          max: maxCustomInterval,
        ),

        preferredTime: parseTime(map['preferredTime']),

        endCondition: endCondition,
        endDate: endDate,

        targetCount: parseIntSafe(map['targetCount'], min: 1),

        habitType: _habitTypeMap[map['habitType']] ?? HabitType.simple,

        targetValue: parseIntSafe(
          map['targetValue'],
          min: 1,
          max: maxTargetValue,
        ),

        unit: map['unit'] is String ? (map['unit'] as String).trim() : null,

        currentStreak: parseIntSafe(map['currentStreak'], min: 0) ?? 0,
        longestStreak: parseIntSafe(map['longestStreak'], min: 0) ?? 0,
        totalCompletions: parseIntSafe(map['totalCompletions'], min: 0) ?? 0,

        lastCompletedDate: AppDateUtils.tryParse(
          map['lastCompletedDate'] as String?,
        ),
      );

      DebugLogger.verbose(
        'Habit deserialized',
        tag: _tag,
        data: 'ID: ${habit.id}',
      );

      return habit;
    } catch (e) {
      DebugLogger.error('Failed to deserialize habit', tag: _tag, error: e);
      rethrow;
    }
  }

  HabitModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? startDate,
    bool? isDeleted,
    String? color,
    List<String>? tags,
    bool? hasNotification,
    int? notificationMinutesBefore,
    HabitFrequency? frequency,
    List<int>? weekdays,
    int? monthDay,
    int? customInterval,
    TimeOfDay? preferredTime,
    HabitEndCondition? endCondition,
    DateTime? endDate,
    int? targetCount,
    HabitType? habitType,
    int? targetValue,
    String? unit,
    int? currentStreak,
    int? longestStreak,
    int? totalCompletions,
    DateTime? lastCompletedDate,
  }) {
    return HabitModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      isDeleted: isDeleted ?? this.isDeleted,
      color: color ?? this.color,
      tags: tags ?? this.tags,
      hasNotification: hasNotification ?? this.hasNotification,
      notificationMinutesBefore:
          notificationMinutesBefore ?? this.notificationMinutesBefore,
      frequency: frequency ?? this.frequency,
      weekdays: weekdays ?? this.weekdays,
      monthDay: monthDay ?? this.monthDay,
      customInterval: customInterval ?? this.customInterval,
      preferredTime: preferredTime ?? this.preferredTime,
      endCondition: endCondition ?? this.endCondition,
      endDate: endDate ?? this.endDate,
      targetCount: targetCount ?? this.targetCount,
      habitType: habitType ?? this.habitType,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalCompletions: totalCompletions ?? this.totalCompletions,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
    );
  }

  bool get isActive => !isDeleted && !_hasEnded;

  bool get _hasEnded {
    switch (endCondition) {
      case HabitEndCondition.onDate:
        return endDate != null && AppDateUtils.now.isAfter(endDate!);
      case HabitEndCondition.afterCount:
        return targetCount != null && totalCompletions >= targetCount!;
      case HabitEndCondition.never:
      case HabitEndCondition.manual:
        return false;
    }
  }

  bool get shouldShowToday {
    if (!isActive) return false;

    final today = AppDateUtils.now;
    switch (frequency) {
      case HabitFrequency.daily:
        return true;
      case HabitFrequency.weekly:
        return weekdays?.contains(today.weekday) ?? false;
      case HabitFrequency.monthly:
        return today.day == monthDay;
      case HabitFrequency.custom:
        if (lastCompletedDate == null) return true;
        final daysSinceLastCompletion =
            today.difference(lastCompletedDate!).inDays;
        return daysSinceLastCompletion >= (customInterval ?? 1);
    }
  }

  double get completionRate {
    if (habitType == HabitType.simple) {
      return totalCompletions > 0 ? 1.0 : 0.0;
    } else {
      return 0.0;
    }
  }

  String get frequencyLabel {
    final frequencyKey =
        '${frequency.name}-${weekdays?.join(",")}-$monthDay-$customInterval';

    if (_lastFrequencyKey == frequencyKey && _cachedFrequencyLabel != null) {
      return _cachedFrequencyLabel!;
    }

    String label;
    switch (frequency) {
      case HabitFrequency.daily:
        label = 'Daily';
        break;
      case HabitFrequency.weekly:
        if (weekdays != null && weekdays!.isNotEmpty) {
          if (weekdays!.length == 7) {
            label = 'Every day';
          } else if (weekdays!.length == 1) {
            label = 'Every ${_getWeekdayName(weekdays!.first)}';
          } else {
            label = '${weekdays!.length} days/week';
          }
        } else {
          label = 'Weekly';
        }
        break;
      case HabitFrequency.monthly:
        label = 'Monthly (day $monthDay)';
        break;
      case HabitFrequency.custom:
        if (customInterval == 1) {
          label = 'Daily';
        } else if (customInterval == 7) {
          label = 'Weekly';
        } else {
          label = 'Every $customInterval days';
        }
        break;
    }

    _cachedFrequencyLabel = label;
    _lastFrequencyKey = frequencyKey;
    return label;
  }

  String _getWeekdayName(int weekday) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[weekday - 1];
  }

  @override
  String toString() {
    return 'HabitModel(id: $id, title: $title, frequency: $frequency, streak: $currentStreak)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HabitModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum HabitFrequency { daily, weekly, monthly, custom }

enum HabitEndCondition { never, onDate, afterCount, manual }

enum HabitType { simple, quantifiable }
