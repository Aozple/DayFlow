import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class HabitModel {
  static const String _tag = 'HabitModel';

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

  // Habit-specific fields
  final HabitFrequency frequency;
  final List<int>? weekdays; // 1-7 (Monday-Sunday) for weekly habits
  final int? monthDay; // 1-31 for monthly habits
  final int? customInterval; // For custom frequency (every X days)
  final TimeOfDay? preferredTime;

  // End conditions
  final HabitEndCondition endCondition;
  final DateTime? endDate;
  final int? targetCount;

  // Habit type
  final HabitType habitType;
  final int? targetValue; // For quantifiable habits
  final String? unit; // "glasses", "minutes", "pages", etc.

  // Tracking
  final int currentStreak;
  final int longestStreak;
  final int totalCompletions;
  final DateTime? lastCompletedDate;

  // Validation constants
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
       createdAt = createdAt ?? DateTime.now(),
       startDate = startDate ?? createdAt ?? DateTime.now(),
       tags = tags ?? [] {
    _validateModel();
  }

  void _validateModel() {
    if (title.isEmpty) {
      throw ArgumentError('Title cannot be empty');
    }
    if (title.length > maxTitleLength) {
      throw ArgumentError('Title too long (max $maxTitleLength characters)');
    }
    if (description != null && description!.length > maxDescriptionLength) {
      throw ArgumentError(
        'Description too long (max $maxDescriptionLength characters)',
      );
    }
    if (!_isValidHexColor(color)) {
      throw ArgumentError('Invalid color format');
    }
    if (startDate.isBefore(createdAt)) {
      throw ArgumentError('Start date cannot be before creation date');
    }
    if (tags.length > maxTags) {
      throw ArgumentError('Too many tags (max $maxTags)');
    }
    for (final tag in tags) {
      if (tag.length > maxTagLength) {
        throw ArgumentError(
          'Tag "$tag" too long (max $maxTagLength characters)',
        );
      }
    }

    // Habit-specific validations
    _validateFrequency();
    _validateEndCondition();
    _validateHabitType();
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
        // No additional validation needed
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
        if (endDate!.isBefore(DateTime.now())) {
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
        // No additional validation needed
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

  static bool _isValidHexColor(String color) {
    final regex = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$');
    return regex.hasMatch(color);
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
      // Safe parsing helpers
      DateTime? parseDate(String? dateStr) {
        if (dateStr == null || dateStr.isEmpty) return null;
        try {
          return DateTime.parse(dateStr);
        } catch (e) {
          DebugLogger.warning('Invalid date format', tag: _tag, data: dateStr);
          return null;
        }
      }

      TimeOfDay? parseTime(Map<String, dynamic>? timeMap) {
        if (timeMap == null) return null;
        try {
          return TimeOfDay(
            hour: timeMap['hour'] as int,
            minute: timeMap['minute'] as int,
          );
        } catch (e) {
          DebugLogger.warning('Invalid time format', tag: _tag, data: timeMap);
          return null;
        }
      }

      List<String> parseTags() {
        try {
          if (map['tags'] != null) {
            return List<String>.from(map['tags'])
                .where((tag) => tag.isNotEmpty && tag.length <= maxTagLength)
                .take(maxTags)
                .toList();
          }
        } catch (e) {
          DebugLogger.warning(
            'Error parsing tags',
            tag: _tag,
            data: e.toString(),
          );
        }
        return [];
      }

      final habit = HabitModel(
        id: map['id'] as String? ?? const Uuid().v4(),
        title: (map['title'] as String? ?? 'Untitled Habit').substring(
          0,
          (map['title'] as String? ?? 'Untitled Habit').length.clamp(
            0,
            maxTitleLength,
          ),
        ),
        description: map['description'] as String?,
        createdAt: parseDate(map['createdAt'] as String?) ?? DateTime.now(),
        startDate:
            parseDate(map['startDate'] as String?) ??
            parseDate(map['createdAt'] as String?) ??
            DateTime.now(),
        isDeleted: map['isDeleted'] as bool? ?? false,
        color: map['color'] as String? ?? '#6C63FF',
        tags: parseTags(),
        hasNotification: map['hasNotification'] as bool? ?? false,
        notificationMinutesBefore: map['notificationMinutesBefore'] as int?,
        frequency: HabitFrequency.values.firstWhere(
          (f) => f.name == map['frequency'],
          orElse: () => HabitFrequency.daily,
        ),
        weekdays:
            map['weekdays'] != null ? List<int>.from(map['weekdays']) : null,
        monthDay: map['monthDay'] as int?,
        customInterval: map['customInterval'] as int?,
        preferredTime: parseTime(map['preferredTime'] as Map<String, dynamic>?),
        endCondition: HabitEndCondition.values.firstWhere(
          (e) => e.name == map['endCondition'],
          orElse: () => HabitEndCondition.never,
        ),
        endDate: parseDate(map['endDate'] as String?),
        targetCount: map['targetCount'] as int?,
        habitType: HabitType.values.firstWhere(
          (t) => t.name == map['habitType'],
          orElse: () => HabitType.simple,
        ),
        targetValue: map['targetValue'] as int?,
        unit: map['unit'] as String?,
        currentStreak: map['currentStreak'] as int? ?? 0,
        longestStreak: map['longestStreak'] as int? ?? 0,
        totalCompletions: map['totalCompletions'] as int? ?? 0,
        lastCompletedDate: parseDate(map['lastCompletedDate'] as String?),
      );

      DebugLogger.verbose(
        'Habit deserialized',
        tag: _tag,
        data: 'ID: ${habit.id}',
      );
      return habit;
    } catch (e) {
      DebugLogger.error('Failed to deserialize habit', tag: _tag, error: e);
      // Return a minimal valid habit instead of crashing
      return HabitModel(
        id: map['id'] as String? ?? const Uuid().v4(),
        title: 'Error loading habit',
        isDeleted: true,
        frequency: HabitFrequency.daily,
      );
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

  // Computed properties
  bool get isActive => !isDeleted && !_hasEnded;

  bool get _hasEnded {
    switch (endCondition) {
      case HabitEndCondition.onDate:
        return endDate != null && DateTime.now().isAfter(endDate!);
      case HabitEndCondition.afterCount:
        return targetCount != null && totalCompletions >= targetCount!;
      case HabitEndCondition.never:
      case HabitEndCondition.manual:
        return false;
    }
  }

  bool get shouldShowToday {
    if (!isActive) return false;

    final today = DateTime.now();
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
      // For quantifiable habits, this would be calculated based on today's progress
      return 0.0; // Will be implemented with HabitInstanceModel
    }
  }

  String get frequencyLabel {
    switch (frequency) {
      case HabitFrequency.daily:
        return 'Daily';
      case HabitFrequency.weekly:
        if (weekdays != null && weekdays!.isNotEmpty) {
          if (weekdays!.length == 7) {
            return 'Every day';
          } else if (weekdays!.length == 1) {
            return 'Every ${_getWeekdayName(weekdays!.first)}';
          } else {
            return '${weekdays!.length} days/week';
          }
        }
        return 'Weekly';
      case HabitFrequency.monthly:
        return 'Monthly (day $monthDay)';
      case HabitFrequency.custom:
        if (customInterval == 1) {
          return 'Daily';
        } else if (customInterval == 7) {
          return 'Weekly';
        } else {
          return 'Every $customInterval days';
        }
    }
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

// Enums
enum HabitFrequency { daily, weekly, monthly, custom }

enum HabitEndCondition { never, onDate, afterCount, manual }

enum HabitType { simple, quantifiable }
