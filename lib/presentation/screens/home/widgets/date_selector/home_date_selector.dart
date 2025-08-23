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
        final isSaturdayFirst =
            settingsState is SettingsLoaded
                ? settingsState.isSaturdayFirst
                : false;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(
                color: AppColors.divider.withAlpha(50),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            children: [
              // Week navigation
              HomeWeekNavigation(
                selectedDate: selectedDate,
                isSaturdayFirst: isSaturdayFirst,
                onWeekChanged: onDateSelected,
              ),

              // Date items container with consistent styling
              Container(
                height: 64, // Compact height
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withAlpha(100),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.divider.withAlpha(100),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: List.generate(7, (index) {
                    final weekStart = _getWeekStart(
                      selectedDate,
                      isSaturdayFirst,
                    );
                    final date = weekStart.add(Duration(days: index));

                    return Expanded(
                      child: HomeDateItem(
                        date: date,
                        selectedDate: selectedDate,
                        isSaturdayFirst: isSaturdayFirst,
                        onTap: () => onDateSelected(date),
                      ),
                    );
                  }),
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
