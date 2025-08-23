import 'package:flutter/cupertino.dart';

/// Confirmation dialog before deleting a task.
///
/// This widget provides a confirmation dialog when the user attempts to
/// delete a task, ensuring they don't accidentally delete important tasks.
class TaskDetailsDeleteDialog extends StatelessWidget {
  /// The title of the task to be deleted.
  final String taskTitle;

  const TaskDetailsDeleteDialog({super.key, required this.taskTitle});

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Delete Task'),
      content: const Text('Are you sure you want to delete this task?'),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context, false), // Cancel button.
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true, // Red button.
          onPressed: () => Navigator.pop(context, true), // Confirm delete.
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
