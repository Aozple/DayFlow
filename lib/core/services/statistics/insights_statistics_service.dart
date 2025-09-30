import 'package:dayflow/core/constants/statistics_constants.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:dayflow/presentation/blocs/habits/habit_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';

class InsightsStatisticsService {
  const InsightsStatisticsService._();

  static List<String> generateInsights(
    TaskLoaded taskState,
    HabitLoaded habitState,
    DateTime startDate,
    DateTime endDate,
  ) {
    DebugLogger.debug(
      'Starting insights generation',
      tag: StatisticsConstants.logTag,
      data: {'startDate': startDate.toString(), 'endDate': endDate.toString()},
    );

    try {
      final insights = <String>[];

      insights.addAll(_generateTaskInsights(taskState));

      insights.addAll(_generateHabitInsights(habitState));

      insights.addAll(_generateStreakInsights(habitState));

      insights.addAll(_generateProductivityInsights(taskState));

      insights.addAll(_generateOverdueInsights(taskState));

      final limitedInsights =
          insights.take(StatisticsConstants.maxInsights).toList();

      DebugLogger.success(
        'Insights generated',
        tag: StatisticsConstants.logTag,
        data: {
          'totalGenerated': insights.length,
          'returned': limitedInsights.length,
        },
      );

      return limitedInsights;
    } catch (e, stackTrace) {
      DebugLogger.error(
        'Failed to generate insights',
        tag: StatisticsConstants.logTag,
        error: e,
        stackTrace: stackTrace,
      );
      return getDefaultInsights();
    }
  }

  static List<String> _generateTaskInsights(TaskLoaded taskState) {
    final insights = <String>[];
    final completionRate = taskState.completionRate;

    if (completionRate >= StatisticsConstants.excellentCompletionRate) {
      insights.add(
        '🎉 Excellent! ${(completionRate * 100).round()}% task completion rate',
      );
    } else if (completionRate >= StatisticsConstants.goodCompletionRate) {
      insights.add(
        '👍 Good job! ${(completionRate * 100).round()}% tasks completed',
      );
    } else if (completionRate < StatisticsConstants.poorCompletionRate) {
      insights.add('💡 Try breaking large tasks into smaller ones');
    }

    DebugLogger.verbose(
      'Task insights generated',
      tag: StatisticsConstants.logTag,
      data: {
        'completionRate': completionRate.toStringAsFixed(2),
        'insightsCount': insights.length,
      },
    );

    return insights;
  }

  static List<String> _generateHabitInsights(HabitLoaded habitState) {
    final insights = <String>[];
    final todayCompletion = habitState.todayCompletionRate;

    if (todayCompletion == 1.0 && habitState.todayInstances.isNotEmpty) {
      insights.add('⭐ All habits completed today - perfect!');
    } else if (todayCompletion >= 0.8 && habitState.todayInstances.isNotEmpty) {
      insights.add('✨ Great habit consistency today!');
    } else if (todayCompletion < 0.5 && habitState.todayInstances.isNotEmpty) {
      insights.add('💪 Keep pushing with your habits - consistency is key!');
    }

    DebugLogger.verbose(
      'Habit insights generated',
      tag: StatisticsConstants.logTag,
      data: {
        'todayCompletion': todayCompletion.toStringAsFixed(2),
        'insightsCount': insights.length,
      },
    );

    return insights;
  }

  static List<String> _generateStreakInsights(HabitLoaded habitState) {
    final insights = <String>[];
    final bestStreak = habitState.habits.fold(
      0,
      (max, h) => h.currentStreak > max ? h.currentStreak : max,
    );

    if (bestStreak >= StatisticsConstants.excellentStreak) {
      insights.add('🔥 Amazing $bestStreak day streak! Keep it up');
    } else if (bestStreak >= StatisticsConstants.goodStreak) {
      insights.add('💪 $bestStreak day streak - building momentum');
    } else if (bestStreak == 0 && habitState.habits.isNotEmpty) {
      insights.add('🚀 Start a new streak - you can do this!');
    }

    DebugLogger.verbose(
      'Streak insights generated',
      tag: StatisticsConstants.logTag,
      data: {'bestStreak': bestStreak, 'insightsCount': insights.length},
    );

    return insights;
  }

  static List<String> _generateProductivityInsights(TaskLoaded taskState) {
    final insights = <String>[];
    final avgTasksPerDay = calculateAverageTasksPerDay(taskState);

    if (avgTasksPerDay >= StatisticsConstants.highProductivityTasksPerDay) {
      insights.add('🚀 Averaging ${avgTasksPerDay.round()} tasks per day');
    } else if (avgTasksPerDay >= 3) {
      insights.add(
        '📈 Solid productivity with ${avgTasksPerDay.round()} tasks daily',
      );
    } else if (avgTasksPerDay > 0 && avgTasksPerDay < 2) {
      insights.add(
        '💡 Consider setting more daily goals to boost productivity',
      );
    }

    DebugLogger.verbose(
      'Productivity insights generated',
      tag: StatisticsConstants.logTag,
      data: {
        'avgTasksPerDay': avgTasksPerDay.toStringAsFixed(1),
        'insightsCount': insights.length,
      },
    );

    return insights;
  }

  static List<String> _generateOverdueInsights(TaskLoaded taskState) {
    final insights = <String>[];
    final overdueTasks = taskState.overdueTasks.length;

    if (overdueTasks > StatisticsConstants.warningOverdueTasks) {
      insights.add('⚠️ You have $overdueTasks overdue tasks to review');
    } else if (overdueTasks == 0 && taskState.activeTasks.isNotEmpty) {
      insights.add('✨ No overdue tasks - great time management!');
    } else if (overdueTasks >= 1 &&
        overdueTasks <= StatisticsConstants.warningOverdueTasks) {
      insights.add(
        '👀 $overdueTasks overdue task${overdueTasks > 1 ? 's' : ''} - time to catch up!',
      );
    }

    DebugLogger.verbose(
      'Overdue insights generated',
      tag: StatisticsConstants.logTag,
      data: {'overdueTasks': overdueTasks, 'insightsCount': insights.length},
    );

    return insights;
  }

  static double calculateAverageTasksPerDay(TaskLoaded taskState) {
    final completedTasks = taskState.completedTasks;
    if (completedTasks.isEmpty) return 0;

    final daysWithTasks = <DateTime>{};

    for (final task in completedTasks) {
      if (task.completedAt != null) {
        final date = DateTime(
          task.completedAt!.year,
          task.completedAt!.month,
          task.completedAt!.day,
        );
        daysWithTasks.add(date);
      }
    }

    final average =
        daysWithTasks.isEmpty
            ? 0.0
            : completedTasks.length / daysWithTasks.length;

    DebugLogger.verbose(
      'Average tasks per day calculated',
      tag: StatisticsConstants.logTag,
      data: {
        'completedTasks': completedTasks.length,
        'daysWithTasks': daysWithTasks.length,
        'average': average.toStringAsFixed(2),
      },
    );

    return average;
  }

  static List<String> getDefaultInsights() {
    DebugLogger.warning(
      'Using default insights',
      tag: StatisticsConstants.logTag,
    );

    return [
      '💡 Start tracking your tasks and habits to see personalized insights',
      '🎯 Set small, achievable goals to build momentum',
      '🔄 Consistency is more important than perfection',
    ];
  }
}
