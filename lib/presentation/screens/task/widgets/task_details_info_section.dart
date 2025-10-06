import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/core/utils/app_color_utils.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class TaskDetailsInfoSection extends StatelessWidget {
  final TaskModel task;

  final VoidCallback onReschedule;

  final VoidCallback onChangePriority;

  final VoidCallback onChangeColor;

  const TaskDetailsInfoSection({
    super.key,
    required this.task,
    required this.onReschedule,
    required this.onChangePriority,
    required this.onChangeColor,
  });

  @override
  Widget build(BuildContext context) {
    final taskColor = AppColorUtils.fromHex(task.color);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: taskColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoItem(
            context,
            icon: CupertinoIcons.calendar,
            label: 'Schedule',
            value:
                task.dueDate != null
                    ? DateFormat('EEE, MMM d • HH:mm').format(task.dueDate!)
                    : 'No date set',
            onEdit: onReschedule,
          ),
          const Divider(height: 24, color: AppColors.divider),

          _buildInfoItem(
            context,
            icon: CupertinoIcons.flag_fill,
            label: 'Priority',
            value: 'Level ${task.priority}',
            valueColor: AppColors.getPriorityColor(task.priority),
            onEdit: onChangePriority,
          ),
          const Divider(height: 24, color: AppColors.divider),

          _buildInfoItem(
            context,
            icon: CupertinoIcons.paintbrush_fill,
            label: 'Color',
            value: null,
            customWidget: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: taskColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider, width: 2),
              ),
            ),
            onEdit: onChangeColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? value,
    Color? valueColor,
    Widget? customWidget,
    required VoidCallback onEdit,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: valueColor ?? AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
              if (value != null) ...[
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
              ],
              if (customWidget != null) ...[
                const SizedBox(height: 4),
                customWidget,
              ],
            ],
          ),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: const Size(32, 32),
          onPressed: onEdit,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              CupertinoIcons.pencil,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
