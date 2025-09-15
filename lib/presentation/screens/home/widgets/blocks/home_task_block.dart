import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Compact task display for timeline view
class HomeTaskBlock extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Determine color scheme based on task color
    final isDefaultColor = task.color == '#2C2C2E' || task.color == '#8E8E93';
    final taskColor =
        isDefaultColor
            ? AppColors.textSecondary
            : AppColors.fromHex(task.color);

    // Safety check for note type
    if (task.isNote) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onLongPress: () => onOptions(task),
      onTap: () {
        context.push('/task-details', extra: task);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:
              task.isCompleted
                  ? AppColors.surface.withAlpha(150)
                  : isDefaultColor
                  ? AppColors.surfaceLight
                  : taskColor.withAlpha(40),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                task.isCompleted
                    ? AppColors.divider
                    : isDefaultColor
                    ? AppColors.divider
                    : taskColor.withAlpha(150),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Priority indicator bar
            Container(
              width: 4,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.getPriorityColor(task.priority),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Task content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Task title
                  Text(
                    task.title,
                    style: TextStyle(
                      color:
                          task.isCompleted
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration:
                          task.isCompleted ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Time and tags row
                  if (task.dueDate != null || task.tags.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Time display with notification indicator
                        if (task.dueDate != null) ...[
                          const Icon(
                            CupertinoIcons.clock,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('HH:mm').format(task.dueDate!),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),

                          // Show bell icon for tasks with notifications
                          if (task.hasNotification) ...[
                            const SizedBox(width: 4),
                            Icon(
                              CupertinoIcons.bell_fill,
                              size: 12,
                              color: AppColors.accent.withAlpha(180),
                            ),
                          ],
                        ],
                        // Show first tag with count indicator for additional tags
                        if (task.tags.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.divider.withAlpha(50),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  task.tags.first,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                                if (task.tags.length > 1) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withAlpha(50),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '+${task.tags.length - 1}',
                                      style: TextStyle(
                                        color: AppColors.accent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Completion checkbox
            const SizedBox(width: 12),
            CupertinoButton(
              padding: const EdgeInsets.all(4),
              minSize: 32,
              onPressed: () {
                onToggleComplete(task);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color:
                      task.isCompleted ? AppColors.accent : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        task.isCompleted ? AppColors.accent : AppColors.divider,
                    width: task.isCompleted ? 0 : 2,
                  ),
                ),
                child:
                    task.isCompleted
                        ? const Icon(
                          CupertinoIcons.checkmark,
                          size: 16,
                          color: Colors.white,
                        )
                        : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
