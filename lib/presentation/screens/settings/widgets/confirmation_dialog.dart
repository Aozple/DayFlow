import 'package:flutter/cupertino.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;

  final IconData icon;

  final Color iconColor;

  final Widget content;

  final VoidCallback onConfirm;

  final String confirmText;

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
          onPressed: () => Navigator.pop(context),
        ),
        CupertinoDialogAction(
          isDestructiveAction: isDestructive,
          onPressed: onConfirm,
          child: Text(confirmText),
        ),
      ],
    );
  }
}
