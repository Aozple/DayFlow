import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dayflow/presentation/blocs/settings/settings_bloc.dart';
import 'home_date_item.dart';
import 'home_week_navigation.dart';

/// Horizontal date selector for navigating through days
class HomeDateSelector extends StatelessWidget {
  final DateTime selectedDate;
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
        // Get first day of week setting
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
              // Week navigation controls
              HomeWeekNavigation(
                selectedDate: selectedDate,
                isSaturdayFirst: isSaturdayFirst,
                onWeekChanged: onDateSelected,
              ),

              // Day selector row
              Container(
                height: 64,
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
                    // Calculate date for each day in the week
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

  /// Calculate the first day of the week based on settings
  DateTime _getWeekStart(DateTime date, bool isSaturdayFirst) {
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
}
