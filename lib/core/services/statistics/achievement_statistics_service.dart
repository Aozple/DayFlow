import 'package:dayflow/core/constants/statistics_constants.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:dayflow/core/services/statistics/statistics_service.dart';
import 'package:dayflow/presentation/blocs/habits/habit_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';

class AchievementStatisticsService {
  const AchievementStatisticsService._();

  static List<Achievement> calculateAchievements(
    TaskLoaded taskState,
    HabitLoaded habitState,
  ) {
    DebugLogger.debug(
      'Starting achievements calculation',
      tag: StatisticsConstants.logTag,
    );

    try {
      final achievements = <Achievement>[];

      achievements.addAll(_calculateTaskAchievements(taskState));

      achievements.addAll(_calculateHabitAchievements(habitState));

      achievements.addAll(_calculateStreakAchievements(habitState));

      achievements.addAll(_calculateSpecialAchievements(taskState, habitState));

      final unlockedCount = achievements.where((a) => a.isUnlocked).length;
      final totalPoints = achievements
          .where((a) => a.isUnlocked)
          .fold(0, (sum, a) => sum + a.points);

      DebugLogger.success(
        'Achievements calculated',
        tag: StatisticsConstants.logTag,
        data: {
          'total': achievements.length,
          'unlocked': unlockedCount,
          'totalPoints': totalPoints,
        },
      );

      return achievements;
    } catch (e, stackTrace) {
      DebugLogger.error(
        'Failed to calculate achievements',
        tag: StatisticsConstants.logTag,
        error: e,
        stackTrace: stackTrace,
      );
      return getDefaultAchievements();
    }
  }

  static List<Achievement> _calculateTaskAchievements(TaskLoaded taskState) {
    final completedTasks = taskState.completedTasks.length;

    return [
      Achievement(
        id: 'task_beginner',
        title: 'First Steps',
        description: 'Complete 10 tasks',
        icon: '🎯',
        progress: completedTasks.clamp(0, 10) / 10,
        isUnlocked:
            completedTasks >=
            StatisticsConstants.achievementThresholds['task_beginner']!,
        points: StatisticsConstants.achievementPoints['task_beginner']!,
        category: AchievementCategory.tasks,
      ),
      Achievement(
        id: 'task_intermediate',
        title: 'Task Master',
        description: 'Complete 50 tasks',
        icon: '⭐',
        progress: completedTasks.clamp(0, 50) / 50,
        isUnlocked:
            completedTasks >=
            StatisticsConstants.achievementThresholds['task_intermediate']!,
        points: StatisticsConstants.achievementPoints['task_intermediate']!,
        category: AchievementCategory.tasks,
      ),
      Achievement(
        id: 'task_master',
        title: 'Productivity King',
        description: 'Complete 100 tasks',
        icon: '👑',
        progress: completedTasks.clamp(0, 100) / 100,
        isUnlocked:
            completedTasks >=
            StatisticsConstants.achievementThresholds['task_master']!,
        points: StatisticsConstants.achievementPoints['task_master']!,
        category: AchievementCategory.tasks,
      ),
    ];
  }

  static List<Achievement> _calculateHabitAchievements(HabitLoaded habitState) {
    final totalHabits = habitState.habits.length;

    return [
      Achievement(
        id: 'habit_builder',
        title: 'Habit Builder',
        description: 'Create 5 habits',
        icon: '🎨',
        progress: totalHabits.clamp(0, 5) / 5,
        isUnlocked:
            totalHabits >=
            StatisticsConstants.achievementThresholds['habit_builder']!,
        points: StatisticsConstants.achievementPoints['habit_builder']!,
        category: AchievementCategory.habits,
      ),
    ];
  }

  static List<Achievement> _calculateStreakAchievements(
    HabitLoaded habitState,
  ) {
    final bestStreak = habitState.habits.fold(
      0,
      (max, h) => h.currentStreak > max ? h.currentStreak : max,
    );

    return [
      Achievement(
        id: 'streak_starter',
        title: 'Getting Started',
        description: '3 day streak',
        icon: '🔥',
        progress: bestStreak.clamp(0, 3) / 3,
        isUnlocked:
            bestStreak >=
            StatisticsConstants.achievementThresholds['streak_starter']!,
        points: StatisticsConstants.achievementPoints['streak_starter']!,
        category: AchievementCategory.streaks,
      ),
      Achievement(
        id: 'streak_keeper',
        title: 'Week Warrior',
        description: '7 day streak',
        icon: '💪',
        progress: bestStreak.clamp(0, 7) / 7,
        isUnlocked:
            bestStreak >=
            StatisticsConstants.achievementThresholds['streak_keeper']!,
        points: StatisticsConstants.achievementPoints['streak_keeper']!,
        category: AchievementCategory.streaks,
      ),
      Achievement(
        id: 'streak_master',
        title: 'Unstoppable',
        description: '30 day streak',
        icon: '🚀',
        progress: bestStreak.clamp(0, 30) / 30,
        isUnlocked:
            bestStreak >=
            StatisticsConstants.achievementThresholds['streak_master']!,
        points: StatisticsConstants.achievementPoints['streak_master']!,
        category: AchievementCategory.streaks,
      ),
    ];
  }

  static List<Achievement> _calculateSpecialAchievements(
    TaskLoaded taskState,
    HabitLoaded habitState,
  ) {
    final earlyTasks = getEarlyBirdTasks(taskState);
    final perfectDays = getPerfectDays(taskState, habitState);

    return [
      Achievement(
        id: 'early_bird',
        title: 'Early Bird',
        description: 'Complete 5 tasks before 9 AM',
        icon: '🌅',
        progress: earlyTasks.clamp(0, 5) / 5,
        isUnlocked:
            earlyTasks >=
            StatisticsConstants.achievementThresholds['early_bird']!,
        points: StatisticsConstants.achievementPoints['early_bird']!,
        category: AchievementCategory.special,
      ),
      Achievement(
        id: 'perfect_day',
        title: 'Perfect Day',
        description: 'Complete all tasks and habits in a day',
        icon: '✨',
        progress: perfectDays > 0 ? 1.0 : 0.0,
        isUnlocked:
            perfectDays >=
            StatisticsConstants.achievementThresholds['perfect_day']!,
        points: StatisticsConstants.achievementPoints['perfect_day']!,
        category: AchievementCategory.special,
      ),
    ];
  }

  static int getEarlyBirdTasks(TaskLoaded taskState) {
    final earlyTasks =
        taskState.completedTasks.where((task) {
          if (task.completedAt == null) return false;
          return task.completedAt!.hour < StatisticsConstants.earlyBirdHour;
        }).length;

    DebugLogger.verbose(
      'Early bird tasks calculated',
      tag: StatisticsConstants.logTag,
      data: earlyTasks,
    );

    return earlyTasks;
  }

  static int getPerfectDays(TaskLoaded taskState, HabitLoaded habitState) {
    int perfectDays = 0;
    final now = DateTime.now();

    for (int i = 0; i < StatisticsConstants.monthDays; i++) {
      final date = now.subtract(Duration(days: i));
      final dayTasks = taskState.getTasksForDate(date);

      if (dayTasks.isNotEmpty) {
        final allTasksComplete = dayTasks.every((t) => t.isCompleted);
        if (allTasksComplete) perfectDays++;
      }
    }

    DebugLogger.verbose(
      'Perfect days calculated',
      tag: StatisticsConstants.logTag,
      data: perfectDays,
    );

    return perfectDays;
  }

  static List<Achievement> getDefaultAchievements() {
    DebugLogger.warning(
      'Using default achievements',
      tag: StatisticsConstants.logTag,
    );

    return [];
  }
}
