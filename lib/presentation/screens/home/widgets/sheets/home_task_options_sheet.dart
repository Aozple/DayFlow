import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/cupertino.dart';

/// Action sheet for task operations
class HomeTaskOptionsSheet extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggleComplete;
  final VoidCallback onEdit;
  final VoidCallback onViewDetails;
  final VoidCallback onDuplicate;
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
        overflow: TextOverflow.ellipsis,
      ),
      message: Column(
        children: [
          // Status and priority indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status badge
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
              // Priority badge
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
        // Toggle completion status
        CupertinoActionSheetAction(
          onPressed: onToggleComplete,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                task.isCompleted
                    ? CupertinoIcons.arrow_uturn_left
                    : CupertinoIcons.checkmark_circle,
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
        // Edit task
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
        // View task details
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
        // Duplicate task
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
        // Delete task (red)
        CupertinoActionSheetAction(
          isDestructiveAction: true,
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
      // Cancel button
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
    );
  }

  /// Get color based on task priority
  Color _getPriorityColor(int priority) {
    if (priority >= 4) return AppColors.error; // High priority
    if (priority == 3) return AppColors.warning; // Medium priority
    return AppColors.textSecondary; // Low priority
  }
}
