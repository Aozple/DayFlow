import 'package:dayflow/core/constants/statistics_constants.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:dayflow/presentation/blocs/habits/habit_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';

class TrendsStatisticsService {
  const TrendsStatisticsService._();

  static Map<String, dynamic> calculateWeeklyTrends(
    TaskLoaded taskState,
    HabitLoaded habitState,
  ) {
    DebugLogger.debug(
      'Starting weekly trends calculation',
      tag: StatisticsConstants.logTag,
    );

    try {
      final now = DateTime.now();
      final weekData = <String, dynamic>{};

      for (int i = StatisticsConstants.weekDays - 1; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dayName = _getDayName(date.weekday);

        final dayTasks = taskState.getTasksForDate(date);
        final completedTasks = dayTasks.where((t) => t.isCompleted).length;

        final dayData = {
          'completed': completedTasks,
          'total': dayTasks.length,
          'percentage':
              dayTasks.isEmpty
                  ? 0
                  : (completedTasks / dayTasks.length * 100).round(),
          'date': date,
        };

        weekData[dayName] = dayData;
      }

      DebugLogger.success(
        'Weekly trends calculated',
        tag: StatisticsConstants.logTag,
        data: {'daysCalculated': weekData.length},
      );

      return weekData;
    } catch (e, stackTrace) {
      DebugLogger.error(
        'Failed to calculate weekly trends',
        tag: StatisticsConstants.logTag,
        error: e,
        stackTrace: stackTrace,
      );
      return getDefaultWeeklyTrends();
    }
  }

  static Map<String, dynamic> calculateMonthlyTrends(
    TaskLoaded taskState,
    HabitLoaded habitState,
  ) {
    DebugLogger.debug(
      'Starting monthly trends calculation',
      tag: StatisticsConstants.logTag,
    );

    try {
      final now = DateTime.now();
      final monthData = <String, dynamic>{};
      final weeks = <String, Map<String, dynamic>>{};

      for (int weekIndex = 0; weekIndex < 4; weekIndex++) {
        final weekStartDate = now.subtract(Duration(days: (weekIndex + 1) * 7));
        final weekEndDate = now.subtract(Duration(days: weekIndex * 7));

        int weekTotalTasks = 0;
        int weekCompletedTasks = 0;

        for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
          final date = weekStartDate.add(Duration(days: dayOffset));
          if (date.isAfter(weekEndDate)) break;

          final dayTasks = taskState.getTasksForDate(date);
          final completedTasks = dayTasks.where((t) => t.isCompleted).length;

          weekTotalTasks += dayTasks.length;
          weekCompletedTasks += completedTasks;
        }

        weeks['Week ${4 - weekIndex}'] = {
          'completed': weekCompletedTasks,
          'total': weekTotalTasks,
          'percentage':
              weekTotalTasks == 0
                  ? 0
                  : (weekCompletedTasks / weekTotalTasks * 100).round(),
          'startDate': weekStartDate,
          'endDate': weekEndDate,
        };
      }

      monthData['weeks'] = weeks;

      DebugLogger.success(
        'Monthly trends calculated',
        tag: StatisticsConstants.logTag,
        data: {'weeksCalculated': weeks.length},
      );

      return monthData;
    } catch (e, stackTrace) {
      DebugLogger.error(
        'Failed to calculate monthly trends',
        tag: StatisticsConstants.logTag,
        error: e,
        stackTrace: stackTrace,
      );
      return getDefaultMonthlyTrends();
    }
  }

  static Map<String, dynamic> calculatePerformanceTrends(
    TaskLoaded taskState,
    HabitLoaded habitState,
  ) {
    DebugLogger.debug(
      'Starting performance trends calculation',
      tag: StatisticsConstants.logTag,
    );

    try {
      final trends = <String, dynamic>{};

      final completionRateTrend = _calculateCompletionRateTrend(taskState);
      trends['completionRate'] = completionRateTrend;

      final streakTrend = _calculateStreakTrend(habitState);
      trends['streak'] = streakTrend;

      final productivityTrend = _calculateProductivityTrend(taskState);
      trends['productivity'] = productivityTrend;

      DebugLogger.success(
        'Performance trends calculated',
        tag: StatisticsConstants.logTag,
        data: trends.keys.toList(),
      );

      return trends;
    } catch (e, stackTrace) {
      DebugLogger.error(
        'Failed to calculate performance trends',
        tag: StatisticsConstants.logTag,
        error: e,
        stackTrace: stackTrace,
      );
      return getDefaultPerformanceTrends();
    }
  }

  static Map<String, dynamic> _calculateCompletionRateTrend(
    TaskLoaded taskState,
  ) {
    final now = DateTime.now();
    final rates = <double>[];

    for (int i = StatisticsConstants.weekDays - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayTasks = taskState.getTasksForDate(date);

      if (dayTasks.isNotEmpty) {
        final completed = dayTasks.where((t) => t.isCompleted).length;
        rates.add(completed / dayTasks.length);
      } else {
        rates.add(0.0);
      }
    }

    final trend = rates.length >= 2 ? rates.last - rates.first : 0.0;

    return {
      'rates': rates,
      'trend': trend,
      'direction':
          trend > 0.05
              ? 'improving'
              : trend < -0.05
              ? 'declining'
              : 'stable',
    };
  }

  static Map<String, dynamic> _calculateStreakTrend(HabitLoaded habitState) {
    final currentStreaks =
        habitState.habits.map((h) => h.currentStreak).toList();
    final averageStreak =
        currentStreaks.isEmpty
            ? 0.0
            : currentStreaks.reduce((a, b) => a + b) / currentStreaks.length;

    return {
      'currentStreaks': currentStreaks,
      'averageStreak': averageStreak,
      'longestStreak':
          currentStreaks.isEmpty
              ? 0
              : currentStreaks.reduce((a, b) => a > b ? a : b),
      'activeHabits': habitState.activeHabits.length,
    };
  }

  static Map<String, dynamic> _calculateProductivityTrend(
    TaskLoaded taskState,
  ) {
    final now = DateTime.now();
    final dailyProductivity = <double>[];

    for (int i = StatisticsConstants.weekDays - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayTasks = taskState.getTasksForDate(date);
      final completed = dayTasks.where((t) => t.isCompleted).length;

      dailyProductivity.add(completed.toDouble());
    }

    final averageProductivity =
        dailyProductivity.isEmpty
            ? 0.0
            : dailyProductivity.reduce((a, b) => a + b) /
                dailyProductivity.length;

    return {
      'dailyProductivity': dailyProductivity,
      'averageProductivity': averageProductivity,
      'peakDay':
          dailyProductivity.isEmpty
              ? 0
              : dailyProductivity.reduce((a, b) => a > b ? a : b),
    };
  }

  static String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  static Map<String, dynamic> getDefaultWeeklyTrends() {
    DebugLogger.warning(
      'Using default weekly trends',
      tag: StatisticsConstants.logTag,
    );

    final weekData = <String, dynamic>{};
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (final day in days) {
      weekData[day] = {'completed': 0, 'total': 0, 'percentage': 0};
    }

    return weekData;
  }

  static Map<String, dynamic> getDefaultMonthlyTrends() {
    DebugLogger.warning(
      'Using default monthly trends',
      tag: StatisticsConstants.logTag,
    );

    return {'weeks': <String, Map<String, dynamic>>{}};
  }

  static Map<String, dynamic> getDefaultPerformanceTrends() {
    DebugLogger.warning(
      'Using default performance trends',
      tag: StatisticsConstants.logTag,
    );

    return {
      'completionRate': {'rates': [], 'trend': 0.0, 'direction': 'stable'},
      'streak': {
        'currentStreaks': [],
        'averageStreak': 0.0,
        'longestStreak': 0,
        'activeHabits': 0,
      },
      'productivity': {
        'dailyProductivity': [],
        'averageProductivity': 0.0,
        'peakDay': 0,
      },
    };
  }
}
