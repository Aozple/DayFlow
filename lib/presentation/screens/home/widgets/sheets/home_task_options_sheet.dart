import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/cupertino.dart';

/// A Cupertino-style action sheet for task options.
///
/// This widget presents a modal action sheet with various options for interacting
/// with a task, including toggling completion, editing, viewing details,
/// duplicating, and deleting the task.
class HomeTaskOptionsSheet extends StatelessWidget {
  /// The task to show options for.
  final TaskModel task;

  /// Callback function when task completion is toggled.
  final VoidCallback onToggleComplete;

  /// Callback function when the edit option is selected.
  final VoidCallback onEdit;

  /// Callback function when the view details option is selected.
  final VoidCallback onViewDetails;

  /// Callback function when the duplicate option is selected.
  final VoidCallback onDuplicate;

  /// Callback function when the delete option is selected.
  final VoidCallback onDelete;

  const HomeTaskOptionsSheet({
    super.key,
    required this.task,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onViewDetails,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheet(
      title: Text(
        task.title,
        style: const TextStyle(fontSize: 16),
        maxLines: 2,
        overflow: TextOverflow.ellipsis, // Truncate long titles.
      ),
      message: Column(
        children: [
          // Display task status and priority.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status indicator (Completed/In Progress).
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      task.isCompleted
                          ? AppColors.success.withAlpha(20)
                          : AppColors.accent.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  task.isCompleted ? 'Completed' : 'In Progress',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        task.isCompleted ? AppColors.success : AppColors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Priority indicator (e.g., "P5").
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(task.priority).withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'P${task.priority}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getPriorityColor(task.priority),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Action to toggle task completion status.
        CupertinoActionSheetAction(
          onPressed: onToggleComplete,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                task.isCompleted
                    ? CupertinoIcons
                        .arrow_uturn_left // Icon for marking pending.
                    : CupertinoIcons
                        .checkmark_circle, // Icon for marking completed.
                size: 18,
                color: task.isCompleted ? AppColors.warning : AppColors.success,
              ),
              const SizedBox(width: 8),
              Text(
                task.isCompleted ? 'Mark as Pending' : 'Mark as Completed',
                style: TextStyle(
                  color:
                      task.isCompleted ? AppColors.warning : AppColors.success,
                ),
              ),
            ],
          ),
        ),
        // Action to edit the task.
        CupertinoActionSheetAction(
          onPressed: onEdit,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.pencil, size: 18),
              SizedBox(width: 8),
              Text('Edit Task'),
            ],
          ),
        ),
        // Action to view task details.
        CupertinoActionSheetAction(
          onPressed: onViewDetails,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.info_circle, size: 18),
              SizedBox(width: 8),
              Text('View Details'),
            ],
          ),
        ),
        // Action to duplicate the task.
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
        // Action to delete the task (destructive).
        CupertinoActionSheetAction(
          isDestructiveAction: true, // Make this action red.
          onPressed: onDelete,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.trash, size: 18),
              SizedBox(width: 8),
              Text('Delete Task'),
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

  /// Helper method to get a color based on task priority.
  Color _getPriorityColor(int priority) {
    if (priority >= 4) return AppColors.error; // High priority.
    if (priority == 3) return AppColors.warning; // Medium priority.
    return AppColors.textSecondary; // Low priority.
  }
}
