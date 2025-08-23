import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

/// Section displaying task metadata (created at, completed at).
///
/// This widget displays metadata about the task, including when it was
/// created and when it was completed (if applicable).
class TaskDetailsMetadata extends StatelessWidget {
  /// The task to display metadata for.
  final TaskModel task;

  const TaskDetailsMetadata({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Full width.
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(
          150,
        ), // Slightly transparent surface.
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider.withAlpha(50),
          width: 1,
        ), // Subtle border.
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                CupertinoIcons.info_circle, // Info icon.
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
          // Row for creation date.
          _buildMetaRow(
            'Created',
            DateFormat('MMM d, yyyy • HH:mm').format(task.createdAt),
          ),
          // Row for completion date, only shown if completed.
          if (task.completedAt != null) ...[
            const SizedBox(height: 8),
            _buildMetaRow(
              'Completed',
              DateFormat('MMM d, yyyy • HH:mm').format(task.completedAt!),
              valueColor: AppColors.success, // Green color for completion date.
            ),
          ],
        ],
      ),
    );
  }

  /// Helper widget to build a single metadata row (label and value).
  Widget _buildMetaRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label, // Label (e.g., "Created").
          style: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
        ),
        Text(
          value, // Value (e.g., "Aug 21, 2025 • 14:30").
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
