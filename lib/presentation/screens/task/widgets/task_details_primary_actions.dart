import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/cupertino.dart';

class TaskDetailsPrimaryActions extends StatelessWidget {
  final TaskModel task;

  final VoidCallback onToggleComplete;

  final VoidCallback onEdit;

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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPrimaryButton(
              icon:
                  task.isCompleted
                      ? CupertinoIcons.arrow_uturn_left
                      : CupertinoIcons.checkmark_circle,
              label: task.isCompleted ? 'Undo' : 'Complete',
              color: task.isCompleted ? AppColors.warning : AppColors.success,
              onTap: onToggleComplete,
              isFirst: true,
            ),
          ),
          Container(width: 1, height: 60, color: AppColors.divider),

          Expanded(
            child: _buildPrimaryButton(
              icon: CupertinoIcons.pencil_circle,
              label: 'Edit',
              color: AppColors.warning,
              onTap: onEdit,
              isFirst: false,
            ),
          ),
          Container(width: 1, height: 60, color: AppColors.divider),

          Expanded(
            child: _buildPrimaryButton(
              icon: CupertinoIcons.trash_circle,
              label: 'Delete',
              color: AppColors.error,
              onTap: onDelete,
              isFirst: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isFirst,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
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
