import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';

class HomeConfirmDeleteDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? subtitle;
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
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),

        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () {
            Navigator.pop(context);
            onDelete();
          },
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
