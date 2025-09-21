import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Header widget for task details screen.
///
/// Provides navigation controls and displays task status information
/// with consistent styling matching other app headers.
class TaskDetailsHeader extends StatelessWidget {
  /// The task to display in the header.
  final TaskModel task;

  /// Callback function when the back button is pressed.
  final VoidCallback onBackPressed;

  /// Callback function when the more options button is pressed.
  final VoidCallback onMoreOptions;

  // Button dimensions
  static const double _buttonHeight = 40.0;

  const TaskDetailsHeader({
    super.key,
    required this.task,
    required this.onBackPressed,
    required this.onMoreOptions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(200),
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider.withAlpha(30),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          _buildBackButton(),

          // Title and status section
          _buildTitleSection(),

          // More options button
          _buildMoreOptionsButton(),
        ],
      ),
    );
  }

  /// Build back navigation button
  Widget _buildBackButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onBackPressed,
      child: Container(
        height: _buttonHeight,
        width: _buttonHeight, // Square button
        decoration: BoxDecoration(
          color: AppColors.textSecondary.withAlpha(10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.textSecondary.withAlpha(30),
            width: 1,
          ),
        ),
        child: const Center(
          child: Icon(
            CupertinoIcons.chevron_back,
            color: AppColors.textSecondary,
            size: 18,
          ),
        ),
      ),
    );
  }

  /// Build title section with task name and completion status
  Widget _buildTitleSection() {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Task title
          Text(
            task.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          // Completion status indicator
          _buildStatusIndicator(),
        ],
      ),
    );
  }

  /// Build status indicator showing completion state
  Widget _buildStatusIndicator() {
    final isCompleted = task.isCompleted;
    final statusColor = isCompleted ? AppColors.success : AppColors.accent;
    final statusText = isCompleted ? 'Completed' : 'In Progress';
    final statusIcon =
        isCompleted
            ? CupertinoIcons.checkmark_circle_fill
            : CupertinoIcons.clock_fill;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 10, color: statusColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 11,
              color: statusColor,
              fontWeight: FontWeight.w500,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  /// Build more options button
  Widget _buildMoreOptionsButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onMoreOptions,
      child: Container(
        height: _buttonHeight,
        width: _buttonHeight, // Square button
        decoration: BoxDecoration(
          color: AppColors.accent.withAlpha(15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.accent.withAlpha(40), width: 1),
        ),
        child: Center(
          child: Icon(
            CupertinoIcons.ellipsis,
            color: AppColors.accent,
            size: 18,
          ),
        ),
      ),
    );
  }
}
