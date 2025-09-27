import 'package:dayflow/core/constants/app_constants.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:dayflow/data/models/habit_model.dart';
import 'package:dayflow/data/models/habit_instance_model.dart';
import 'package:dayflow/data/repositories/base/base_repository.dart';
import 'package:dayflow/data/repositories/interfaces/habit_repository_interface.dart';
import 'package:get_it/get_it.dart';

class HabitRepository extends BaseRepository<HabitModel>
    implements IHabitRepository {
  static const String _tag = 'HabitRepo';

  // Instance management
  late final BaseRepository<HabitInstanceModel> _instanceRepo;

  HabitRepository() : super(boxName: AppConstants.habitsBox, tag: _tag) {
    _instanceRepo = GetIt.I<HabitInstanceRepository>();
  }

  @override
  HabitModel fromMap(Map<String, dynamic> map) => HabitModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(HabitModel item) => item.toMap();

  @override
  String getId(HabitModel item) => item.id;

  @override
  bool isDeleted(HabitModel item) => item.isDeleted;

  // Habit methods
  @override
  Future<String> addHabit(HabitModel habit) async {
    final id = await add(habit);
    await generateInstances(habit);
    return id;
  }

  @override
  HabitModel? getHabit(String id) {
    return get(id);
  }

  @override
  List<HabitModel> getAllHabits() {
    final habits = getAll();
    habits.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return habits;
  }

  @override
  Future<void> updateHabit(HabitModel habit) async {
    await update(habit);
    await _regenerateInstances(habit);
  }

  @override
  Future<void> deleteHabit(String id) async {
    final habit = getHabit(id);
    if (habit != null) {
      final deletedHabit = habit.copyWith(isDeleted: true);
      await updateHabit(deletedHabit);
      await _deleteHabitInstances(id);
    }
  }

  // Instance methods
  @override
  Future<void> addInstance(HabitInstanceModel instance) async {
    await _instanceRepo.add(instance);
  }

  @override
  HabitInstanceModel? getInstance(String id) {
    return _instanceRepo.get(id);
  }

  @override
  List<HabitInstanceModel> getInstancesByHabitId(String habitId) {
    final instances =
        _instanceRepo.getAll().where((i) => i.habitId == habitId).toList();
    instances.sort((a, b) => a.date.compareTo(b.date));
    return instances;
  }

  @override
  List<HabitInstanceModel> getInstancesByDate(DateTime date) {
    return _instanceRepo
        .getAll()
        .where((i) => _isSameDay(i.date, date))
        .toList();
  }

  @override
  Future<void> updateInstance(HabitInstanceModel instance) async {
    await _instanceRepo.update(instance);

    if (instance.status == HabitInstanceStatus.completed) {
      await _updateHabitStreak(instance.habitId);
    }
  }

  @override
  Future<void> completeInstance(String instanceId, {int? value}) async {
    final instance = getInstance(instanceId);
    if (instance != null) {
      final updated = instance.copyWith(
        status: HabitInstanceStatus.completed,
        completedAt: DateTime.now(),
        value: value,
      );
      await updateInstance(updated);
    }
  }

  // Instance generation
  @override
  Future<void> generateInstances(
    HabitModel habit, {
    int daysAhead = AppConstants.defaultDaysAhead,
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
          final existing = await _getInstanceForDate(habit.id, currentDate);

          if (existing == null) {
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

      DebugLogger.success('Generated $generatedCount instances', tag: tag);
    } catch (e) {
      DebugLogger.error('Failed to generate instances', tag: tag, error: e);
    }
  }

  Future<void> _regenerateInstances(HabitModel habit) async {
    final instances = getInstancesByHabitId(habit.id);
    final today = DateTime.now();

    // Remove future pending instances
    for (final instance in instances) {
      if (instance.date.isAfter(today) &&
          instance.status == HabitInstanceStatus.pending) {
        await _instanceRepo.delete(instance.id);
      }
    }

    await generateInstances(habit);
  }

  Future<void> _deleteHabitInstances(String habitId) async {
    final instances = getInstancesByHabitId(habitId);
    final today = DateTime.now();

    for (final instance in instances) {
      if (instance.date.isAfter(today) || _isSameDay(instance.date, today)) {
        final deleted = instance.copyWith(isDeleted: true);
        await updateInstance(deleted);
      }
    }
  }

  // Streak management
  Future<void> _updateHabitStreak(String habitId) async {
    try {
      final habit = getHabit(habitId);
      if (habit == null) return;

      final instances = getInstancesByHabitId(habitId);
      instances.sort((a, b) => b.date.compareTo(a.date));

      final streakData = _calculateStreak(habit, instances);
      final totalCompletions =
          instances
              .where((i) => i.status == HabitInstanceStatus.completed)
              .length;

      final updated = habit.copyWith(
        currentStreak: streakData.current,
        longestStreak:
            streakData.longest > habit.longestStreak
                ? streakData.longest
                : habit.longestStreak,
        totalCompletions: totalCompletions,
        lastCompletedDate: streakData.lastCompletedDate,
      );

      await update(updated);
      DebugLogger.info('Streak updated', tag: tag);
    } catch (e) {
      DebugLogger.error('Failed to update streak', tag: tag, error: e);
    }
  }

  ({int current, int longest, DateTime? lastCompletedDate}) _calculateStreak(
    HabitModel habit,
    List<HabitInstanceModel> instances,
  ) {
    int currentStreak = 0;
    int longestStreak = 0;
    DateTime? lastCompletedDate;

    // Calculation logic stays the same
    for (final instance in instances) {
      if (instance.status == HabitInstanceStatus.completed) {
        currentStreak++;
        longestStreak =
            longestStreak > currentStreak ? longestStreak : currentStreak;
        lastCompletedDate ??= instance.completedAt;
      } else if (instance.status == HabitInstanceStatus.pending &&
          instance.date.isBefore(DateTime.now())) {
        currentStreak = 0;
      }
    }

    return (
      current: currentStreak,
      longest: longestStreak,
      lastCompletedDate: lastCompletedDate,
    );
  }

  // Helper methods
  bool _shouldGenerateInstance(HabitModel habit, DateTime date) {
    final startDateOnly = DateTime(
      habit.startDate.year,
      habit.startDate.month,
      habit.startDate.day,
    );

    if (date.isBefore(startDateOnly)) return false;
    if (_hasHabitEnded(habit, date)) return false;

    return _matchesFrequencyPattern(habit, date);
  }

  bool _hasHabitEnded(HabitModel habit, DateTime date) {
    switch (habit.endCondition) {
      case HabitEndCondition.onDate:
        return habit.endDate != null && date.isAfter(habit.endDate!);
      case HabitEndCondition.afterCount:
        return habit.targetCount != null &&
            habit.totalCompletions >= habit.targetCount!;
      default:
        return false;
    }
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
        final daysDiff = date.difference(habit.startDate).inDays;
        return daysDiff >= 0 && daysDiff % habit.customInterval! == 0;
    }
  }

  Future<HabitInstanceModel?> _getInstanceForDate(
    String habitId,
    DateTime date,
  ) async {
    final instances = getInstancesByHabitId(habitId);
    try {
      return instances.firstWhere((i) => _isSameDay(i.date, date));
    } catch (_) {
      return null;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Future<void> clearAllHabits() async {
    await clearAll();
    await _instanceRepo.clearAll();
  }

  @override
  Map<String, dynamic> getStatistics() {
    final habits = getAllHabits();
    final today = DateTime.now();
    final todayInstances = getInstancesByDate(today);

    return {
      'totalHabits': habits.length,
      'activeHabits': habits.where((h) => h.isActive).length,
      'todayTotal': todayInstances.length,
      'todayCompleted': todayInstances.where((i) => i.isCompleted).length,
      'todayPending': todayInstances.where((i) => i.isPending).length,
      'completionRate':
          todayInstances.isEmpty
              ? 0.0
              : todayInstances.where((i) => i.isCompleted).length /
                  todayInstances.length,
    };
  }
}

// Separate repository for HabitInstance
class HabitInstanceRepository extends BaseRepository<HabitInstanceModel> {
  HabitInstanceRepository()
    : super(boxName: AppConstants.habitInstancesBox, tag: 'HabitInstanceRepo');

  @override
  HabitInstanceModel fromMap(Map<String, dynamic> map) =>
      HabitInstanceModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(HabitInstanceModel item) => item.toMap();

  @override
  String getId(HabitInstanceModel item) => item.id;

  @override
  bool isDeleted(HabitInstanceModel item) => item.isDeleted;
}
