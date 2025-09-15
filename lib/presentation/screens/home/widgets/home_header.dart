import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Header section of the home screen with date display and action buttons
class HomeHeader extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final bool hasActiveFilters;
  final VoidCallback onFilterPressed;
  final VoidCallback onSearchPressed;

  const HomeHeader({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.hasActiveFilters,
    required this.onFilterPressed,
    required this.onSearchPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Container(
        color: AppColors.surface.withAlpha(200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Date display section
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE').format(selectedDate),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    DateFormat('d MMM').format(selectedDate),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            // Action buttons row
            Row(
              children: [
                // "Today" button - only visible when not on today's date
                if (!_isSameDay(selectedDate, DateTime.now()))
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      final today = DateTime.now();
                      onDateSelected(today);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Today',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                // Filter button with active indicator
                CupertinoButton(
                  padding: const EdgeInsets.all(4),
                  minSize: 28,
                  onPressed: onFilterPressed,
                  child: Stack(
                    children: [
                      const Icon(
                        CupertinoIcons.slider_horizontal_3,
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                      // Indicator dot for active filters
                      if (hasActiveFilters)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Search button
                CupertinoButton(
                  padding: const EdgeInsets.all(4),
                  minSize: 28,
                  onPressed: onSearchPressed,
                  child: const Icon(
                    CupertinoIcons.search,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Settings button
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    context.push('/settings');
                  },
                  child: const Icon(
                    CupertinoIcons.gear,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
