import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/cupertino.dart';

/// A Cupertino-style action sheet for note options.
///
/// This widget presents a modal action sheet with various options for interacting
/// with a note, including editing, duplicating, and deleting the note.
class HomeNoteOptionsSheet extends StatelessWidget {
  /// The note to show options for.
  final TaskModel note;

  /// Callback function when the edit option is selected.
  final VoidCallback onEdit;

  /// Callback function when the duplicate option is selected.
  final VoidCallback onDuplicate;

  /// Callback function when the delete option is selected.
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
          isDestructiveAction: true, // Make this action red.
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
        onPressed: () => Navigator.pop(context), // Just close the sheet.
        child: const Text('Cancel'),
      ),
    );
  }
}
