import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/habit_instance_model.dart';
import 'package:dayflow/data/models/habit_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class HabitHeatmapCard extends StatelessWidget {
  final List<HabitModel> habits;
  final List<HabitInstanceModel> instances;
  final int year;
  final HabitModel? focusedHabit;
  final Function(DateTime) onDateTapped;

  const HabitHeatmapCard({
    super.key,
    required this.habits,
    required this.instances,
    required this.year,
    this.focusedHabit,
    required this.onDateTapped,
  });

  @override
  Widget build(BuildContext context) {
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
              Icon(CupertinoIcons.calendar, size: 20, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  focusedHabit != null
                      ? '${focusedHabit!.title} - $year'
                      : 'All Habits - $year',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildHeatmapGrid(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_buildLegend(), _buildYearNavigation()],
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapGrid() {
    final now = DateTime.now();
    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year, 12, 31);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildWeekColumns(startDate, endDate, now),
    );
  }

  List<Widget> _buildWeekColumns(
    DateTime startDate,
    DateTime endDate,
    DateTime now,
  ) {
    final columns = <Widget>[];
    var currentDate = startDate;

    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      final weekColumn = <Widget>[];

      for (int weekday = 1; weekday <= 7; weekday++) {
        if (currentDate.weekday == weekday && !currentDate.isAfter(endDate)) {
          final intensity = _getIntensityForDate(currentDate);
          final isToday = _isSameDay(currentDate, now);
          final isFuture = currentDate.isAfter(now);

          weekColumn.add(
            GestureDetector(
              onTap: () {
                if (!isFuture) {
                  HapticFeedback.lightImpact();
                  onDateTapped(currentDate);
                }
              },
              child: Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color:
                      isFuture
                          ? AppColors.surface.withAlpha(30)
                          : _getColorForIntensity(intensity),
                  borderRadius: BorderRadius.circular(2),
                  border:
                      isToday
                          ? Border.all(color: AppColors.accent, width: 1.5)
                          : null,
                ),
              ),
            ),
          );

          currentDate = currentDate.add(const Duration(days: 1));
        } else {
          weekColumn.add(
            Container(width: 12, height: 12, margin: const EdgeInsets.all(1)),
          );
        }
      }

      if (weekColumn.isNotEmpty) {
        columns.add(
          Column(mainAxisSize: MainAxisSize.min, children: weekColumn),
        );
      }
    }

    return columns;
  }

  double _getIntensityForDate(DateTime date) {
    if (focusedHabit != null) {
      final instance =
          instances
              .where(
                (i) =>
                    i.habitId == focusedHabit!.id && _isSameDay(i.date, date),
              )
              .firstOrNull;
      return instance?.isCompleted == true ? 1.0 : 0.0;
    }

    final dayInstances =
        instances.where((i) => _isSameDay(i.date, date)).toList();
    if (dayInstances.isEmpty) return 0.0;

    final completed = dayInstances.where((i) => i.isCompleted).length;
    return completed / dayInstances.length;
  }

  Color _getColorForIntensity(double intensity) {
    if (intensity == 0.0) {
      return AppColors.surface;
    } else if (intensity <= 0.25) {
      return AppColors.accent.withAlpha(60);
    } else if (intensity <= 0.5) {
      return AppColors.accent.withAlpha(120);
    } else if (intensity <= 0.75) {
      return AppColors.accent.withAlpha(180);
    } else {
      return AppColors.accent;
    }
  }

  Widget _buildLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Less',
          style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
        ),
        const SizedBox(width: 4),
        ...List.generate(5, (index) {
          return Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: _getColorForIntensity(index / 4.0),
              borderRadius: BorderRadius.circular(1),
            ),
          );
        }),
        const SizedBox(width: 4),
        const Text(
          'More',
          style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
        ),
      ],
    );
  }

  Widget _buildYearNavigation() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onDateTapped(DateTime(year - 1, 6, 15));
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            child: const Icon(
              CupertinoIcons.chevron_left,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          year.toString(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        GestureDetector(
          onTap: () {
            if (year < DateTime.now().year) {
              HapticFeedback.lightImpact();
              onDateTapped(DateTime(year + 1, 6, 15));
            }
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            child: Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color:
                  year < DateTime.now().year
                      ? AppColors.textSecondary
                      : AppColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
