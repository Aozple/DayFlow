import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Compact task display for timeline view
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

class _HomeTaskBlockState extends State<HomeTaskBlock>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine color scheme based on task color
    final isDefaultColor =
        widget.task.color == '#2C2C2E' || widget.task.color == '#8E8E93';
    final taskColor =
        isDefaultColor
            ? AppColors.textSecondary
            : AppColors.fromHex(widget.task.color);

    // Safety check for note type
    if (widget.task.isNote) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onLongPress: () => widget.onOptions(widget.task),
      onTap: () {
        context.push('/task-details', extra: widget.task);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color:
              widget.task.isCompleted
                  ? AppColors.surface.withAlpha(75)
                  : isDefaultColor
                  ? AppColors.surfaceLight
                  : taskColor.withAlpha(50),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                widget.task.isCompleted
                    ? AppColors.divider.withAlpha(25)
                    : isDefaultColor
                    ? AppColors.divider.withAlpha(50)
                    : taskColor.withAlpha(75),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Action button (moved to left)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 36,
              onPressed: () => widget.onOptions(widget.task),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surface.withAlpha(100),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.line_horizontal_3,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Task content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Task title
                  Text(
                    widget.task.title,
                    style: TextStyle(
                      color:
                          widget.task.isCompleted
                              ? AppColors.textSecondary.withAlpha(120)
                              : AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight:
                          widget.task.isCompleted
                              ? FontWeight.w400
                              : FontWeight.w600,
                      decoration:
                          widget.task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                      decorationColor: AppColors.textTertiary.withAlpha(80),
                      decorationThickness: 1,
                      letterSpacing: -0.1,
                      height: 1.35,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Metadata row
                  if (widget.task.dueDate != null ||
                      widget.task.tags.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        // Simplified time display
                        if (widget.task.dueDate != null) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.time,
                                size: 11,
                                color:
                                    widget.task.isCompleted
                                        ? AppColors.textTertiary
                                        : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat(
                                  'HH:mm',
                                ).format(widget.task.dueDate!),
                                style: TextStyle(
                                  color:
                                      widget.task.isCompleted
                                          ? AppColors.textTertiary
                                          : AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (widget.task.hasNotification) ...[
                                const SizedBox(width: 5),
                                Icon(
                                  CupertinoIcons.bell_solid,
                                  size: 9,
                                  color: AppColors.accent.withAlpha(150),
                                ),
                              ],
                            ],
                          ),
                        ],
                        // Simplified tags
                        if (widget.task.tags.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.number,
                                size: 11,
                                color:
                                    widget.task.isCompleted
                                        ? AppColors.textTertiary
                                        : AppColors.accent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.task.tags.first,
                                style: TextStyle(
                                  color:
                                      widget.task.isCompleted
                                          ? AppColors.textTertiary
                                          : AppColors.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (widget.task.tags.length > 1) ...[
                                Text(
                                  ' +${widget.task.tags.length - 1}',
                                  style: const TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Priority bar (back to right side)
            Container(
              width: 3,
              height: 36,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color:
                    widget.task.isCompleted
                        ? AppColors.textTertiary.withAlpha(50)
                        : AppColors.getPriorityColor(
                          widget.task.priority,
                        ).withAlpha(150),
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            // Modern checkbox design (back to right side)
            GestureDetector(
              onTapDown: (_) {
                setState(() => _isPressed = true);
                _scaleController.forward();
              },
              onTapUp: (_) {
                setState(() => _isPressed = false);
                _scaleController.reverse();
                widget.onToggleComplete(widget.task);
              },
              onTapCancel: () {
                setState(() => _isPressed = false);
                _scaleController.reverse();
              },
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color:
                            widget.task.isCompleted
                                ? AppColors.accent
                                : _isPressed
                                ? AppColors.accent.withAlpha(30)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            widget.task.isCompleted
                                ? null
                                : Border.all(
                                  color:
                                      _isPressed
                                          ? AppColors.accent
                                          : AppColors.divider,
                                  width: 2,
                                ),
                        boxShadow:
                            widget.task.isCompleted
                                ? [
                                  BoxShadow(
                                    color: AppColors.accent.withAlpha(50),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                                : null,
                      ),
                      child:
                          widget.task.isCompleted
                              ? const Icon(
                                Icons.done_rounded,
                                size: 18,
                                color: Colors.white,
                                weight: 700,
                              )
                              : _isPressed
                              ? Center(
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              )
                              : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
