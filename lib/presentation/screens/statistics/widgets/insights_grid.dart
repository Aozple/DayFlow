import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/habit_model.dart';
import 'package:dayflow/presentation/blocs/habits/habit_bloc.dart';
import 'package:flutter/cupertino.dart';

class InsightsGrid extends StatelessWidget {
  final HabitLoaded habitState;
  final String period;
  final HabitModel? focusedHabit;

  const InsightsGrid({
    super.key,
    required this.habitState,
    required this.period,
    this.focusedHabit,
  });

  @override
  Widget build(BuildContext context) {
    final insights = _calculateInsights();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Insights',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildInsightCard(
              title: 'Best Habit',
              value: insights.bestHabit ?? 'None',
              subtitle: '${insights.bestHabitRate}% success',
              icon: CupertinoIcons.star_fill,
              color: AppColors.warning,
            ),
            _buildInsightCard(
              title: 'Best Day',
              value: insights.bestDay,
              subtitle: 'Most productive',
              icon: CupertinoIcons.calendar_today,
              color: AppColors.success,
            ),
            _buildInsightCard(
              title: 'Current Streak',
              value: '${insights.currentStreak}',
              subtitle: 'days in a row',
              icon: CupertinoIcons.flame_fill,
              color: AppColors.error,
            ),
            _buildInsightCard(
              title: 'This $period',
              value: '${insights.periodRate}%',
              subtitle: 'completion rate',
              icon: CupertinoIcons.chart_pie_fill,
              color: AppColors.info,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withAlpha(30), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const Spacer(),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  ({
    String? bestHabit,
    int bestHabitRate,
    String bestDay,
    int currentStreak,
    int periodRate,
  })
  _calculateInsights() {
    if (focusedHabit != null) {
      return (
        bestHabit: focusedHabit!.title,
        bestHabitRate: _calculateHabitSuccessRate(focusedHabit!),
        bestDay: _getBestDayForHabit(focusedHabit!),
        currentStreak: focusedHabit!.currentStreak,
        periodRate: _calculatePeriodRate(focusedHabit!),
      );
    }

    final bestHabit = _findBestHabit();
    return (
      bestHabit: bestHabit?.title,
      bestHabitRate:
          bestHabit != null ? _calculateHabitSuccessRate(bestHabit) : 0,
      bestDay: _getBestDayOverall(),
      currentStreak: _getMaxCurrentStreak(),
      periodRate: _calculateOverallPeriodRate(),
    );
  }

  HabitModel? _findBestHabit() {
    if (habitState.habits.isEmpty) return null;

    var bestHabit = habitState.habits.first;
    var bestRate = _calculateHabitSuccessRate(bestHabit);

    for (final habit in habitState.habits.skip(1)) {
      final rate = _calculateHabitSuccessRate(habit);
      if (rate > bestRate) {
        bestHabit = habit;
        bestRate = rate;
      }
    }

    return bestHabit;
  }

  int _calculateHabitSuccessRate(HabitModel habit) {
    final instances =
        habitState.todayInstances.where((i) => i.habitId == habit.id).toList();

    if (instances.isEmpty) return 0;

    final completed = instances.where((i) => i.isCompleted).length;
    return ((completed / instances.length) * 100).round();
  }

  String _getBestDayForHabit(HabitModel habit) {
    final dayStats = <int, int>{};

    for (final instance in habitState.todayInstances) {
      if (instance.habitId == habit.id && instance.isCompleted) {
        final day = instance.date.weekday;
        dayStats[day] = (dayStats[day] ?? 0) + 1;
      }
    }

    if (dayStats.isEmpty) return 'No data';

    final bestDay =
        dayStats.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    return _getDayName(bestDay);
  }

  String _getBestDayOverall() {
    final dayStats = <int, int>{};

    for (final instance in habitState.todayInstances) {
      if (instance.isCompleted) {
        final day = instance.date.weekday;
        dayStats[day] = (dayStats[day] ?? 0) + 1;
      }
    }

    if (dayStats.isEmpty) return 'No data';

    final bestDay =
        dayStats.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    return _getDayName(bestDay);
  }

  int _getMaxCurrentStreak() {
    return habitState.habits.fold(
      0,
      (max, habit) => habit.currentStreak > max ? habit.currentStreak : max,
    );
  }

  int _calculatePeriodRate(HabitModel habit) {
    final now = DateTime.now();
    final startDate = _getPeriodStartDate(now);

    final periodInstances =
        habitState.todayInstances
            .where(
              (i) =>
                  i.habitId == habit.id &&
                  i.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
                  i.date.isBefore(now.add(const Duration(days: 1))),
            )
            .toList();

    if (periodInstances.isEmpty) return 0;

    final completed = periodInstances.where((i) => i.isCompleted).length;
    return ((completed / periodInstances.length) * 100).round();
  }

  int _calculateOverallPeriodRate() {
    final now = DateTime.now();
    final startDate = _getPeriodStartDate(now);

    final periodInstances =
        habitState.todayInstances
            .where(
              (i) =>
                  i.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
                  i.date.isBefore(now.add(const Duration(days: 1))),
            )
            .toList();

    if (periodInstances.isEmpty) return 0;

    final completed = periodInstances.where((i) => i.isCompleted).length;
    return ((completed / periodInstances.length) * 100).round();
  }

  DateTime _getPeriodStartDate(DateTime now) {
    switch (period) {
      case 'Week':
        return now.subtract(Duration(days: now.weekday - 1));
      case 'Month':
        return DateTime(now.year, now.month, 1);
      case 'Year':
        return DateTime(now.year, 1, 1);
      default:
        return now.subtract(const Duration(days: 30));
    }
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
