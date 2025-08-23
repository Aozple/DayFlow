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
    final isSelected = _isSameDay(date, selectedDate);
    final isToday = _isSameDay(date, DateTime.now());
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth =
        (screenWidth - 32) / 7; // Better spacing like week navigation

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: itemWidth,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Container(
          decoration: BoxDecoration(
            color:
                isSelected
                    ? AppColors.accent
                    : isToday
                    ? AppColors.accent.withAlpha(25)
                    : AppColors.surface, // Card-like background
            borderRadius: BorderRadius.circular(8), // Match week navigation
            border:
                isToday && !isSelected
                    ? Border.all(
                      color: AppColors.accent.withAlpha(60),
                      width: 0.5,
                    )
                    : Border.all(
                      color: AppColors.divider.withAlpha(100),
                      width: 0.5,
                    ), // Consistent border style
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: AppColors.accent.withAlpha(30),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                    : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Day name
              Text(
                _getDayName(date),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5, // Match week navigation
                  color:
                      isSelected
                          ? Colors.white
                          : isToday
                          ? AppColors.accent
                          : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              // Day number
              Text(
                date.day.toString(),
                style: TextStyle(
                  fontSize: 16, // Slightly smaller for better proportion
                  fontWeight: FontWeight.w700,
                  color:
                      isSelected
                          ? Colors.white
                          : isToday
                          ? AppColors.accent
                          : AppColors.textPrimary,
                ),
              ),
              // Today indicator dot
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
                const SizedBox(height: 6),
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
