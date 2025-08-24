import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// The week navigation component showing the current week range and navigation buttons.
///
/// This widget displays the date range of the current week (e.g., "Aug 21 - 27")
/// and provides buttons to navigate to the previous or next week. It also shows
/// an indicator when Saturday is set as the first day of the week.
class HomeWeekNavigation extends StatelessWidget {
  /// The currently selected date.
  final DateTime selectedDate;

  /// Whether the week starts on Saturday (affects display).
  final bool isSaturdayFirst;

  /// Callback function when the week is changed.
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
          // Week range and indicator
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
                // Saturday indicator
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

          // Navigation buttons
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
                // Divider
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

  /// Helper method to format the week range string (e.g., "Aug 21 - 27" or "Aug 21 - Sep 3").
  String _getWeekRange(DateTime date) {
    final weekStart = _getWeekStart(date); // Get the start date of the week.
    final weekEnd = weekStart.add(
      const Duration(days: 6),
    ); // Get the end date of the week.

    if (weekStart.month == weekEnd.month) {
      // If both start and end are in the same month.
      return '${DateFormat('MMM d').format(weekStart)} - ${weekEnd.day}';
    } else {
      // If the week spans two months.
      return '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d').format(weekEnd)}';
    }
  }

  /// Helper method to determine the start of the week based on settings (Monday or Saturday).
  DateTime _getWeekStart(DateTime date) {
    final weekday =
        date.weekday; // Get the day of the week (1 for Monday, 7 for Sunday).

    if (isSaturdayFirst) {
      // If Saturday is the first day of the week (weekday 6).
      int daysToSubtract;
      if (weekday == 6) {
        daysToSubtract = 0; // If it's Saturday, subtract 0 days.
      } else if (weekday == 7) {
        daysToSubtract =
            1; // If it's Sunday, subtract 1 day to get to Saturday.
      } else {
        daysToSubtract =
            weekday +
            1; // For Monday-Friday, calculate days to subtract to get to Saturday.
      }
      return date.subtract(Duration(days: daysToSubtract));
    } else {
      // Default behavior: Monday is the first day of the week.
      return date.subtract(Duration(days: weekday - 1));
    }
  }

  /// Navigates the selected date by a full week (forward or backward).
  void _navigateWeek(int direction) {
    final newDate = selectedDate.add(
      Duration(days: 7 * direction),
    ); // Add or subtract 7 days.
    onWeekChanged(newDate);
  }
}
