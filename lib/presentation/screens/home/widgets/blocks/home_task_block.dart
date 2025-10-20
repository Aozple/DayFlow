import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/core/utils/app_color_utils.dart';
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
            ? Theme.of(context).colorScheme.primary
            : AppColorUtils.fromHex(widget.task.color);

    if (widget.task.isNote) {
      return const SizedBox.shrink();
    }

    return Dismissible(
      key: ValueKey(widget.task.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        decoration: BoxDecoration(
          color: taskColor.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        child: Icon(CupertinoIcons.ellipsis, color: taskColor),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          HapticFeedback.lightImpact();
          widget.onOptions(widget.task);
        }
        return false;
      },
      child: GestureDetector(
        onTap: () => context.push('/task-details', extra: widget.task),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: _buildContainerDecoration(taskColor, isDefaultColor),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _buildMainContent(taskColor, isDefaultColor)),
              const SizedBox(width: 8),
              _buildCompletionCheckbox(taskColor),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildContainerDecoration(
    Color taskColor,
    bool isDefaultColor,
  ) {
    Color backgroundColor;

    if (widget.task.isCompleted) {
      backgroundColor = AppColors.surface.withAlpha(75);
    } else if (isDefaultColor) {
      backgroundColor = AppColors.surfaceLight;
    } else {
      backgroundColor = taskColor.withAlpha(20);
    }

    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: taskColor, width: 2),
      boxShadow:
          widget.task.isCompleted
              ? null
              : [
                BoxShadow(
                  color:
                      isDefaultColor
                          ? Colors.black.withAlpha(10)
                          : taskColor.withAlpha(15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
    );
  }

  Widget _buildMainContent(Color taskColor, bool isDefaultColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTitleRow(),
        if (_shouldShowMetadata()) ...[
          const SizedBox(height: 8),
          _buildMetadataRow(taskColor, isDefaultColor),
        ],
      ],
    );
  }

  Widget _buildTitleRow() {
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
    final iconColor =
        widget.task.isCompleted ? AppColors.textTertiary : priorityColor;
    final isHighPriority = widget.task.priority >= 4;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: iconColor.withAlpha(15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        isHighPriority ? CupertinoIcons.exclamationmark : CupertinoIcons.flag,
        size: 12,
        color: iconColor,
      ),
    );
  }

  Widget _buildMetadataRow(Color taskColor, bool isDefaultColor) {
    final metadataColor =
        widget.task.isCompleted
            ? AppColors.textTertiary
            : AppColors.textSecondary;
    final List<Widget> chips = [];

    if (widget.task.dueDate != null) {
      chips.add(
        _buildInfoChip(
          icon: CupertinoIcons.clock,
          text: DateFormat('HH:mm').format(widget.task.dueDate!),
          color: metadataColor,
        ),
      );
    }
    if (widget.task.tags.isNotEmpty) {
      chips.add(
        _buildInfoChip(
          icon: CupertinoIcons.tag_fill,
          text: '#${widget.task.tags.length}',
          color: widget.task.isCompleted ? metadataColor : taskColor,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(chips.length, (index) {
          return Padding(
            padding: EdgeInsets.only(right: index == chips.length - 1 ? 0 : 12),
            child: chips[index],
          );
        }),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildCompletionCheckbox(Color taskColor) {
    final isCompleted = widget.task.isCompleted;
    final checkboxColor =
        isCompleted
            ? AppColors.textTertiary
            : Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onToggleComplete(widget.task);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCompleted ? checkboxColor : Colors.transparent,
          border: Border.all(
            color: isCompleted ? checkboxColor : AppColors.divider,
            width: 2,
          ),
        ),
        child:
            isCompleted
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
                : null,
      ),
    );
  }

  bool _shouldShowMetadata() {
    return widget.task.dueDate != null || widget.task.tags.isNotEmpty;
  }
}
