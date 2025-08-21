import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
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
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                _getWeekRange(
                  selectedDate,
                ), // Display the date range of the current week.
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              // Show a "SAT" indicator if Saturday is set as the first day of the week.
              if (isSaturdayFirst) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(20),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'SAT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ],
          ),
          // Buttons for navigating to the previous and next week.
          Row(
            children: [
              CupertinoButton(
                padding: const EdgeInsets.all(4),
                minSize: 28,
                onPressed: () => _navigateWeek(-1), // Go to previous week.
                child: const Icon(
                  CupertinoIcons.chevron_left,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              CupertinoButton(
                padding: const EdgeInsets.all(4),
                minSize: 28,
                onPressed: () => _navigateWeek(1), // Go to next week.
                child: const Icon(
                  CupertinoIcons.chevron_right,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
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
