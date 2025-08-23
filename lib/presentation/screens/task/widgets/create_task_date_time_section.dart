import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Section for selecting the task's date and time.
///
/// This widget provides controls for selecting a date and optionally a time
/// for the task, with visual indicators for prefilled values.
class CreateTaskDateTimeSection extends StatelessWidget {
  /// The currently selected date.
  final DateTime selectedDate;

  /// The currently selected time.
  final TimeOfDay? selectedTime;

  /// Whether a specific time is set for the task.
  final bool hasTime;

  /// Whether the date was prefilled from another screen.
  final bool isPrefilled;

  /// Callback function when the date changes.
  final Function(DateTime) onDateChanged;

  /// Callback function when the time changes.
  final Function(bool, TimeOfDay?) onTimeChanged;

  /// Callback function to open the date picker.
  final VoidCallback onSelectDate;

  /// Callback function to open the time picker.
  final VoidCallback onSelectTime;

  const CreateTaskDateTimeSection({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.hasTime,
    required this.isPrefilled,
    required this.onDateChanged,
    required this.onTimeChanged,
    required this.onSelectDate,
    required this.onSelectTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        // Add a subtle border if the date was prefilled.
        border:
            isPrefilled
                ? Border.all(color: AppColors.accent.withAlpha(50), width: 1)
                : null,
      ),
      child: Column(
        children: [
          // List tile for picking the date.
          ListTile(
            leading: Icon(
              CupertinoIcons.calendar,
              color: AppColors.accent,
              size: 22,
            ),
            title: const Text(
              'Date',
              style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
            ),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onSelectDate, // Opens the date picker.
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Show a "Prefilled" tag if the date came from another screen.
                  if (isPrefilled) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Prefilled',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  // Display the selected date.
                  Text(
                    DateFormat('EEE, MMM d').format(selectedDate),
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 15,
                      fontWeight:
                          isPrefilled ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Divider below the date picker.
          Container(
            height: 0.5,
            margin: const EdgeInsets.only(left: 56),
            color: AppColors.divider,
          ),
          // Switch to enable/disable time selection for the task.
          SwitchListTile(
            secondary: Icon(
              CupertinoIcons.clock,
              color: hasTime ? AppColors.accent : AppColors.textSecondary,
              size: 22,
            ),
            title: const Text(
              'Time',
              style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
            ),
            value: hasTime,
            onChanged: (value) => onTimeChanged(value, selectedTime),
            activeColor: AppColors.accent,
          ),
          // Time picker section, only visible if hasTime is true.
          if (hasTime) ...[
            // Divider above the time picker.
            Container(
              height: 0.5,
              margin: const EdgeInsets.only(left: 56),
              color: AppColors.divider,
            ),
            ListTile(
              leading: const SizedBox(
                width: 22,
              ), // Aligns with other list tiles.
              title: const Text(
                'Time',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Show a "Prefilled" tag if the time came from another screen.
                  if (isPrefilled) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Prefilled',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  // Button to open the time picker.
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: onSelectTime,
                    child: Text(
                      selectedTime?.format(context) ??
                          'Select time', // Display selected time or a placeholder.
                      style: TextStyle(color: AppColors.accent, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
