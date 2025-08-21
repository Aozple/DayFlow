import 'dart:ui';

import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// The header section of the home screen, including date display and action buttons.
///
/// This widget displays the currently selected date in a prominent format and provides
/// quick access to common actions like returning to today, filtering tasks, searching,
/// and accessing settings.
class HomeHeader extends StatelessWidget {
  /// The currently selected date to display.
  final DateTime selectedDate;

  /// Callback function when a new date is selected.
  final Function(DateTime) onDateSelected;

  /// Whether any filters are currently active.
  final bool hasActiveFilters;

  /// Callback function when the filter button is pressed.
  final VoidCallback onFilterPressed;

  /// Callback function when the search button is pressed.
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
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 10,
          sigmaY: 10,
        ), // Apply a blur effect.
        child: Container(
          color: AppColors.surface.withAlpha(
            200,
          ), // Semi-transparent background.
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Column for displaying the selected date.
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE').format(
                      selectedDate,
                    ), // Day of the week (e.g., "Wednesday").
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    DateFormat(
                      'd MMM',
                    ).format(selectedDate), // Day and month (e.g., "21 Aug").
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              // Row for action buttons (Today, Filter, Search, Settings).
              Row(
                children: [
                  // "Today" button, visible only if the selected date is not today.
                  if (!_isSameDay(selectedDate, DateTime.now()))
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        final today = DateTime.now();
                        onDateSelected(today); // Set selected date to today.
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
                  // Filter button with an indicator if filters are active.
                  CupertinoButton(
                    padding: const EdgeInsets.all(4),
                    minSize: 28,
                    onPressed: onFilterPressed, // Open the filter modal.
                    child: Stack(
                      children: [
                        const Icon(
                          CupertinoIcons.slider_horizontal_3, // Filter icon.
                          color: AppColors.textSecondary,
                          size: 24,
                        ),
                        // Small dot indicator if any filters are applied.
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
                  // Search button.
                  CupertinoButton(
                    padding: const EdgeInsets.all(4),
                    minSize: 28,
                    onPressed: onSearchPressed, // Open the search delegate.
                    child: const Icon(
                      CupertinoIcons.search, // Search icon.
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Settings button.
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      context.push('/settings'); // Navigate to settings screen.
                    },
                    child: const Icon(
                      CupertinoIcons.gear, // Settings icon.
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper method to check if two DateTime objects represent the same day (ignoring time).
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
