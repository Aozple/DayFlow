import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';

/// A confirmation dialog before deleting a task or note.
///
/// This widget presents a modal dialog asking the user to confirm the deletion
/// of a task or note, with options to cancel or proceed with the deletion.
class HomeConfirmDeleteDialog extends StatelessWidget {
  /// The title of the dialog.
  final String title;

  /// The main content message of the dialog.
  final String content;

  /// Optional subtitle or additional information to display.
  final String? subtitle;

  /// Callback function when the delete action is confirmed.
  final VoidCallback onDelete;

  const HomeConfirmDeleteDialog({
    super.key,
    required this.title,
    required this.content,
    this.subtitle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(content),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis, // Truncate long descriptions.
            ),
          ],
        ],
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context), // Close dialog.
        ),
        CupertinoDialogAction(
          isDestructiveAction: true, // Make this action red.
          onPressed: () {
            Navigator.pop(context); // Close dialog.
            onDelete(); // Proceed with deletion.
          },
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
