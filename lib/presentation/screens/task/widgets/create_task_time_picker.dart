import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Modal for selecting a time.
///
/// This widget provides a simple interface for selecting a time for a task,
/// with appropriate styling and default values.
class CreateTaskTimePicker extends StatelessWidget {
  /// The currently selected time.
  final TimeOfDay? selectedTime;

  /// Callback function when the time changes.
  final Function(TimeOfDay) onTimeChanged;

  const CreateTaskTimePicker({
    super.key,
    required this.selectedTime,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250, // Fixed height for the time picker.
      color: AppColors.surface, // Background color of the picker.
      child: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.time, // Only show time selection.
        initialDateTime: DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          selectedTime?.hour ?? 0, // Use selected time's hour or default to 0.
          selectedTime?.minute ??
              0, // Use selected time's minute or default to 0.
        ),
        onDateTimeChanged: (date) {
          onTimeChanged(TimeOfDay(hour: date.hour, minute: date.minute));
        },
      ),
    );
  }
}
