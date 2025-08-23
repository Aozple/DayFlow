import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';

/// Modal for selecting a date.
///
/// This widget provides a simple interface for selecting a date for a task,
/// with appropriate constraints and styling.
class CreateTaskDatePicker extends StatelessWidget {
  /// The currently selected date.
  final DateTime selectedDate;

  /// Callback function when the date changes.
  final Function(DateTime) onDateChanged;

  const CreateTaskDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250, // Fixed height for the date picker.
      color: AppColors.surface, // Background color of the picker.
      child: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.date, // Only show date selection.
        initialDateTime:
            selectedDate, // Start with the currently selected date.
        minimumDate: DateTime.now().subtract(
          const Duration(days: 1),
        ), // Can't select dates before yesterday.
        onDateTimeChanged: onDateChanged,
      ),
    );
  }
}
