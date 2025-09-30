import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/cupertino.dart';

class TaskDetailsPriorityModal extends StatelessWidget {
  final TaskModel currentTask;

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
        final priority = index + 1;
        return CupertinoActionSheetAction(
          onPressed: () {
            onPriorityChanged(priority);
            Navigator.pop(context);
          },
          child: Text('Priority $priority'),
        );
      }),
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
    );
  }
}
