import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// A compact display block for a task in the timeline.
/// 
/// This widget displays a task in a compact format suitable for the timeline view,
/// showing the task title, time, tags, and completion status. It provides
/// interactions for viewing details, toggling completion, and accessing options.
class HomeTaskBlock extends StatelessWidget {
  /// The task to display.
  final TaskModel task;
  
  /// Callback function when the task completion is toggled.
  final Function(TaskModel) onToggleComplete;
  
  /// Callback function to show task options.
  final Function(TaskModel) onOptions;

  const HomeTaskBlock({
    super.key,
    required this.task,
    required this.onToggleComplete,
    required this.onOptions,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if the task uses a default color or a custom one.
    final isDefaultColor = task.color == '#2C2C2E' || task.color == '#8E8E93';
    final taskColor =
        isDefaultColor
            ? AppColors
                .textSecondary // Use secondary text color for default.
            : AppColors.fromHex(task.color); // Convert hex to Color object.
    
    // If the task is actually a note, delegate to the note block builder.
    if (task.isNote) {
      // This shouldn't happen as the caller should check, but just in case
      return const SizedBox.shrink();
    }
    
    return GestureDetector(
      onLongPress:
          () => onOptions(task), // Show options menu on long press.
      onTap: () {
        context.push(
          '/task-details',
          extra: task,
        ); // Navigate to task details on tap.
      },
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 200,
        ), // Smooth animation for state changes.
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:
              task.isCompleted
                  ? AppColors.surface.withAlpha(
                    150,
                  ) // Faded background if completed.
                  : isDefaultColor
                  ? AppColors
                      .surfaceLight // Light surface for default color.
                  : taskColor.withAlpha(40), // Semi-transparent custom color.
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                task.isCompleted
                    ? AppColors
                        .divider // Divider color if completed.
                    : isDefaultColor
                    ? AppColors
                        .divider // Divider color for default.
                    : taskColor.withAlpha(
                      150,
                    ), // More opaque custom color for border.
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Vertical bar indicating task priority.
            Container(
              width: 4,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.getPriorityColor(
                  task.priority,
                ), // Color based on priority.
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Task title and metadata.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Task title.
                  Text(
                    task.title,
                    style: TextStyle(
                      color:
                          task.isCompleted
                              ? AppColors
                                  .textSecondary // Faded text if completed.
                              : AppColors
                                  .textPrimary, // Primary text otherwise.
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration:
                          task.isCompleted
                              ? TextDecoration.lineThrough
                              : null, // Strikethrough if completed.
                      decorationColor: AppColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis, // Truncate long titles.
                  ),
                  // Row for time and tags, only shown if they exist.
                  if (task.dueDate != null || task.tags.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Display task time if due date is set.
                        if (task.dueDate != null) ...[
                          const Icon(
                            CupertinoIcons.clock,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('HH:mm').format(
                              task.dueDate!,
                            ), // Format time (e.g., "14:30").
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        // Display the first tag if tags exist.
                        if (task.tags.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.divider.withAlpha(
                                50,
                              ), // Subtle background for tag.
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              task.tags.first, // Display only the first tag.
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Checkbox for marking task as complete/incomplete.
            const SizedBox(width: 12),
            CupertinoButton(
              padding: const EdgeInsets.all(
                4,
              ), // Padding for better touch area.
              minSize: 32, // Larger touch area.
              onPressed: () {
                onToggleComplete(task); // Dispatch event to toggle completion.
              },
              child: AnimatedContainer(
                duration: const Duration(
                  milliseconds: 200,
                ), // Smooth animation.
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color:
                      task.isCompleted
                          ? AppColors.accent
                          : Colors.transparent, // Accent color if completed.
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        task.isCompleted
                            ? AppColors.accent
                            : AppColors.divider, // Accent border if completed.
                    width:
                        task.isCompleted
                            ? 0
                            : 2, // Thicker border if not completed.
                  ),
                ),
                child:
                    task.isCompleted
                        ? const Icon(
                          CupertinoIcons
                              .checkmark, // Checkmark icon if completed.
                          size: 16,
                          color: Colors.white,
                        )
                        : null, // No child if not completed.
              ),
            ),
          ],
        ),
      ),
    );
  }
}