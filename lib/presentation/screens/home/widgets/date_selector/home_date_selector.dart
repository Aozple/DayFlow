import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dayflow/presentation/blocs/settings/settings_bloc.dart';
import 'home_date_item.dart';
import 'home_week_navigation.dart';

/// The horizontal date selector for navigating through days of the week.
///
/// This widget provides a visual interface for selecting dates within a week,
/// with navigation controls to move between weeks. It adapts based on user
/// settings for whether the week starts on Monday or Saturday.
class HomeDateSelector extends StatelessWidget {
  /// The currently selected date.
  final DateTime selectedDate;

  /// Callback function when a new date is selected.
  final Function(DateTime) onDateSelected;

  const HomeDateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        // Get the "Saturday first" setting from the SettingsBloc.
        final isSaturdayFirst =
            settingsState is SettingsLoaded
                ? settingsState.isSaturdayFirst
                : false; // Default to false if settings not loaded.

        return Container(
          height: 90,
          color: AppColors.surface, // Background color for the date selector.
          child: Column(
            children: [
              // Row displaying the current week range and navigation buttons.
              HomeWeekNavigation(
                selectedDate: selectedDate,
                isSaturdayFirst: isSaturdayFirst,
                onWeekChanged: (newDate) {
                  onDateSelected(newDate);
                },
              ),

              // Horizontal list of days in the current week.
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics:
                      const NeverScrollableScrollPhysics(), // Prevent manual scrolling.
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: 7, // Always show 7 days.
                  itemBuilder: (context, index) {
                    final weekStart = _getWeekStart(
                      selectedDate,
                      isSaturdayFirst,
                    ); // Get the start of the week.
                    final date = weekStart.add(
                      Duration(days: index),
                    ); // Calculate each day's date.
                    return HomeDateItem(
                      date: date,
                      selectedDate: selectedDate,
                      isSaturdayFirst: isSaturdayFirst,
                      onTap: () => onDateSelected(date),
                    ); // Build the widget for each day.
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Helper method to determine the start of the week based on settings (Monday or Saturday).
  DateTime _getWeekStart(DateTime date, bool isSaturdayFirst) {
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
}
