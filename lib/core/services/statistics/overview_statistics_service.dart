import 'package:dayflow/core/constants/statistics_constants.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:dayflow/presentation/blocs/habits/habit_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';

class OverviewStatisticsService {
  const OverviewStatisticsService._();

  static Map<String, dynamic> calculateOverview(
    TaskLoaded taskState,
    HabitLoaded habitState,
  ) {
    DebugLogger.debug(
      'Starting overview calculation',
      tag: StatisticsConstants.logTag,
    );

    try {
      final today = DateTime.now();

      final todayTasks = taskState.getTasksForDate(today);
      final completedTodayTasks = todayTasks.where((t) => t.isCompleted).length;
      final todayHabits = habitState.todayInstances;
      final completedTodayHabits = habitState.completedToday.length;

      DebugLogger.verbose(
        'Today data calculated',
        tag: StatisticsConstants.logTag,
        data: {
          'tasks': '$completedTodayTasks/${todayTasks.length}',
          'habits': '$completedTodayHabits/${todayHabits.length}',
        },
      );

      final todayScore = _calculateDailyScore(
        completedTodayTasks,
        todayTasks.length,
        completedTodayHabits,
        todayHabits.length,
      );

      final bestStreak = _calculateBestStreak(habitState);
      final totalPoints = _calculateTotalPoints(taskState, habitState);
      final weeklyAverage = _calculateWeeklyAverage(taskState, habitState);

      final overview = {
        'todayScore': todayScore,
        'todayTasksCompleted': completedTodayTasks,
        'todayTasksTotal': todayTasks.length,
        'todayHabitsCompleted': completedTodayHabits,
        'todayHabitsTotal': todayHabits.length,
        'currentStreak': bestStreak,
        'totalPoints': totalPoints,
        'weeklyAverage': weeklyAverage,
        'totalTasksCompleted': taskState.completedTasks.length,
        'totalActiveHabits': habitState.activeHabits.length,
        'overdueTasks': taskState.overdueTasks.length,
      };

      DebugLogger.success(
        'Overview calculation completed',
        tag: StatisticsConstants.logTag,
        data: {
          'todayScore': '${(todayScore * 100).round()}%',
          'totalPoints': totalPoints,
          'streak': bestStreak,
        },
      );

      return overview;
    } catch (e, stackTrace) {
      DebugLogger.error(
        'Failed to calculate overview',
        tag: StatisticsConstants.logTag,
        error: e,
        stackTrace: stackTrace,
      );
      return getDefaultOverview();
    }
  }

  static double _calculateDailyScore(
    int tasksCompleted,
    int totalTasks,
    int habitsCompleted,
    int totalHabits,
  ) {
    if (totalTasks == 0 && totalHabits == 0) return 0.0;

    final taskScore = totalTasks > 0 ? tasksCompleted / totalTasks : 0.0;
    final habitScore = totalHabits > 0 ? habitsCompleted / totalHabits : 0.0;

    final weightedScore =
        (totalTasks > 0 && totalHabits > 0)
            ? (taskScore * 0.5) + (habitScore * 0.5)
            : taskScore + habitScore;

    final finalScore = weightedScore.clamp(0.0, 1.0);

    DebugLogger.verbose(
      'Daily score calculated',
      tag: StatisticsConstants.logTag,
      data: {
        'taskScore': taskScore.toStringAsFixed(2),
        'habitScore': habitScore.toStringAsFixed(2),
        'finalScore': finalScore.toStringAsFixed(2),
      },
    );

    return finalScore;
  }

  static int _calculateTotalPoints(
    TaskLoaded taskState,
    HabitLoaded habitState,
  ) {
    final taskPoints =
        taskState.completedTasks.length *
        StatisticsConstants.taskCompletionPoints;

    final habitPoints =
        habitState.completedToday.length *
        StatisticsConstants.habitCompletionPoints;

    final streakBonus = habitState.habits.fold(
      0,
      (sum, h) =>
          sum + (h.currentStreak * StatisticsConstants.streakBonusPerDay),
    );

    final overduePenalty =
        taskState.overdueTasks.length * StatisticsConstants.overdueTaskPenalty;

    final totalPoints = (taskPoints +
            habitPoints +
            streakBonus +
            overduePenalty)
        .clamp(0, StatisticsConstants.maxTotalPoints);

    DebugLogger.verbose(
      'Points breakdown',
      tag: StatisticsConstants.logTag,
      data: {
        'taskPoints': taskPoints,
        'habitPoints': habitPoints,
        'streakBonus': streakBonus,
        'overduePenalty': overduePenalty,
        'total': totalPoints,
      },
    );

    return totalPoints;
  }

  static double _calculateWeeklyAverage(
    TaskLoaded taskState,
    HabitLoaded habitState,
  ) {
    final now = DateTime.now();
    double totalScore = 0;
    int validDays = 0;

    for (int i = 0; i < StatisticsConstants.weekDays; i++) {
      final date = now.subtract(Duration(days: i));
      final dayTasks = taskState.getTasksForDate(date);

      if (dayTasks.isNotEmpty) {
        final completed = dayTasks.where((t) => t.isCompleted).length;
        totalScore += completed / dayTasks.length;
        validDays++;
      }
    }

    final average = validDays > 0 ? totalScore / validDays : 0.0;

    DebugLogger.verbose(
      'Weekly average calculated',
      tag: StatisticsConstants.logTag,
      data: {'validDays': validDays, 'average': average.toStringAsFixed(2)},
    );

    return average;
  }

  static int _calculateBestStreak(HabitLoaded habitState) {
    final bestStreak = habitState.habits.fold(
      0,
      (max, h) => h.currentStreak > max ? h.currentStreak : max,
    );

    DebugLogger.verbose(
      'Best streak found',
      tag: StatisticsConstants.logTag,
      data: bestStreak,
    );

    return bestStreak;
  }

  static Map<String, dynamic> getDefaultOverview() {
    DebugLogger.warning(
      'Using default overview data',
      tag: StatisticsConstants.logTag,
    );

    return {
      'todayScore': 0.0,
      'todayTasksCompleted': 0,
      'todayTasksTotal': 0,
      'todayHabitsCompleted': 0,
      'todayHabitsTotal': 0,
      'currentStreak': 0,
      'totalPoints': 0,
      'weeklyAverage': 0.0,
      'totalTasksCompleted': 0,
      'totalActiveHabits': 0,
      'overdueTasks': 0,
    };
  }
}
