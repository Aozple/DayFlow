import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/presentation/blocs/habits/habit_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
import 'package:flutter/cupertino.dart';

class WeeklyProgressWidget extends StatelessWidget {
  final TaskLoaded taskState;
  final HabitLoaded habitState;
  final (DateTime, DateTime) dateRange;

  const WeeklyProgressWidget({
    super.key,
    required this.taskState,
    required this.habitState,
    required this.dateRange,
  });

  @override
  Widget build(BuildContext context) {
    final weekData = _calculateWeeklyProgress();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withAlpha(15),
            AppColors.accent.withAlpha(8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withAlpha(30), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      CupertinoIcons.calendar_today,
                      size: 14,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'This Week',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getScoreColor(weekData.score).withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getScoreColor(weekData.score).withAlpha(40),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.star_fill,
                      size: 12,
                      color: _getScoreColor(weekData.score),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${weekData.score}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _getScoreColor(weekData.score),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: List.generate(7, (index) {
              final day = weekData.days[index];
              return Expanded(child: _buildDayColumn(day, index));
            }),
          ),

          const SizedBox(height: 12),
          _buildWeekSummary(weekData),
        ],
      ),
    );
  }

  Widget _buildDayColumn(DayProgress day, int index) {
    final isToday = _isToday(day.date);
    final isPast = day.date.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          Text(
            _getDayName(index),
            style: TextStyle(
              fontSize: 10,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              color: isToday ? AppColors.accent : AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    isToday
                        ? AppColors.accent.withAlpha(60)
                        : AppColors.divider.withAlpha(20),
                width: isToday ? 1.5 : 0.5,
              ),
            ),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                FractionallySizedBox(
                  heightFactor: day.completionRate,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors:
                            isPast
                                ? [
                                  AppColors.success.withAlpha(150),
                                  AppColors.success.withAlpha(100),
                                ]
                                : [
                                  AppColors.surface.withAlpha(100),
                                  AppColors.surface.withAlpha(50),
                                ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(7),
                      ),
                    ),
                  ),
                ),

                if (day.tasks > 0 || day.habits > 0)
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (day.habits > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.info.withAlpha(20),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${day.completedHabits}/${day.habits}',
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: AppColors.info,
                              ),
                            ),
                          ),
                        if (day.tasks > 0) ...[
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withAlpha(20),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${day.completedTasks}/${day.tasks}',
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSummary(WeeklyData data) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background.withAlpha(100),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider.withAlpha(20), width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSummaryItem(
            CupertinoIcons.checkmark_circle_fill,
            '${data.totalCompleted}',
            'completed',
            AppColors.success,
          ),
          Container(
            width: 1,
            height: 20,
            color: AppColors.divider.withAlpha(30),
          ),
          _buildSummaryItem(
            CupertinoIcons.flag_fill,
            '${data.totalPending}',
            'pending',
            AppColors.warning,
          ),
          Container(
            width: 1,
            height: 20,
            color: AppColors.divider.withAlpha(30),
          ),
          _buildSummaryItem(
            CupertinoIcons.flame_fill,
            '${data.streakDays}',
            'day streak',
            AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.info;
    if (score >= 40) return AppColors.warning;
    return AppColors.error;
  }

  String _getDayName(int index) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[index];
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  WeeklyData _calculateWeeklyProgress() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    final days = List.generate(7, (index) {
      final date = startOfWeek.add(Duration(days: index));

      final dayTasks =
          taskState.tasks
              .where(
                (task) =>
                    task.dueDate != null && _isSameDay(task.dueDate!, date),
              )
              .toList();

      final dayHabits =
          habitState.todayInstances
              .where((instance) => _isSameDay(instance.date, date))
              .toList();

      final completedTasks = dayTasks.where((t) => t.isCompleted).length;
      final completedHabits = dayHabits.where((h) => h.isCompleted).length;

      final totalItems = dayTasks.length + dayHabits.length;
      final completedItems = completedTasks + completedHabits;

      return DayProgress(
        date: date,
        tasks: dayTasks.length,
        completedTasks: completedTasks,
        habits: dayHabits.length,
        completedHabits: completedHabits,
        completionRate: totalItems > 0 ? completedItems / totalItems : 0.0,
      );
    });

    final totalCompleted = days.fold(
      0,
      (sum, day) => sum + day.completedTasks + day.completedHabits,
    );
    final totalPending = days.fold(
      0,
      (sum, day) =>
          sum +
          (day.tasks - day.completedTasks) +
          (day.habits - day.completedHabits),
    );

    final streakDays = _calculateStreakDays(days);
    final score = _calculateWeekScore(days);

    return WeeklyData(
      days: days,
      totalCompleted: totalCompleted,
      totalPending: totalPending,
      streakDays: streakDays,
      score: score,
    );
  }

  int _calculateStreakDays(List<DayProgress> days) {
    int streak = 0;
    for (int i = days.length - 1; i >= 0; i--) {
      if (days[i].date.isAfter(DateTime.now())) continue;
      if (days[i].completionRate > 0.5) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  int _calculateWeekScore(List<DayProgress> days) {
    final validDays =
        days
            .where(
              (d) =>
                  d.date.isBefore(DateTime.now().add(const Duration(days: 1))),
            )
            .toList();

    if (validDays.isEmpty) return 0;

    final totalScore = validDays.fold(
      0.0,
      (sum, day) => sum + (day.completionRate * 100),
    );

    return (totalScore / validDays.length).round();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class WeeklyData {
  final List<DayProgress> days;
  final int totalCompleted;
  final int totalPending;
  final int streakDays;
  final int score;

  WeeklyData({
    required this.days,
    required this.totalCompleted,
    required this.totalPending,
    required this.streakDays,
    required this.score,
  });
}

class DayProgress {
  final DateTime date;
  final int tasks;
  final int completedTasks;
  final int habits;
  final int completedHabits;
  final double completionRate;

  DayProgress({
    required this.date,
    required this.tasks,
    required this.completedTasks,
    required this.habits,
    required this.completedHabits,
    required this.completionRate,
  });
}
