import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

/// A confirmation dialog when the user tries to leave with unsaved changes.
///
/// This widget presents a dialog asking the user to confirm whether they want
/// to discard their unsaved changes or continue editing. It provides clear
/// options for both choices.
class CreateNoteDiscardDialog extends StatelessWidget {
  const CreateNoteDiscardDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Discard Changes?'),
      content: const Text(
        'You have unsaved changes. Are you sure you want to discard them?',
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('Keep Editing'),
          onPressed:
              () => Navigator.pop(context), // Close dialog, stay on screen.
        ),
        CupertinoDialogAction(
          isDestructiveAction: true, // Make the button red.
          onPressed: () {
            Navigator.pop(context); // Close dialog.
            context.pop(); // Close the current screen.
          },
          child: const Text('Discard'),
        ),
      ],
    );
  }
}
