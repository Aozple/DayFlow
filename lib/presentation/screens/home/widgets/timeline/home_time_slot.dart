import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/material.dart';
import '../blocks/home_note_block.dart';
import '../blocks/home_task_block.dart';
import 'home_empty_slot.dart';

/// Hourly time slot in the timeline
class HomeTimeSlot extends StatelessWidget {
  final int hour;
  final List<TaskModel> tasks;
  final bool isCurrentHour;
  final Function(int) onQuickAddMenu;
  final Function(TaskModel) onTaskToggled;
  final Function(TaskModel) onTaskOptions;
  final Function(TaskModel) onNoteOptions;

  const HomeTimeSlot({
    super.key,
    required this.hour,
    required this.tasks,
    required this.isCurrentHour,
    required this.onQuickAddMenu,
    required this.onTaskToggled,
    required this.onTaskOptions,
    required this.onNoteOptions,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final shouldShowIndicator = isCurrentHour && now.hour == hour;
    final minuteProgress = shouldShowIndicator ? now.minute / 60.0 : 0.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main content
        IntrinsicHeight(
          child: Container(
            constraints: const BoxConstraints(minHeight: 90),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.divider.withAlpha(25),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time label column
                GestureDetector(
                  onTap: () => onQuickAddMenu(hour),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 75,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border(
                        right: BorderSide(
                          color:
                              isCurrentHour
                                  ? AppColors.accent
                                  : AppColors.divider.withAlpha(150),
                          width: isCurrentHour ? 3 : 1,
                        ),
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${hour.toString().padLeft(2, '0')}:00',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  isCurrentHour
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                              color:
                                  isCurrentHour
                                      ? AppColors.accent
                                      : AppColors.textSecondary,
                              letterSpacing: 0.3,
                              height: 1.2,
                            ),
                          ),
                          if (isCurrentHour) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withAlpha(150),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                // Tasks area
                Expanded(
                  child: GestureDetector(
                    onTap: tasks.isEmpty ? () => onQuickAddMenu(hour) : null,
                    behavior: HitTestBehavior.translucent,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      padding: EdgeInsets.all(tasks.isEmpty ? 8 : 12),
                      decoration: BoxDecoration(
                        color:
                            tasks.isNotEmpty
                                ? AppColors.surface.withAlpha(25)
                                : null,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            tasks.isNotEmpty
                                ? Border.all(
                                  color: AppColors.divider.withAlpha(30),
                                  width: 0.5,
                                )
                                : null,
                        boxShadow:
                            tasks.isNotEmpty
                                ? [
                                  BoxShadow(
                                    color: AppColors.background.withAlpha(60),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                    spreadRadius: -2,
                                  ),
                                ]
                                : null,
                      ),
                      child:
                          tasks.isEmpty
                              ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: HomeEmptySlot(),
                              )
                              : Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Display tasks or notes for this hour
                                  for (int i = 0; i < tasks.length; i++) ...[
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.divider.withAlpha(
                                            25,
                                          ),
                                          width: 0.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.background
                                                .withAlpha(50),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                            spreadRadius: -2,
                                          ),
                                          if (!tasks[i].isCompleted)
                                            BoxShadow(
                                              color: AppColors.accent.withAlpha(
                                                8,
                                              ),
                                              blurRadius: 20,
                                              offset: const Offset(0, 0),
                                              spreadRadius: -5,
                                            ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Stack(
                                          children: [
                                            // Task/Note content
                                            tasks[i].isNote
                                                ? HomeNoteBlock(
                                                  note: tasks[i],
                                                  onOptions: onNoteOptions,
                                                )
                                                : HomeTaskBlock(
                                                  task: tasks[i],
                                                  onToggleComplete:
                                                      onTaskToggled,
                                                  onOptions: onTaskOptions,
                                                ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (i < tasks.length - 1)
                                      const SizedBox(height: 12),
                                  ],
                                ],
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Current time indicator
        if (shouldShowIndicator)
          Positioned(
            top:
                12 +
                (minuteProgress * 66), // 12 padding + (0-66 based on minutes)
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: SizedBox(
                height: 20,
                child: Row(
                  children: [
                    const SizedBox(width: 68),
                    // Animated dot
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(200),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withAlpha(50),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Line
                    Expanded(
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.accent.withAlpha(150),
                              AppColors.accent.withAlpha(100),
                              AppColors.accent.withAlpha(25),
                              Colors.transparent,
                            ],
                            stops: const [0, 0.2, 0.6, 1],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
