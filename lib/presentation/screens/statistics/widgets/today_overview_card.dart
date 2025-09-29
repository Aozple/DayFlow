import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/habit_model.dart';
import 'package:dayflow/presentation/blocs/habits/habit_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TodayOverviewCard extends StatelessWidget {
  final HabitLoaded habitState;
  final TaskLoaded taskState;
  final DateTime selectedDate;
  final HabitModel? focusedHabit;

  const TodayOverviewCard({
    super.key,
    required this.habitState,
    required this.taskState,
    required this.selectedDate,
    this.focusedHabit,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = _isSameDay(selectedDate, DateTime.now());
    final stats = _calculateStats();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, AppColors.accent.withAlpha(200)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withAlpha(30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isToday ? 'Today' : _formatDate(selectedDate),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getMotivationalMessage(stats.completionRate),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  stats.completionRate >= 0.8
                      ? CupertinoIcons.star_fill
                      : CupertinoIcons.chart_pie,
                  size: 24,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Completed',
                  '${stats.completed}',
                  '${stats.total}',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withAlpha(30),
              ),
              Expanded(
                child: _buildStatItem(
                  'Streak',
                  '${stats.currentStreak}',
                  'days',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withAlpha(30),
              ),
              Expanded(
                child: _buildStatItem(
                  'Rate',
                  '${(stats.completionRate * 100).round()}%',
                  'complete',
                ),
              ),
            ],
          ),
          if (stats.completionRate > 0) ...[
            const SizedBox(height: 16),
            _buildProgressBar(stats.completionRate),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        Text(unit, style: const TextStyle(fontSize: 9, color: Colors.white60)),
      ],
    );
  }

  Widget _buildProgressBar(double progress) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Daily Progress',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(30),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  ({int completed, int total, double completionRate, int currentStreak})
  _calculateStats() {
    if (focusedHabit != null) {
      final instance =
          habitState.todayInstances
              .where(
                (i) =>
                    i.habitId == focusedHabit!.id &&
                    _isSameDay(i.date, selectedDate),
              )
              .firstOrNull;

      return (
        completed: instance?.isCompleted == true ? 1 : 0,
        total: 1,
        completionRate: instance?.isCompleted == true ? 1.0 : 0.0,
        currentStreak: focusedHabit!.currentStreak,
      );
    }

    final todayInstances =
        habitState.todayInstances
            .where((i) => _isSameDay(i.date, selectedDate))
            .toList();

    final completed = todayInstances.where((i) => i.isCompleted).length;
    final total = todayInstances.length;
    final completionRate = total > 0 ? completed / total : 0.0;

    final maxStreak = habitState.habits.fold(
      0,
      (max, habit) => habit.currentStreak > max ? habit.currentStreak : max,
    );

    return (
      completed: completed,
      total: total,
      completionRate: completionRate,
      currentStreak: maxStreak,
    );
  }

  String _getMotivationalMessage(double rate) {
    if (rate >= 1.0) return 'Perfect Day! 🎉';
    if (rate >= 0.8) return 'Great Progress! 🔥';
    if (rate >= 0.5) return 'Keep Going! 💪';
    if (rate > 0.0) return 'Good Start! 🌱';
    return 'Ready to Begin? 🚀';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
