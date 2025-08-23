import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

/// Section displaying task's schedule, priority, and color.
///
/// This widget provides a visual representation of the task's key information,
/// including due date, priority level, and assigned color.
class TaskDetailsInfoSection extends StatelessWidget {
  /// The task to display information for.
  final TaskModel task;

  /// Callback function when the reschedule button is pressed.
  final VoidCallback onReschedule;

  /// Callback function when the change priority button is pressed.
  final VoidCallback onChangePriority;

  /// Callback function when the change color button is pressed.
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
    final taskColor = AppColors.fromHex(
      task.color,
    ); // Convert hex string to Color object.

    return Container(
      width: double.infinity, // Takes full available width.
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface, // Background color.
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: taskColor, width: 4),
        ), // Left border with task's color.
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date & Time information with an edit button.
          _buildInfoItem(
            icon: CupertinoIcons.calendar, // Calendar icon.
            label: 'Schedule',
            value:
                task.dueDate != null
                    ? DateFormat('EEE, MMM d • HH:mm').format(
                      task.dueDate!,
                    ) // Format date and time.
                    : 'No date set', // Display if no due date.
            onEdit: onReschedule, // Opens date/time picker.
          ),
          const Divider(height: 24, color: AppColors.divider), // Divider.
          // Priority information with an edit button.
          _buildInfoItem(
            icon: CupertinoIcons.flag_fill, // Flag icon.
            label: 'Priority',
            value: 'Level ${task.priority}',
            valueColor: AppColors.getPriorityColor(
              task.priority,
            ), // Color based on priority.
            onEdit: onChangePriority, // Opens priority picker.
          ),
          const Divider(height: 24, color: AppColors.divider), // Divider.
          // Color information with an edit button.
          _buildInfoItem(
            icon: CupertinoIcons.paintbrush_fill, // Paintbrush icon.
            label: 'Color',
            value: null, // No text value, using custom widget.
            customWidget: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: taskColor, // Display task's color.
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider, width: 2),
              ),
            ),
            onEdit: onChangeColor, // Opens color picker.
          ),
        ],
      ),
    );
  }

  /// Helper widget to build a single info item (icon, label, value, edit button).
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    String? value,
    Color? valueColor,
    Widget? customWidget,
    required VoidCallback onEdit,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: valueColor ?? AppColors.textSecondary,
        ), // Icon.
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label, // Label (e.g., "Schedule").
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
              if (value != null) ...[
                const SizedBox(height: 2),
                Text(
                  value, // Value (e.g., "Mon, Aug 21 • 14:30").
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
              ],
              if (customWidget != null) ...[
                const SizedBox(height: 4),
                customWidget, // Custom widget if provided (e.g., color circle).
              ],
            ],
          ),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 32,
          onPressed: onEdit, // Edit button action.
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(
                20,
              ), // Subtle accent background.
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              CupertinoIcons.pencil, // Pencil icon.
              size: 16,
              color: AppColors.accent,
            ),
          ),
        ),
      ],
    );
  }
}
