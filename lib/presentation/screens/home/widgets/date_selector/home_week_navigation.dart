import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Week navigation component with date range and navigation buttons
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
          // Week range display with first day indicator
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
                // Saturday first day indicator
                if (isSaturdayFirst) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.accent.withAlpha(60),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      'SAT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Week navigation buttons
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Previous week button
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
                // Divider between buttons
                Container(
                  width: 0.5,
                  height: 24,
                  color: AppColors.divider.withAlpha(80),
                ),
                // Next week button
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

  /// Format week range string (e.g., "Aug 21 - 27" or "Aug 21 - Sep 3")
  String _getWeekRange(DateTime date) {
    final weekStart = _getWeekStart(date);
    final weekEnd = weekStart.add(const Duration(days: 6));

    if (weekStart.month == weekEnd.month) {
      // Same month format
      return '${DateFormat('MMM d').format(weekStart)} - ${weekEnd.day}';
    } else {
      // Different month format
      return '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d').format(weekEnd)}';
    }
  }

  /// Calculate first day of week based on settings
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday; // 1 for Monday, 7 for Sunday

    if (isSaturdayFirst) {
      // Saturday-first week calculation
      int daysToSubtract;
      if (weekday == 6) {
        daysToSubtract = 0; // Saturday
      } else if (weekday == 7) {
        daysToSubtract = 1; // Sunday
      } else {
        daysToSubtract = weekday + 1; // Monday-Friday
      }
      return date.subtract(Duration(days: daysToSubtract));
    } else {
      // Monday-first week calculation
      return date.subtract(Duration(days: weekday - 1));
    }
  }

  /// Navigate to previous or next week
  void _navigateWeek(int direction) {
    final newDate = selectedDate.add(Duration(days: 7 * direction));
    onWeekChanged(newDate);
  }
}
