import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class TaskDetailsMetadata extends StatelessWidget {
  final TaskModel task;

  const TaskDetailsMetadata({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(150),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withAlpha(50), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                CupertinoIcons.info_circle,
                size: 18,
                color: AppColors.textTertiary,
              ),
              SizedBox(width: 8),
              Text(
                'Information',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildMetaRow(
            'Created',
            DateFormat('MMM d, yyyy • HH:mm').format(task.createdAt),
          ),

          if (task.completedAt != null) ...[
            const SizedBox(height: 8),
            _buildMetaRow(
              'Completed',
              DateFormat('MMM d, yyyy • HH:mm').format(task.completedAt!),
              valueColor: AppColors.success,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: valueColor ?? AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
