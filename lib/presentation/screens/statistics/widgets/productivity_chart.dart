import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/presentation/blocs/habits/habit_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
import 'package:flutter/cupertino.dart';

class ProductivityChart extends StatelessWidget {
  final TaskLoaded taskState;
  final HabitLoaded habitState;
  final (DateTime, DateTime) dateRange;

  const ProductivityChart({
    super.key,
    required this.taskState,
    required this.habitState,
    required this.dateRange,
  });

  @override
  Widget build(BuildContext context) {
    final data = _generateChartData();

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
          const SizedBox(height: 20),
          _buildChart(data),
          const SizedBox(height: 16),
          _buildTimeLabels(data),
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
            Icon(
              CupertinoIcons.chart_bar_alt_fill,
              size: 18,
              color: AppColors.success,
            ),
            SizedBox(width: 8),
            Text(
              'Productivity Trends',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        _buildTrendIndicator(),
      ],
    );
  }

  Widget _buildTrendIndicator() {
    final trend = _calculateTrend();
    final isUp = trend > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isUp ? AppColors.success : AppColors.error).withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp
                ? CupertinoIcons.arrow_up_right
                : CupertinoIcons.arrow_down_right,
            size: 12,
            color: isUp ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 4),
          Text(
            '${trend.abs()}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isUp ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<double> data) {
    if (data.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: const Text(
          'No data available',
          style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
        ),
      );
    }

    final maxValue = data.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children:
            data.asMap().entries.map((entry) {
              final value = entry.value;
              final height = maxValue > 0 ? (value / maxValue) * 100 : 0.0;

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (value > 0)
                        Text(
                          '${value.round()}%',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Container(
                        height: height,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildTimeLabels(List<double> data) {
    final labels = _getTimeLabels();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children:
          labels.take(data.length).map((label) {
            return Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                ),
              ),
            );
          }).toList(),
    );
  }

  List<double> _generateChartData() {
    final days = dateRange.$2.difference(dateRange.$1).inDays + 1;
    final dataPoints = days > 7 ? 7 : days;
    final data = <double>[];

    for (int i = 0; i < dataPoints; i++) {
      final date = dateRange.$2.subtract(Duration(days: dataPoints - i - 1));
      final dayTasks =
          taskState.tasks.where((task) {
            return task.dueDate != null && _isSameDay(task.dueDate!, date);
          }).toList();

      if (dayTasks.isEmpty) {
        data.add(0);
      } else {
        final completed = dayTasks.where((t) => t.isCompleted).length;
        data.add((completed / dayTasks.length) * 100);
      }
    }

    return data;
  }

  List<String> _getTimeLabels() {
    final days = dateRange.$2.difference(dateRange.$1).inDays + 1;

    if (days <= 7) {
      return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    } else if (days <= 30) {
      return ['W1', 'W2', 'W3', 'W4'];
    } else {
      return ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    }
  }

  int _calculateTrend() {
    final data = _generateChartData();
    if (data.length < 2) return 0;

    final recent = data.sublist(data.length ~/ 2);
    final older = data.sublist(0, data.length ~/ 2);

    final recentAvg =
        recent.isEmpty ? 0.0 : recent.reduce((a, b) => a + b) / recent.length;
    final olderAvg =
        older.isEmpty ? 0.0 : older.reduce((a, b) => a + b) / older.length;

    if (olderAvg == 0) return 0;
    return ((recentAvg - olderAvg) / olderAvg * 100).round();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
