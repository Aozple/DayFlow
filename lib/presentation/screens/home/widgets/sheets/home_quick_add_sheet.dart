import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeQuickAddSheet extends StatelessWidget {
  final int hour;
  final DateTime selectedDate;
  final Function(int) onCreateTask;
  final Function(int) onCreateNote;
  final Function(int) onCreateHabit;

  const HomeQuickAddSheet({
    super.key,
    required this.hour,
    required this.selectedDate,
    required this.onCreateTask,
    required this.onCreateNote,
    required this.onCreateHabit,
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
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('New Task'),
            ],
          ),
        ),

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

        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
            onCreateHabit(hour);
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.repeat, size: 20, color: AppColors.info),
              SizedBox(width: 8),
              Text('New Habit'),
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
