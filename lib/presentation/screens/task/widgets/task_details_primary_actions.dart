import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/cupertino.dart';

/// Row of primary action buttons (Complete/Undo, Edit, Delete).
///
/// This widget provides the main actions for a task, including toggling
/// completion status, editing, and deleting the task.
class TaskDetailsPrimaryActions extends StatelessWidget {
  /// The task to display actions for.
  final TaskModel task;

  /// Callback function when the complete/undo button is pressed.
  final VoidCallback onToggleComplete;

  /// Callback function when the edit button is pressed.
  final VoidCallback onEdit;

  /// Callback function when the delete button is pressed.
  final VoidCallback onDelete;

  const TaskDetailsPrimaryActions({
    super.key,
    required this.task,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface, // Background color for the action bar.
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Button to mark task as complete or undo completion.
          Expanded(
            child: _buildPrimaryButton(
              icon:
                  task.isCompleted
                      ? CupertinoIcons
                          .arrow_uturn_left // Undo icon.
                      : CupertinoIcons.checkmark_circle, // Complete icon.
              label: task.isCompleted ? 'Undo' : 'Complete',
              color:
                  task.isCompleted
                      ? AppColors
                          .warning // Warning color for undo.
                      : AppColors.success, // Success color for complete.
              onTap: onToggleComplete, // Toggles completion status.
              isFirst: true, // Marks as the first button for styling.
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: AppColors.divider,
          ), // Vertical divider.
          // Button to edit the task.
          Expanded(
            child: _buildPrimaryButton(
              icon: CupertinoIcons.pencil_circle, // Pencil icon.
              label: 'Edit',
              color: AppColors.warning, // Accent color.
              onTap: onEdit, // Navigates to edit screen.
              isFirst: false,
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: AppColors.divider,
          ), // Vertical divider.
          // Button to delete the task.
          Expanded(
            child: _buildPrimaryButton(
              icon: CupertinoIcons.trash_circle, // Trash icon.
              label: 'Delete',
              color: AppColors.error, // Error color for destructive action.
              onTap: onDelete, // Shows delete confirmation.
              isFirst: false,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper widget to build a single primary action button.
  Widget _buildPrimaryButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool
    isFirst, // Not directly used for styling here, but good for consistency.
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        height: 80, // Fixed height for consistent layout.
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28), // Icon.
            const SizedBox(height: 6),
            Text(
              label, // Button label.
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
