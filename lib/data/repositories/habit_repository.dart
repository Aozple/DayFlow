import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:dayflow/data/models/habit_instance_model.dart';
import 'package:dayflow/data/models/habit_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Repository for managing habit data and instances with caching
class HabitRepository {
  static const String _tag = 'HabitRepo';

  // Storage boxes
  final Box _habitBox;
  final Box _instanceBox;

  // Performance cache
  List<HabitModel>? _cachedHabits;
  List<HabitInstanceModel>? _cachedInstances;
  DateTime? _lastCacheUpdate;

  // Constants
  static const Duration _cacheDuration = Duration(seconds: 30);
  static const int _defaultDaysAhead = 30;

  HabitRepository()
    : _habitBox = Hive.box('habits'),
      _instanceBox = Hive.box('habit_instances');

  // === Data Conversion ===

  /// Recursively converts dynamic values to proper types for Hive storage
  dynamic _convertValue(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(
        value.map((k, v) => MapEntry(k.toString(), _convertValue(v))),
      );
    } else if (value is List) {
      return value.map(_convertValue).toList();
    }
    return value;
  }

  /// Safely converts Hive data to typed map
  Map<String, dynamic> _convertToTypedMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;

    if (data is Map) {
      try {
        final converted = <String, dynamic>{};
        data.forEach((key, value) {
          converted[key.toString()] = _convertValue(value);
        });
        return converted;
      } catch (e) {
        DebugLogger.error('Map conversion failed', tag: _tag, error: e);
        rethrow;
      }
    }

    throw Exception(
      'Cannot convert ${data.runtimeType} to Map<String, dynamic>',
    );
  }

  // === Cache Management ===

  void _invalidateCache() {
    _cachedHabits = null;
    _cachedInstances = null;
    _lastCacheUpdate = null;
  }

  bool _isCacheValid() {
    if (_cachedHabits == null ||
        _cachedInstances == null ||
        _lastCacheUpdate == null) {
      return false;
    }
    final age = DateTime.now().difference(_lastCacheUpdate!);
    return age < _cacheDuration;
  }

  // === Habit CRUD Operations ===

  Future<String> addHabit(HabitModel habit) async {
    return DebugLogger.timeOperation('Add Habit', () async {
      try {
        await _habitBox.put(habit.id, habit.toMap());
        _invalidateCache();

        await generateInstances(habit);

        DebugLogger.success(
          'Habit added: ${habit.title}',
          tag: _tag,
          data: 'ID: ${habit.id}',
        );
        return habit.id;
      } catch (e) {
        DebugLogger.error('Failed to add habit', tag: _tag, error: e);
        throw Exception('Failed to add habit: $e');
      }
    });
  }

  HabitModel? getHabit(String id) {
    try {
      // Check cache first
      if (_isCacheValid()) {
        try {
          return _cachedHabits?.firstWhere((h) => h.id == id);
        } catch (_) {
          // Not found in cache, continue to storage
        }
      }

      final habitMap = _habitBox.get(id);
      if (habitMap != null) {
        final typedMap = _convertToTypedMap(habitMap);
        return HabitModel.fromMap(typedMap);
      }

      return null;
    } catch (e) {
      DebugLogger.error('Failed to get habit', tag: _tag, error: e);
      return null;
    }
  }

  List<HabitModel> getAllHabits() {
    try {
      // Return cached if valid
      if (_isCacheValid() && _cachedHabits != null) {
        return _cachedHabits!;
      }

      final stopwatch = Stopwatch()..start();
      final habits = <HabitModel>[];

      for (final key in _habitBox.keys) {
        try {
          final habitMap = _habitBox.get(key);
          if (habitMap != null) {
            final typedMap = _convertToTypedMap(habitMap);
            final habit = HabitModel.fromMap(typedMap);

            if (!habit.isDeleted) {
              habits.add(habit);
            }
          }
        } catch (e) {
          DebugLogger.warning(
            'Skipping corrupted habit: $key',
            tag: _tag,
            data: e.toString(),
          );
          continue;
        }
      }

      // Sort by creation date (newest first)
      habits.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Update cache
      _cachedHabits = habits;
      _lastCacheUpdate = DateTime.now();

      stopwatch.stop();
      DebugLogger.success(
        'Habits loaded successfully',
        tag: _tag,
        data: '${habits.length} habits (${stopwatch.elapsedMilliseconds}ms)',
      );

      return habits;
    } catch (e) {
      DebugLogger.error('Failed to get all habits', tag: _tag, error: e);
      return _cachedHabits ?? [];
    }
  }

  Future<void> updateHabit(HabitModel habit) async {
    return DebugLogger.timeOperation('Update Habit', () async {
      try {
        await _habitBox.put(habit.id, habit.toMap());
        _invalidateCache();

        // Regenerate future instances if schedule changed
        await _regenerateInstances(habit);

        DebugLogger.success('Habit updated: ${habit.title}', tag: _tag);
      } catch (e) {
        DebugLogger.error('Failed to update habit', tag: _tag, error: e);
        throw Exception('Failed to update habit: $e');
      }
    });
  }

  Future<void> deleteHabit(String id) async {
    return DebugLogger.timeOperation('Delete Habit', () async {
      try {
        final habit = getHabit(id);
        if (habit != null) {
          // Soft delete
          final deletedHabit = habit.copyWith(isDeleted: true);
          await updateHabit(deletedHabit);
          await _deleteHabitInstances(id);

          DebugLogger.success('Habit deleted: ${habit.title}', tag: _tag);
        }
      } catch (e) {
        DebugLogger.error('Failed to delete habit', tag: _tag, error: e);
        throw Exception('Failed to delete habit: $e');
      }
    });
  }

  // === Instance CRUD Operations ===

  Future<void> addInstance(HabitInstanceModel instance) async {
    try {
      await _instanceBox.put(instance.id, instance.toMap());
      _invalidateCache();
    } catch (e) {
      DebugLogger.error('Failed to add instance', tag: _tag, error: e);
      throw Exception('Failed to add instance: $e');
    }
  }

  HabitInstanceModel? getInstance(String id) {
    try {
      final instanceMap = _instanceBox.get(id);
      if (instanceMap != null) {
        final typedMap = _convertToTypedMap(instanceMap);
        return HabitInstanceModel.fromMap(typedMap);
      }
      return null;
    } catch (e) {
      DebugLogger.error('Failed to get instance', tag: _tag, error: e);
      return null;
    }
  }

  List<HabitInstanceModel> getInstancesByHabitId(String habitId) {
    try {
      final instances = <HabitInstanceModel>[];

      for (final key in _instanceBox.keys) {
        try {
          final instanceMap = _instanceBox.get(key);
          if (instanceMap != null) {
            final typedMap = _convertToTypedMap(instanceMap);
            final instance = HabitInstanceModel.fromMap(typedMap);

            if (instance.habitId == habitId && !instance.isDeleted) {
              instances.add(instance);
            }
          }
        } catch (e) {
          DebugLogger.warning('Skipping corrupted instance: $key', tag: _tag);
          continue;
        }
      }

      instances.sort((a, b) => a.date.compareTo(b.date));
      return instances;
    } catch (e) {
      DebugLogger.error(
        'Failed to get instances by habit ID',
        tag: _tag,
        error: e,
      );
      return [];
    }
  }

  List<HabitInstanceModel> getInstancesByDate(DateTime date) {
    try {
      // Return cached if valid
      if (_isCacheValid() && _cachedInstances != null) {
        return _cachedInstances!.where((instance) {
          return _isSameDay(instance.date, date) && !instance.isDeleted;
        }).toList();
      }

      final instances = <HabitInstanceModel>[];

      for (final key in _instanceBox.keys) {
        try {
          final instanceMap = _instanceBox.get(key);
          if (instanceMap != null) {
            final typedMap = _convertToTypedMap(instanceMap);
            final instance = HabitInstanceModel.fromMap(typedMap);

            if (_isSameDay(instance.date, date) && !instance.isDeleted) {
              instances.add(instance);
            }
          }
        } catch (e) {
          DebugLogger.warning('Skipping corrupted instance: $key', tag: _tag);
          continue;
        }
      }

      // Update cache
      _cachedInstances = instances;
      _lastCacheUpdate = DateTime.now();

      return instances;
    } catch (e) {
      DebugLogger.error('Failed to get instances by date', tag: _tag, error: e);
      return [];
    }
  }

  Future<void> updateInstance(HabitInstanceModel instance) async {
    try {
      await _instanceBox.put(instance.id, instance.toMap());
      _invalidateCache();

      // Update streak when habit is completed
      if (instance.status == HabitInstanceStatus.completed) {
        await _updateHabitStreak(instance.habitId);
      }
    } catch (e) {
      DebugLogger.error('Failed to update instance', tag: _tag, error: e);
      throw Exception('Failed to update instance: $e');
    }
  }

  Future<void> completeInstance(String instanceId, {int? value}) async {
    return DebugLogger.timeOperation('Complete Instance', () async {
      try {
        final instance = getInstance(instanceId);
        if (instance != null) {
          final updatedInstance = instance.copyWith(
            status: HabitInstanceStatus.completed,
            completedAt: DateTime.now(),
            value: value,
          );
          await updateInstance(updatedInstance);
          DebugLogger.success('Instance completed', tag: _tag);
        }
      } catch (e) {
        DebugLogger.error('Failed to complete instance', tag: _tag, error: e);
        throw Exception('Failed to complete instance: $e');
      }
    });
  }

  // === Instance Generation ===

  Future<void> generateInstances(
    HabitModel habit, {
    int daysAhead = _defaultDaysAhead,
  }) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final endDate = today.add(Duration(days: daysAhead));

      var currentDate = today;
      var generatedCount = 0;

      while (currentDate.isBefore(endDate) ||
          _isSameDay(currentDate, endDate)) {
        if (_shouldGenerateInstance(habit, currentDate)) {
          final existingInstance = await _getInstanceForDate(
            habit.id,
            currentDate,
          );

          if (existingInstance == null) {
            final instance = HabitInstanceModel(
              habitId: habit.id,
              date: currentDate,
              status: HabitInstanceStatus.pending,
            );
            await addInstance(instance);
            generatedCount++;
          }
        }

        currentDate = currentDate.add(const Duration(days: 1));
      }

      DebugLogger.success(
        'Generated $generatedCount instances',
        tag: _tag,
        data: 'Habit: ${habit.title}',
      );
    } catch (e) {
      DebugLogger.error('Failed to generate instances', tag: _tag, error: e);
    }
  }

  Future<void> _regenerateInstances(HabitModel habit) async {
    try {
      final instances = getInstancesByHabitId(habit.id);
      final today = DateTime.now();

      // Remove future pending instances
      for (final instance in instances) {
        if (instance.date.isAfter(today) &&
            instance.status == HabitInstanceStatus.pending) {
          await _instanceBox.delete(instance.id);
        }
      }

      await generateInstances(habit);
    } catch (e) {
      DebugLogger.error('Failed to regenerate instances', tag: _tag, error: e);
    }
  }

  bool _shouldGenerateInstance(HabitModel habit, DateTime date) {
    final startDateOnly = DateTime(
      habit.startDate.year,
      habit.startDate.month,
      habit.startDate.day,
    );
    final checkDateOnly = DateTime(date.year, date.month, date.day);

    if (checkDateOnly.isBefore(startDateOnly)) return false;

    // Don't generate for past dates (before today)
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    if (checkDateOnly.isBefore(todayOnly)) return false;

    // Check end conditions
    if (_hasHabitEnded(habit, date)) return false;

    // Check frequency pattern
    return _matchesFrequencyPattern(habit, date);
  }

  /// Check if habit has reached its end condition
  bool _hasHabitEnded(HabitModel habit, DateTime date) {
    switch (habit.endCondition) {
      case HabitEndCondition.onDate:
        if (habit.endDate != null) {
          final endDateOnly = DateTime(
            habit.endDate!.year,
            habit.endDate!.month,
            habit.endDate!.day,
          );
          final checkDateOnly = DateTime(date.year, date.month, date.day);
          return checkDateOnly.isAfter(endDateOnly);
        }
        break;
      case HabitEndCondition.afterCount:
        if (habit.targetCount != null) {
          return habit.totalCompletions >= habit.targetCount!;
        }
        break;
      case HabitEndCondition.never:
      case HabitEndCondition.manual:
        return false;
    }
    return false;
  }

  bool _matchesFrequencyPattern(HabitModel habit, DateTime date) {
    switch (habit.frequency) {
      case HabitFrequency.daily:
        return true;
      case HabitFrequency.weekly:
        return habit.weekdays?.contains(date.weekday) ?? false;
      case HabitFrequency.monthly:
        return date.day == habit.monthDay;
      case HabitFrequency.custom:
        if (habit.customInterval == null) return false;
        final referenceDate = DateTime(
          habit.startDate.year,
          habit.startDate.month,
          habit.startDate.day,
        );
        final checkDate = DateTime(date.year, date.month, date.day);
        final daysDifference = checkDate.difference(referenceDate).inDays;
        return daysDifference >= 0 &&
            daysDifference % habit.customInterval! == 0;
    }
  }

  Future<HabitInstanceModel?> _getInstanceForDate(
    String habitId,
    DateTime date,
  ) async {
    final instances = getInstancesByHabitId(habitId);
    try {
      return instances.firstWhere(
        (instance) => _isSameDay(instance.date, date),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _deleteHabitInstances(String habitId) async {
    try {
      final instances = getInstancesByHabitId(habitId);
      final today = DateTime.now();

      for (final instance in instances) {
        if (instance.date.isAfter(today) || _isSameDay(instance.date, today)) {
          final deletedInstance = instance.copyWith(isDeleted: true);
          await updateInstance(deletedInstance);
        }
      }
    } catch (e) {
      DebugLogger.error(
        'Failed to delete habit instances',
        tag: _tag,
        error: e,
      );
    }
  }

  // === Streak Management ===

  Future<void> _updateHabitStreak(String habitId) async {
    try {
      final habit = getHabit(habitId);
      if (habit == null) return;

      final instances = getInstancesByHabitId(habitId);
      instances.sort((a, b) => b.date.compareTo(a.date)); // Most recent first

      final streakData = _calculateStreak(habit, instances);
      final totalCompletions =
          instances
              .where((i) => i.status == HabitInstanceStatus.completed)
              .length;

      final updatedHabit = habit.copyWith(
        currentStreak: streakData.current,
        longestStreak:
            streakData.longest > habit.longestStreak
                ? streakData.longest
                : habit.longestStreak,
        totalCompletions: totalCompletions,
        lastCompletedDate: streakData.lastCompletedDate,
      );

      await updateHabit(updatedHabit);

      DebugLogger.info(
        'Streak updated',
        tag: _tag,
        data: 'Current: ${streakData.current}, Longest: ${streakData.longest}',
      );
    } catch (e) {
      DebugLogger.error('Failed to update streak', tag: _tag, error: e);
    }
  }

  /// Calculates current and longest streak for a habit
  ({int current, int longest, DateTime? lastCompletedDate}) _calculateStreak(
    HabitModel habit,
    List<HabitInstanceModel> instances,
  ) {
    int currentStreak = 0;
    int longestStreak = 0;
    DateTime? lastDate;
    DateTime? lastCompletedDate;
    int tempStreak = 0;

    for (final instance in instances) {
      if (instance.status == HabitInstanceStatus.completed) {
        lastCompletedDate ??= instance.completedAt;

        if (lastDate == null) {
          currentStreak = tempStreak = 1;
          lastDate = instance.date;
        } else {
          final daysDifference = lastDate.difference(instance.date).inDays;

          if (_isStreakContinuous(habit, daysDifference)) {
            currentStreak++;
            tempStreak++;
            lastDate = instance.date;
          } else {
            // Streak broken, but continue counting for longest
            longestStreak =
                longestStreak > tempStreak ? longestStreak : tempStreak;
            tempStreak = 1;
            lastDate = instance.date;
            currentStreak = 0; // Current streak is broken
          }
        }
      } else if (instance.status == HabitInstanceStatus.skipped &&
          lastDate != null) {
        // Streak broken by skip
        longestStreak = longestStreak > tempStreak ? longestStreak : tempStreak;
        tempStreak = 0;
        currentStreak = 0;
      }
    }

    // Check final streak
    longestStreak = longestStreak > tempStreak ? longestStreak : tempStreak;

    return (
      current: currentStreak,
      longest: longestStreak,
      lastCompletedDate: lastCompletedDate,
    );
  }

  bool _isStreakContinuous(HabitModel habit, int daysDifference) {
    switch (habit.frequency) {
      case HabitFrequency.daily:
        return daysDifference == 1;
      case HabitFrequency.weekly:
        return daysDifference <= 7;
      case HabitFrequency.monthly:
        return daysDifference <= 31;
      case HabitFrequency.custom:
        return daysDifference == habit.customInterval;
    }
  }

  // === Statistics ===

  Map<String, dynamic> getStatistics() {
    try {
      final allHabits = getAllHabits();
      final today = DateTime.now();
      final todayInstances = getInstancesByDate(today);

      return {
        'totalHabits': allHabits.length,
        'activeHabits': allHabits.where((h) => h.isActive).length,
        'todayTotal': todayInstances.length,
        'todayCompleted': todayInstances.where((i) => i.isCompleted).length,
        'todayPending': todayInstances.where((i) => i.isPending).length,
        'averageStreak': _calculateAverageStreak(allHabits),
        'completionRate': _calculateCompletionRate(todayInstances),
      };
    } catch (e) {
      DebugLogger.error('Failed to get statistics', tag: _tag, error: e);
      return {};
    }
  }

  double _calculateAverageStreak(List<HabitModel> habits) {
    if (habits.isEmpty) return 0.0;
    final totalStreak = habits.fold(
      0,
      (sum, habit) => sum + habit.currentStreak,
    );
    return totalStreak / habits.length;
  }

  double _calculateCompletionRate(List<HabitInstanceModel> instances) {
    if (instances.isEmpty) return 0.0;
    final completed = instances.where((i) => i.isCompleted).length;
    return completed / instances.length;
  }

  // === Utility Methods ===

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> clearAllHabits() async {
    return DebugLogger.timeOperation('Clear All Habits', () async {
      try {
        await _habitBox.clear();
        await _instanceBox.clear();
        _invalidateCache();
        DebugLogger.success('All habits cleared', tag: _tag);
      } catch (e) {
        DebugLogger.error('Failed to clear habits', tag: _tag, error: e);
        throw Exception('Failed to clear all habits: $e');
      }
    });
  }
}
