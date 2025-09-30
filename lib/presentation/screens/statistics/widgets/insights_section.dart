import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/presentation/blocs/habits/habit_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
import 'package:flutter/cupertino.dart';

class InsightsSection extends StatelessWidget {
  final TaskLoaded taskState;
  final HabitLoaded habitState;
  final (DateTime, DateTime) dateRange;

  const InsightsSection({
    super.key,
    required this.taskState,
    required this.habitState,
    required this.dateRange,
  });

  @override
  Widget build(BuildContext context) {
    final insights = _generateInsights();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withAlpha(30), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          ...insights.map((insight) => _buildInsightCard(insight)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      children: [
        Icon(CupertinoIcons.lightbulb_fill, size: 18, color: AppColors.warning),
        SizedBox(width: 8),
        Text(
          'Smart Insights',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(Insight insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider.withAlpha(20), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: insight.color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(insight.icon, size: 16, color: insight.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Insight> _generateInsights() {
    final insights = <Insight>[];

    final completionRate = taskState.completionRate;
    if (completionRate > 0.8) {
      insights.add(
        Insight(
          title: 'Excellent Performance',
          description:
              'You completed ${(completionRate * 100).round()}% of your tasks. Keep up the great work!',
          icon: CupertinoIcons.star_fill,
          color: AppColors.success,
        ),
      );
    } else if (completionRate < 0.5) {
      insights.add(
        Insight(
          title: 'Room for Improvement',
          description:
              'Your task completion is at ${(completionRate * 100).round()}%. Try breaking tasks into smaller chunks.',
          icon: CupertinoIcons.arrow_up_circle_fill,
          color: AppColors.warning,
        ),
      );
    }

    final overdueTasks = taskState.overdueTasks.length;
    if (overdueTasks > 5) {
      insights.add(
        Insight(
          title: 'Overdue Tasks Alert',
          description:
              'You have $overdueTasks overdue tasks. Consider reviewing your priorities.',
          icon: CupertinoIcons.exclamationmark_triangle_fill,
          color: AppColors.error,
        ),
      );
    }

    final bestStreak = habitState.habits.fold(
      0,
      (max, habit) => habit.currentStreak > max ? habit.currentStreak : max,
    );
    if (bestStreak > 7) {
      insights.add(
        Insight(
          title: 'Streak Champion',
          description:
              'Your best streak is $bestStreak days! You\'re building strong habits.',
          icon: CupertinoIcons.flame_fill,
          color: AppColors.warning,
        ),
      );
    }

    if (insights.isEmpty) {
      insights.add(
        Insight(
          title: 'Keep Tracking',
          description:
              'Continue logging your tasks and habits to get personalized insights.',
          icon: CupertinoIcons.chart_bar_alt_fill,
          color: AppColors.accent,
        ),
      );
    }

    return insights.take(4).toList();
  }
}

class Insight {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  Insight({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
