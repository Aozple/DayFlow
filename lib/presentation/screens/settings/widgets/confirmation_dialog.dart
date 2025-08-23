import 'package:flutter/cupertino.dart';

/// A customizable confirmation dialog for potentially destructive actions.
///
/// This widget provides a consistent dialog layout for confirming actions
/// that may have significant consequences, such as deleting data.
class ConfirmationDialog extends StatelessWidget {
  /// The title of the dialog.
  final String title;

  /// The icon to display in the dialog header.
  final IconData icon;

  /// The color of the icon.
  final Color iconColor;

  /// The content of the dialog.
  final Widget content;

  /// Callback function when the confirm button is pressed.
  final VoidCallback onConfirm;

  /// The text for the confirm button.
  final String confirmText;

  /// Whether this is a destructive action (affects styling).
  final bool isDestructive;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.content,
    required this.onConfirm,
    required this.confirmText,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: content,
      actions: [
        CupertinoDialogAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context), // Cancel action.
        ),
        CupertinoDialogAction(
          isDestructiveAction: isDestructive, // Red button if destructive.
          onPressed: onConfirm,
          child: Text(confirmText),
        ),
      ],
    );
  }
}
