import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/habit_model.dart';
import 'package:dayflow/presentation/blocs/habits/habit_bloc.dart';
import 'package:flutter/cupertino.dart';

class HabitsBreakdown extends StatelessWidget {
  final HabitLoaded habitState;
  final (DateTime, DateTime) dateRange;

  const HabitsBreakdown({
    super.key,
    required this.habitState,
    required this.dateRange,
  });

  @override
  Widget build(BuildContext context) {
    final breakdownData = _calculateBreakdown();

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
          _buildTopHabits(breakdownData.topHabits),
          const SizedBox(height: 16),
          _buildFrequencyDistribution(breakdownData.frequencyData),
          const SizedBox(height: 16),
          _buildStreakAnalysis(breakdownData.streakData),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(CupertinoIcons.repeat, size: 18, color: AppColors.info),
            SizedBox(width: 8),
            Text(
              'Habits Analysis',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.info.withAlpha(20),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${habitState.activeHabits.length} active',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.info,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopHabits(List<HabitPerformance> topHabits) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Performing Habits',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ...topHabits.take(3).map((habit) => _buildHabitItem(habit)),
      ],
    );
  }

  Widget _buildHabitItem(HabitPerformance habit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider.withAlpha(20), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.fromHex(habit.color),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${habit.completionRate}% completion',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.flame_fill,
                  size: 12,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 4),
                Text(
                  '${habit.streak}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyDistribution(Map<HabitFrequency, int> data) {
    final total = data.values.fold(0, (sum, count) => sum + count);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frequency Distribution',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ...data.entries.map((entry) {
          final percentage = total > 0 ? (entry.value / total) : 0.0;
          return _buildFrequencyItem(entry.key, entry.value, percentage);
        }),
      ],
    );
  }

  Widget _buildFrequencyItem(
    HabitFrequency frequency,
    int count,
    double percentage,
  ) {
    final color = _getFrequencyColor(frequency);
    final label = _getFrequencyLabel(frequency);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakAnalysis(StreakData streakData) {
    return Row(
      children: [
        Expanded(
          child: _buildStreakCard(
            'Current',
            '${streakData.current}',
            AppColors.success,
            CupertinoIcons.flame_fill,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStreakCard(
            'Average',
            '${streakData.average}',
            AppColors.info,
            CupertinoIcons.chart_bar_alt_fill,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStreakCard(
            'Longest',
            '${streakData.longest}',
            AppColors.warning,
            CupertinoIcons.star_fill,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(30), width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Color _getFrequencyColor(HabitFrequency frequency) {
    switch (frequency) {
      case HabitFrequency.daily:
        return AppColors.success;
      case HabitFrequency.weekly:
        return AppColors.info;
      case HabitFrequency.monthly:
        return AppColors.warning;
      case HabitFrequency.custom:
        return AppColors.accent;
    }
  }

  String _getFrequencyLabel(HabitFrequency frequency) {
    switch (frequency) {
      case HabitFrequency.daily:
        return 'Daily';
      case HabitFrequency.weekly:
        return 'Weekly';
      case HabitFrequency.monthly:
        return 'Monthly';
      case HabitFrequency.custom:
        return 'Custom';
    }
  }

  ({
    List<HabitPerformance> topHabits,
    Map<HabitFrequency, int> frequencyData,
    StreakData streakData,
  })
  _calculateBreakdown() {
    final topHabits =
        habitState.activeHabits.map((habit) {
            final daysSinceStart =
                DateTime.now().difference(habit.startDate).inDays + 1;
            final completionRate =
                daysSinceStart > 0
                    ? ((habit.totalCompletions / daysSinceStart) * 100).round()
                    : 0;

            return HabitPerformance(
              title: habit.title,
              color: habit.color,
              completionRate: completionRate,
              streak: habit.currentStreak,
            );
          }).toList()
          ..sort((a, b) => b.completionRate.compareTo(a.completionRate));

    final frequencyData = <HabitFrequency, int>{};
    for (final habit in habitState.activeHabits) {
      frequencyData[habit.frequency] =
          (frequencyData[habit.frequency] ?? 0) + 1;
    }

    final currentStreak = habitState.activeHabits.fold(
      0,
      (max, habit) => habit.currentStreak > max ? habit.currentStreak : max,
    );

    final longestStreak = habitState.activeHabits.fold(
      0,
      (max, habit) => habit.longestStreak > max ? habit.longestStreak : max,
    );

    final averageStreak =
        habitState.activeHabits.isEmpty
            ? 0
            : habitState.activeHabits.fold(
                  0,
                  (sum, habit) => sum + habit.currentStreak,
                ) ~/
                habitState.activeHabits.length;

    return (
      topHabits: topHabits,
      frequencyData: frequencyData,
      streakData: StreakData(
        current: currentStreak,
        average: averageStreak,
        longest: longestStreak,
      ),
    );
  }
}

class HabitPerformance {
  final String title;
  final String color;
  final int completionRate;
  final int streak;

  HabitPerformance({
    required this.title,
    required this.color,
    required this.completionRate,
    required this.streak,
  });
}

class StreakData {
  final int current;
  final int average;
  final int longest;

  StreakData({
    required this.current,
    required this.average,
    required this.longest,
  });
}
