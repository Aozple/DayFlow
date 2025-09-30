import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/cupertino.dart';

class HomeNoteOptionsSheet extends StatelessWidget {
  final TaskModel note;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const HomeNoteOptionsSheet({
    super.key,
    required this.note,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheet(
      title: Text(note.title, style: const TextStyle(fontSize: 16)),
      message: const Text('What would you like to do with this note?'),
      actions: [
        CupertinoActionSheetAction(
          onPressed: onEdit,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.pencil, size: 18),
              SizedBox(width: 8),
              Text('Edit Note'),
            ],
          ),
        ),

        CupertinoActionSheetAction(
          onPressed: onDuplicate,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.doc_on_doc, size: 18),
              SizedBox(width: 8),
              Text('Duplicate'),
            ],
          ),
        ),

        CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: onDelete,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.trash, size: 18),
              SizedBox(width: 8),
              Text('Delete Note'),
            ],
          ),
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
