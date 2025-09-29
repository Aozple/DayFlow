import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/presentation/blocs/habits/habit_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
import 'package:flutter/cupertino.dart';

class ActivityHeatmap extends StatelessWidget {
  final TaskLoaded taskState;
  final HabitLoaded habitState;
  final (DateTime, DateTime) dateRange;

  const ActivityHeatmap({
    super.key,
    required this.taskState,
    required this.habitState,
    required this.dateRange,
  });

  @override
  Widget build(BuildContext context) {
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
          _buildHeatmap(),
          const SizedBox(height: 12),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(CupertinoIcons.calendar, size: 18, color: AppColors.accent),
        const SizedBox(width: 8),
        const Text(
          'Activity Overview',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildHeatmap() {
    final days = dateRange.$2.difference(dateRange.$1).inDays + 1;
    final weeks = (days / 7).ceil();

    return SizedBox(
      height: 130,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(weeks, (weekIndex) {
            return _buildWeekColumn(weekIndex);
          }),
        ),
      ),
    );
  }

  Widget _buildWeekColumn(int weekIndex) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      child: Column(
        children: List.generate(7, (dayIndex) {
          final date = dateRange.$1.add(
            Duration(days: weekIndex * 7 + dayIndex),
          );
          if (date.isAfter(dateRange.$2) || date.isAfter(DateTime.now())) {
            return const SizedBox(width: 14, height: 14);
          }

          final intensity = _getActivityIntensity(date);
          return Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: _getColorForIntensity(intensity),
              borderRadius: BorderRadius.circular(3),
              border:
                  _isToday(date)
                      ? Border.all(color: AppColors.accent, width: 1.5)
                      : null,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Less',
          style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
        ),
        const SizedBox(width: 8),
        ...List.generate(5, (index) {
          return Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: _getColorForIntensity(index / 4.0),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
        const SizedBox(width: 8),
        const Text(
          'More',
          style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
        ),
      ],
    );
  }

  double _getActivityIntensity(DateTime date) {
    final dayTasks =
        taskState.tasks.where((task) {
          return task.dueDate != null && _isSameDay(task.dueDate!, date);
        }).toList();

    final dayHabits =
        habitState.todayInstances.where((instance) {
          return _isSameDay(instance.date, date);
        }).toList();

    if (dayTasks.isEmpty && dayHabits.isEmpty) return 0.0;

    final completedTasks = dayTasks.where((t) => t.isCompleted).length;
    final completedHabits = dayHabits.where((h) => h.isCompleted).length;

    final totalItems = dayTasks.length + dayHabits.length;
    final completedItems = completedTasks + completedHabits;

    return totalItems > 0 ? completedItems / totalItems : 0.0;
  }

  Color _getColorForIntensity(double intensity) {
    if (intensity == 0.0) return AppColors.surfaceLight;
    if (intensity <= 0.25) return AppColors.accent.withAlpha(50);
    if (intensity <= 0.5) return AppColors.accent.withAlpha(100);
    if (intensity <= 0.75) return AppColors.accent.withAlpha(150);
    return AppColors.accent;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isToday(DateTime date) {
    return _isSameDay(date, DateTime.now());
  }
}
