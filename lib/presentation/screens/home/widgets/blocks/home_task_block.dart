import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HomeTaskBlock extends StatefulWidget {
  final TaskModel task;
  final Function(TaskModel) onToggleComplete;
  final Function(TaskModel) onOptions;

  const HomeTaskBlock({
    super.key,
    required this.task,
    required this.onToggleComplete,
    required this.onOptions,
  });

  @override
  State<HomeTaskBlock> createState() => _HomeTaskBlockState();
}

class _HomeTaskBlockState extends State<HomeTaskBlock> {
  @override
  Widget build(BuildContext context) {
    final isDefaultColor =
        widget.task.color == '#2C2C2E' || widget.task.color == '#8E8E93';
    final taskColor =
        isDefaultColor
            ? AppColors.textSecondary
            : AppColors.fromHex(widget.task.color);

    if (widget.task.isNote) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => context.push('/task-details', extra: widget.task),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: _buildContainerDecoration(taskColor, isDefaultColor),
        child: Row(
          children: [
            _buildColorIndicator(taskColor),
            const SizedBox(width: 12),

            Expanded(child: _buildMainContent(taskColor)),
            const SizedBox(width: 8),

            _buildVerticalOptionsButton(taskColor),
            const SizedBox(width: 8),

            _buildCompletionCheckbox(taskColor),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildContainerDecoration(
    Color taskColor,
    bool isDefaultColor,
  ) {
    Color backgroundColor;
    Color borderColor;

    if (widget.task.isCompleted) {
      backgroundColor = AppColors.surface.withAlpha(75);
      borderColor = AppColors.divider.withAlpha(25);
    } else if (isDefaultColor) {
      backgroundColor = AppColors.surfaceLight;
      borderColor = AppColors.divider.withAlpha(50);
    } else {
      backgroundColor = taskColor.withAlpha(20);
      borderColor = taskColor.withAlpha(60);
    }

    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: borderColor, width: 1),
      boxShadow:
          widget.task.isCompleted
              ? [
                BoxShadow(
                  color: taskColor.withAlpha(20),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
              : null,
    );
  }

  Widget _buildVerticalOptionsButton(Color taskColor) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onOptions(widget.task);
      },
      child: Container(
        width: 20,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface.withAlpha(30),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDot(
              widget.task.isCompleted
                  ? AppColors.textTertiary.withAlpha(60)
                  : taskColor.withAlpha(120),
            ),
            const SizedBox(height: 4),
            _buildDot(
              widget.task.isCompleted
                  ? AppColors.textTertiary.withAlpha(60)
                  : taskColor.withAlpha(120),
            ),
            const SizedBox(height: 4),
            _buildDot(
              widget.task.isCompleted
                  ? AppColors.textTertiary.withAlpha(60)
                  : taskColor.withAlpha(120),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildColorIndicator(Color taskColor) {
    final priorityColor = AppColors.getPriorityColor(widget.task.priority);

    return Container(
      width: 4,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors:
              widget.task.isCompleted
                  ? [
                    AppColors.textTertiary.withAlpha(50),
                    AppColors.textTertiary.withAlpha(30),
                  ]
                  : [priorityColor, priorityColor.withAlpha(150)],
        ),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildMainContent(Color taskColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTitleRow(taskColor),

        if (_shouldShowMetadata()) ...[
          const SizedBox(height: 6),
          _buildMetadataRow(taskColor),
        ],
      ],
    );
  }

  Widget _buildTitleRow(Color taskColor) {
    final textColor =
        widget.task.isCompleted
            ? AppColors.textSecondary.withAlpha(120)
            : AppColors.textPrimary;

    return Row(
      children: [
        _buildPriorityBadge(),
        const SizedBox(width: 8),

        Expanded(
          child: Text(
            widget.task.title,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight:
                  widget.task.isCompleted ? FontWeight.w500 : FontWeight.w600,
              decoration:
                  widget.task.isCompleted ? TextDecoration.lineThrough : null,
              decorationColor: AppColors.textTertiary.withAlpha(80),
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityBadge() {
    final priorityColor = AppColors.getPriorityColor(widget.task.priority);
    final isHighPriority = widget.task.priority >= 4;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color:
            widget.task.isCompleted
                ? AppColors.textTertiary.withAlpha(15)
                : priorityColor.withAlpha(15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        isHighPriority ? CupertinoIcons.exclamationmark : CupertinoIcons.flag,
        size: 10,
        color: widget.task.isCompleted ? AppColors.textTertiary : priorityColor,
      ),
    );
  }

  Widget _buildMetadataRow(Color taskColor) {
    final metadataColor =
        widget.task.isCompleted
            ? AppColors.textTertiary
            : AppColors.textSecondary;

    return Row(
      children: [
        if (widget.task.dueDate != null) ...[
          Icon(CupertinoIcons.clock, size: 10, color: metadataColor),
          const SizedBox(width: 4),
          Text(
            DateFormat('HH:mm').format(widget.task.dueDate!),
            style: TextStyle(
              color: metadataColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (widget.task.hasNotification) ...[
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.bell_solid,
              size: 8,
              color:
                  widget.task.isCompleted
                      ? AppColors.textTertiary.withAlpha(100)
                      : AppColors.accent.withAlpha(150),
            ),
          ],
          if (widget.task.tags.isNotEmpty) const SizedBox(width: 12),
        ],

        if (widget.task.tags.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color:
                  widget.task.isCompleted
                      ? AppColors.textTertiary.withAlpha(10)
                      : taskColor.withAlpha(10),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '#${widget.task.tags.length}',
              style: TextStyle(
                color:
                    widget.task.isCompleted
                        ? AppColors.textTertiary
                        : taskColor,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompletionCheckbox(Color taskColor) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onToggleComplete(widget.task);
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color:
              widget.task.isCompleted ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                widget.task.isCompleted ? AppColors.accent : AppColors.divider,
            width: 2,
          ),
          boxShadow:
              widget.task.isCompleted
                  ? [
                    BoxShadow(
                      color: AppColors.accent.withAlpha(30),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child:
            widget.task.isCompleted
                ? const Icon(Icons.done_rounded, size: 18, color: Colors.white)
                : null,
      ),
    );
  }

  bool _shouldShowMetadata() {
    return widget.task.dueDate != null || widget.task.tags.isNotEmpty;
  }
}
