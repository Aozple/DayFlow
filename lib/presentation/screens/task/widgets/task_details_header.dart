import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TaskDetailsHeader extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onBackPressed;
  final VoidCallback onMoreOptions;

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
          _buildBackButton(),
          _buildTitleSection(),
          _buildMoreOptionsButton(),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onBackPressed,
      child: Container(
        height: _buttonHeight,
        width: _buttonHeight,
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

  Widget _buildTitleSection() {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          _buildStatusIndicator(),
        ],
      ),
    );
  }

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

  Widget _buildMoreOptionsButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onMoreOptions,
      child: Container(
        height: _buttonHeight,
        width: _buttonHeight,
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
