import 'package:flutter/cupertino.dart';

class TaskDetailsOptionsModal extends StatelessWidget {
  final VoidCallback onDuplicate;

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
            Navigator.pop(context);
            onDuplicate();
          },
          child: const Text('Duplicate Task'),
        ),
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
            onShare();
          },
          child: const Text('Share Task'),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
    );
  }
}
