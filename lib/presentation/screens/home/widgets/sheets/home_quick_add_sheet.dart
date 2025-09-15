import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

/// Quick add menu for creating tasks or notes at a specific time
class HomeQuickAddSheet extends StatelessWidget {
  final int hour;
  final DateTime selectedDate;
  final Function(int) onCreateTask;
  final Function(int) onCreateNote;

  const HomeQuickAddSheet({
    super.key,
    required this.hour,
    required this.selectedDate,
    required this.onCreateTask,
    required this.onCreateNote,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheet(
      title: Text(
        'Add at ${hour.toString().padLeft(2, '0')}:00',
        style: const TextStyle(fontSize: 16),
      ),
      message: Text(
        DateFormat('EEEE, MMM d').format(selectedDate),
        style: const TextStyle(fontSize: 14),
      ),
      actions: [
        // New Task option
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
            onCreateTask(hour);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.checkmark_square_fill,
                size: 20,
                color: AppColors.accent,
              ),
              const SizedBox(width: 8),
              const Text('New Task'),
            ],
          ),
        ),
        // New Note option
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
            onCreateNote(hour);
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.doc_text_fill,
                size: 20,
                color: AppColors.warning,
              ),
              SizedBox(width: 8),
              Text('New Note'),
            ],
          ),
        ),
      ],
      // Cancel button
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
    );
  }
}
