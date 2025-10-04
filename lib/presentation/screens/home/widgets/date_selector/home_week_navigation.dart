import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HomeWeekNavigation extends StatelessWidget {
  final DateTime selectedDate;
  final bool isSaturdayFirst;
  final Function(DateTime) onWeekChanged;

  const HomeWeekNavigation({
    super.key,
    required this.selectedDate,
    required this.isSaturdayFirst,
    required this.onWeekChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider.withAlpha(100), width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.calendar,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  _getWeekRange(selectedDate),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 12),

                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push('/statistics');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withAlpha(60),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.chart_bar,
                          size: 10,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'STATS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _navigateWeek(-1),
                  child: Container(
                    width: 40,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(8),
                        right: Radius.zero,
                      ),
                    ),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      size: 24,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

                Container(
                  width: 0.5,
                  height: 24,
                  color: AppColors.divider.withAlpha(80),
                ),

                GestureDetector(
                  onTap: () => _navigateWeek(1),
                  child: Container(
                    width: 40,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.zero,
                        right: Radius.circular(8),
                      ),
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      size: 24,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getWeekRange(DateTime date) {
    final weekStart = _getWeekStart(date);
    final weekEnd = weekStart.add(const Duration(days: 6));

    if (weekStart.month == weekEnd.month) {
      return '${DateFormat('MMM d').format(weekStart)} - ${weekEnd.day}';
    } else {
      return '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d').format(weekEnd)}';
    }
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;

    if (isSaturdayFirst) {
      int daysToSubtract;
      if (weekday == 6) {
        daysToSubtract = 0;
      } else if (weekday == 7) {
        daysToSubtract = 1;
      } else {
        daysToSubtract = weekday + 1;
      }
      return date.subtract(Duration(days: daysToSubtract));
    } else {
      return date.subtract(Duration(days: weekday - 1));
    }
  }

  void _navigateWeek(int direction) {
    final newDate = selectedDate.add(Duration(days: 7 * direction));
    onWeekChanged(newDate);
  }
}
