import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/habit_model.dart';
import 'package:dayflow/presentation/blocs/habits/habit_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
import 'package:flutter/cupertino.dart';

class TrendsCard extends StatelessWidget {
  final HabitLoaded habitState;
  final TaskLoaded taskState;
  final String period;
  final HabitModel? focusedHabit;

  const TrendsCard({
    super.key,
    required this.habitState,
    required this.taskState,
    required this.period,
    this.focusedHabit,
  });

  @override
  Widget build(BuildContext context) {
    final trendData = _calculateTrendData();

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
              Icon(CupertinoIcons.chart_bar, size: 20, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$period Trends',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _buildTrendIndicator(trendData.trend),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(height: 80, child: _buildTrendChart(trendData.data)),
          const SizedBox(height: 12),
          _buildTrendSummary(trendData),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(String trend) {
    Color color;
    IconData icon;

    switch (trend) {
      case 'up':
        color = AppColors.success;
        icon = CupertinoIcons.arrow_up_right;
        break;
      case 'down':
        color = AppColors.error;
        icon = CupertinoIcons.arrow_down_right;
        break;
      default:
        color = AppColors.textSecondary;
        icon = CupertinoIcons.minus;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            trend == 'up'
                ? 'Improving'
                : trend == 'down'
                ? 'Declining'
                : 'Stable',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(List<double> data) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
        ),
      );
    }

    final maxValue = data.reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) {
      return const Center(
        child: Text(
          'No completion data',
          style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children:
          data.asMap().entries.map((entry) {
            final index = entry.key;
            final value = entry.value;
            final normalizedHeight = (value / maxValue * 60).clamp(2.0, 60.0);

            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: normalizedHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppColors.accent,
                            AppColors.accent.withAlpha(150),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getPeriodLabel(index),
                      style: const TextStyle(
                        fontSize: 8,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildTrendSummary(
    ({List<double> data, String trend, String summary}) trendData,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.lightbulb,
            size: 16,
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              trendData.summary,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  ({List<double> data, String trend, String summary}) _calculateTrendData() {
    final data = _getPeriodData();
    final trend = _calculateTrend(data);
    final summary = _generateSummary(data, trend);

    return (data: data, trend: trend, summary: summary);
  }

  List<double> _getPeriodData() {
    final now = DateTime.now();
    final data = <double>[];

    switch (period) {
      case 'Week':
        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          data.add(_getCompletionRateForDate(date));
        }
        break;
      case 'Month':
        for (int i = 3; i >= 0; i--) {
          final weekStart = now.subtract(Duration(days: i * 7));
          data.add(_getCompletionRateForWeek(weekStart));
        }
        break;
      case 'Year':
        for (int i = 11; i >= 0; i--) {
          final month = DateTime(now.year, now.month - i, 1);
          data.add(_getCompletionRateForMonth(month));
        }
        break;
    }

    return data;
  }

  double _getCompletionRateForDate(DateTime date) {
    final instances =
        habitState.todayInstances
            .where((i) => _isSameDay(i.date, date))
            .toList();

    if (focusedHabit != null) {
      final habitInstances =
          instances.where((i) => i.habitId == focusedHabit!.id).toList();
      if (habitInstances.isEmpty) return 0.0;
      final completed = habitInstances.where((i) => i.isCompleted).length;
      return completed / habitInstances.length;
    }

    if (instances.isEmpty) return 0.0;
    final completed = instances.where((i) => i.isCompleted).length;
    return completed / instances.length;
  }

  double _getCompletionRateForWeek(DateTime weekStart) {
    double totalRate = 0.0;
    int dayCount = 0;

    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      if (!date.isAfter(DateTime.now())) {
        totalRate += _getCompletionRateForDate(date);
        dayCount++;
      }
    }

    return dayCount > 0 ? totalRate / dayCount : 0.0;
  }

  double _getCompletionRateForMonth(DateTime month) {
    double totalRate = 0.0;
    int dayCount = 0;

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      if (!date.isAfter(DateTime.now())) {
        totalRate += _getCompletionRateForDate(date);
        dayCount++;
      }
    }

    return dayCount > 0 ? totalRate / dayCount : 0.0;
  }

  String _calculateTrend(List<double> data) {
    if (data.length < 2) return 'stable';

    final recent = data.sublist(data.length - 3).fold(0.0, (a, b) => a + b) / 3;
    final earlier = data.sublist(0, 3).fold(0.0, (a, b) => a + b) / 3;

    if (recent > earlier + 0.1) return 'up';
    if (recent < earlier - 0.1) return 'down';
    return 'stable';
  }

  String _generateSummary(List<double> data, String trend) {
    if (data.isEmpty) return 'No data available for analysis.';

    final average = data.fold(0.0, (a, b) => a + b) / data.length;
    final percentage = (average * 100).round();

    switch (trend) {
      case 'up':
        return 'Great progress! Your completion rate is improving with $percentage% average.';
      case 'down':
        return 'Consider reviewing your habits. Average completion is $percentage%.';
      default:
        return 'Steady progress with $percentage% average completion rate.';
    }
  }

  String _getPeriodLabel(int index) {
    switch (period) {
      case 'Week':
        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
        return days[index];
      case 'Month':
        return 'W${index + 1}';
      case 'Year':
        const months = [
          'J',
          'F',
          'M',
          'A',
          'M',
          'J',
          'J',
          'A',
          'S',
          'O',
          'N',
          'D',
        ];
        return months[index];
      default:
        return '${index + 1}';
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
