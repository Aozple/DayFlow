import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

/// A quick add menu (action sheet) to create a new task or note at a specific hour.
/// 
/// This widget presents a modal action sheet allowing users to quickly create
/// a new task or note at a specific hour on the selected date.
class HomeQuickAddSheet extends StatelessWidget {
  /// The hour at which to create the new task or note.
  final int hour;
  
  /// The selected date for the new task or note.
  final DateTime selectedDate;
  
  /// Callback function when creating a new task.
  final Function(int) onCreateTask;
  
  /// Callback function when creating a new note.
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
        'Add at ${hour.toString().padLeft(2, '0')}:00', // Display the selected hour.
        style: const TextStyle(fontSize: 16),
      ),
      message: Text(
        DateFormat(
          'EEEE, MMM d',
        ).format(selectedDate), // Display the selected date.
        style: const TextStyle(fontSize: 14),
      ),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context); // Close the action sheet.
            onCreateTask(hour); // Create a new task at this hour.
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.checkmark_square_fill, // Task icon.
                size: 20,
                color: AppColors.accent,
              ),
              const SizedBox(width: 8),
              const Text('New Task'),
            ],
          ),
        ),
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context); // Close the action sheet.
            onCreateNote(hour); // Create a new note at this hour.
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.doc_text_fill, // Note icon.
                size: 20,
                color: AppColors.warning,
              ),
              SizedBox(width: 8),
              Text('New Note'),
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