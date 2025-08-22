import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A Cupertino-style modal for selecting the note's date and time.
///
/// This widget provides a date and time picker interface for setting when
/// the note is scheduled or due. It combines both date and time selection
/// in a single modal with a clean, iOS-style interface.
class CreateNoteDateTimePicker extends StatelessWidget {
  /// The initially selected date.
  final DateTime selectedDate;

  /// The initially selected time.
  final TimeOfDay selectedTime;

  /// Callback function when the date and time are changed.
  final Function(DateTime) onDateTimeChanged;

  const CreateNoteDateTimePicker({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.onDateTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: const BoxDecoration(
        color: AppColors.surface, // Background color.
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ), // Rounded top corners.
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            // Header for the date/time picker modal.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.divider,
                    width: 0.5,
                  ), // Bottom divider.
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context), // Cancel button.
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const Text(
                    'Select Date & Time', // Title.
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context), // Done button.
                    child: Text(
                      'Done',
                      style: TextStyle(color: AppColors.accent),
                    ),
                  ),
                ],
              ),
            ),
            // The Cupertino date and time picker itself.
            Expanded(
              child: CupertinoDatePicker(
                mode:
                    CupertinoDatePickerMode
                        .dateAndTime, // Allow both date and time selection.
                initialDateTime: DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                ),
                onDateTimeChanged: onDateTimeChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
