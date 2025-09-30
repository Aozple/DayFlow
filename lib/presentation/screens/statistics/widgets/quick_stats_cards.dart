import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/presentation/blocs/habits/habit_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
import 'package:flutter/cupertino.dart';

class QuickStatsCards extends StatelessWidget {
  final TaskLoaded taskState;
  final HabitLoaded habitState;
  final (DateTime, DateTime) dateRange;

  const QuickStatsCards({
    super.key,
    required this.taskState,
    required this.habitState,
    required this.dateRange,
  });

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _StatCard(
            title: 'Total Score',
            value: '${stats.totalScore}',
            icon: CupertinoIcons.star_fill,
            color: AppColors.warning,
            subtitle: 'points',
          ),
          const SizedBox(width: 12),
          _StatCard(
            title: 'Productivity',
            value: '${stats.productivityRate}%',
            icon: CupertinoIcons.chart_pie_fill,
            color: AppColors.success,
            subtitle: 'completion',
          ),
          const SizedBox(width: 12),
          _StatCard(
            title: 'Active Streak',
            value: '${stats.currentStreak}',
            icon: CupertinoIcons.flame_fill,
            color: AppColors.error,
            subtitle: 'days',
          ),
          const SizedBox(width: 12),
          _StatCard(
            title: 'Focus Time',
            value: '${stats.focusHours}h',
            icon: CupertinoIcons.timer_fill,
            color: AppColors.info,
            subtitle: 'tracked',
          ),
        ],
      ),
    );
  }

  ({int totalScore, int productivityRate, int currentStreak, int focusHours})
  _calculateStats() {
    final completedTasks = taskState.completedTasks.length;
    final totalTasks = taskState.tasks.length;
    final productivityRate =
        totalTasks > 0 ? ((completedTasks / totalTasks) * 100).round() : 0;

    final bestStreak = habitState.habits.fold(
      0,
      (max, habit) => habit.currentStreak > max ? habit.currentStreak : max,
    );

    final focusHours =
        taskState.tasks.fold(
          0,
          (sum, task) => sum + (task.estimatedMinutes ?? 0),
        ) ~/
        60;

    final totalScore =
        (completedTasks * 10) +
        (habitState.completedToday.length * 15) +
        (bestStreak * 5);

    return (
      totalScore: totalScore,
      productivityRate: productivityRate,
      currentStreak: bestStreak,
      focusHours: focusHours,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withAlpha(30), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 18, color: color),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
