import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeDateItem extends StatelessWidget {
  final DateTime date;
  final DateTime selectedDate;
  final bool isSaturdayFirst;
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
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? colorScheme.primary
                  : isToday
                  ? colorScheme.primary.withAlpha(25)
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected
                    ? Colors.transparent
                    : isToday
                    ? colorScheme.primary.withAlpha(60)
                    : AppColors.divider.withAlpha(100),
            width: 0.5,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: colorScheme.primary.withAlpha(30),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _getDayName(date),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color:
                    isSelected
                        ? Colors.white
                        : isToday
                        ? colorScheme.primary
                        : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              date.day.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color:
                    isSelected
                        ? Colors.white
                        : isToday
                        ? colorScheme.primary
                        : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayName(DateTime date) {
    if (isSaturdayFirst) {
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
          return '';
      }
    }
    return DateFormat('E').format(date).substring(0, 3).toUpperCase();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
