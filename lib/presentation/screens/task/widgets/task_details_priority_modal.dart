import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/cupertino.dart';

/// Modal for quickly changing task priority.
///
/// This widget provides a simple interface for changing the priority of a task,
/// with appropriate styling and feedback.
class TaskDetailsPriorityModal extends StatelessWidget {
  /// The current task being modified.
  final TaskModel currentTask;

  /// Callback function when the priority changes.
  final Function(int) onPriorityChanged;

  const TaskDetailsPriorityModal({
    super.key,
    required this.currentTask,
    required this.onPriorityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheet(
      title: const Text('Select Priority'),
      actions: List.generate(5, (index) {
        final priority = index + 1; // Priority levels 1 to 5.
        return CupertinoActionSheetAction(
          onPressed: () {
            onPriorityChanged(priority); // Update local task with new priority.
            Navigator.pop(context); // Close action sheet.
          },
          child: Text('Priority $priority'), // Display priority level.
        );
      }),
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.pop(context), // Cancel button.
        child: const Text('Cancel'),
      ),
    );
  }
}
