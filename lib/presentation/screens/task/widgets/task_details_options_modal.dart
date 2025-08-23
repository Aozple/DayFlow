import 'package:flutter/cupertino.dart';

/// Modal with more options for the task (duplicate, share).
///
/// This widget provides additional actions for a task, such as duplicating
/// or sharing the task.
class TaskDetailsOptionsModal extends StatelessWidget {
  /// Callback function when the duplicate option is selected.
  final VoidCallback onDuplicate;

  /// Callback function when the share option is selected.
  final VoidCallback onShare;

  const TaskDetailsOptionsModal({
    super.key,
    required this.onDuplicate,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheet(
      actions: [
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context); // Close action sheet.
            onDuplicate(); // Duplicate the task.
          },
          child: const Text('Duplicate Task'),
        ),
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context); // Close action sheet.
            onShare(); // Share the task.
          },
          child: const Text('Share Task'),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.pop(context), // Cancel button.
        child: const Text('Cancel'),
      ),
    );
  }
}
