import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/cupertino.dart';

/// Modal for quickly rescheduling a task.
///
/// This widget provides a simple interface for changing the due date and time
/// of a task, with appropriate styling and default values.
class TaskDetailsRescheduleModal extends StatelessWidget {
  /// The current task being rescheduled.
  final TaskModel currentTask;

  /// Callback function when the date changes.
  final Function(DateTime) onDateChanged;

  const TaskDetailsRescheduleModal({
    super.key,
    required this.currentTask,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      color: AppColors.surface, // Background color.
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context), // Cancel button.
                  child: const Text('Cancel'),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    Navigator.pop(
                      context,
                      currentTask.dueDate,
                    ); // Pass current due date back.
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
          Expanded(
            child: CupertinoDatePicker(
              mode:
                  CupertinoDatePickerMode
                      .dateAndTime, // Allow date and time selection.
              initialDateTime:
                  currentTask.dueDate ?? DateTime.now(), // Initial date.
              onDateTimeChanged: onDateChanged,
            ),
          ),
        ],
      ),
    );
  }
}
