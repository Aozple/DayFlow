import 'package:dayflow/core/constants/statistics_constants.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:dayflow/presentation/blocs/habits/habit_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';

class HeatMapStatisticsService {
  const HeatMapStatisticsService._();

  static List<Map<String, dynamic>> generateHeatMapData(
    TaskLoaded taskState,
    HabitLoaded habitState,
  ) {
    DebugLogger.debug(
      'Starting heat map data generation',
      tag: StatisticsConstants.logTag,
    );

    try {
      final data = <Map<String, dynamic>>[];
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (int i = StatisticsConstants.heatMapDays - 1; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));

        final dayTasks = _getTasksForDate(taskState, date);
        final dayHabits = _getHabitsForDate(habitState, date);

        final totalActivities = dayTasks + dayHabits;
        final level = _getActivityLevel(totalActivities);
        final isPerfectDay =
            totalActivities >= StatisticsConstants.perfectDayMinActivities;

        data.add({
          'date': date,
          'activities': totalActivities,
          'tasks': dayTasks,
          'habits': dayHabits,
          'level': level,
          'isPerfectDay': isPerfectDay,
        });
      }

      DebugLogger.success(
        'Heat map data generated',
        tag: StatisticsConstants.logTag,
        data: {
          'totalDays': data.length,
          'perfectDays': data.where((d) => d['isPerfectDay'] == true).length,
          'totalActivities': data.fold(
            0,
            (sum, d) => sum + (d['activities'] as int),
          ),
        },
      );

      return data;
    } catch (e, stackTrace) {
      DebugLogger.error(
        'Failed to generate heat map data',
        tag: StatisticsConstants.logTag,
        error: e,
        stackTrace: stackTrace,
      );
      return getDefaultHeatMapData();
    }
  }

  static int _getTasksForDate(TaskLoaded taskState, DateTime date) {
    return taskState.tasks.where((task) {
      if (task.completedAt == null) return false;
      return _isSameDay(task.completedAt!, date);
    }).length;
  }

  static int _getHabitsForDate(HabitLoaded habitState, DateTime date) {
    return habitState.todayInstances.where((instance) {
      return _isSameDay(instance.date, date) && instance.isCompleted;
    }).length;
  }

  static int _getActivityLevel(int activities) {
    if (activities == 0) return 0;

    for (final entry in StatisticsConstants.activityLevels.entries) {
      if (activities <= entry.key) {
        return entry.value;
      }
    }

    return 4;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static List<Map<String, dynamic>> getDefaultHeatMapData() {
    DebugLogger.warning(
      'Using default heat map data',
      tag: StatisticsConstants.logTag,
    );

    final data = <Map<String, dynamic>>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int i = StatisticsConstants.heatMapDays - 1; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      data.add({
        'date': date,
        'activities': 0,
        'tasks': 0,
        'habits': 0,
        'level': 0,
        'isPerfectDay': false,
      });
    }

    return data;
  }
}
