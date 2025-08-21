import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// An individual date item (day of the week and day number) in the date selector.
///
/// This widget represents a single day in the date selector, displaying the day name
/// (e.g., MON) and day number (e.g., 21). It highlights the selected date and
/// provides a subtle indicator for today's date.
class HomeDateItem extends StatelessWidget {
  /// The date represented by this item.
  final DateTime date;

  /// The currently selected date.
  final DateTime selectedDate;

  /// Whether the week starts on Saturday (affects day name display).
  final bool isSaturdayFirst;

  /// Callback function when this date item is tapped.
  final VoidCallback onTap;

  const HomeDateItem({
    super.key,
    required this.date,
    required this.selectedDate,
    required this.isSaturdayFirst,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = _isSameDay(
      date,
      selectedDate,
    ); // Check if this date is currently selected.
    final isToday = _isSameDay(
      date,
      DateTime.now(),
    ); // Check if this date is today.
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth =
        (screenWidth - 16) / 7; // Calculate width for each day item.

    return GestureDetector(
      onTap: onTap, // Update selected date on tap.
      child: Container(
        width: itemWidth,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Container(
          decoration: BoxDecoration(
            color:
                isSelected
                    ? AppColors
                        .accent // Highlight color if selected.
                    : isToday
                    ? AppColors.accent.withAlpha(
                      30,
                    ) // Subtle highlight if today.
                    : Colors.transparent, // No background if neither.
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Display the day name (e.g., "MON", "TUE").
              Text(
                _getDayName(date),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color:
                      isSelected
                          ? Colors
                              .white // White text if selected.
                          : isToday
                          ? AppColors
                              .accent // Accent color if today.
                          : AppColors
                              .textSecondary, // Secondary text color otherwise.
                ),
              ),
              const SizedBox(height: 2),
              // Display the day number (e.g., "21").
              Text(
                date.day.toString(),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color:
                      isSelected
                          ? Colors
                              .white // White text if selected.
                          : isToday
                          ? AppColors
                              .accent // Accent color if today.
                          : AppColors
                              .textPrimary, // Primary text color otherwise.
                ),
              ),
              // Small dot indicator for "Today" if not selected.
              if (isToday && !isSelected) ...[
                const SizedBox(height: 2),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ] else
                const SizedBox(height: 6), // Spacer if no dot.
            ],
          ),
        ),
      ),
    );
  }

  /// Helper method to get the correct 3-letter day name based on settings.
  String _getDayName(DateTime date) {
    if (isSaturdayFirst) {
      // Custom day names if Saturday is the first day.
      switch (date.weekday) {
        case 6:
          return 'SAT';
        case 7:
          return 'SUN';
        case 1:
          return 'MON';
        case 2:
          return 'TUE';
        case 3:
          return 'WED';
        case 4:
          return 'THU';
        case 5:
          return 'FRI';
        default:
          return DateFormat('E').format(date).substring(0, 3).toUpperCase();
      }
    } else {
      // Standard 3-letter day names.
      return DateFormat('E').format(date).substring(0, 3).toUpperCase();
    }
  }

  /// Helper method to check if two DateTime objects represent the same day (ignoring time).
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
