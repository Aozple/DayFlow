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
    return IntrinsicHeight(
      child: Container(
        constraints: const BoxConstraints(minHeight: 90),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time label column
            GestureDetector(
              onTap: () => onQuickAddMenu(hour),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 70,
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color:
                          isCurrentHour
                              ? AppColors.accent.withAlpha(150)
                              : AppColors.timelineLineColor,
                      width: isCurrentHour ? 2 : 1,
                    ),
                  ),
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${hour.toString().padLeft(2, '0')}:00',
                      style: TextStyle(
                        fontSize: isCurrentHour ? 17 : 15,
                        fontWeight:
                            isCurrentHour ? FontWeight.w700 : FontWeight.w500,
                        color:
                            isCurrentHour
                                ? AppColors.accent
                                : AppColors.hourTextColor,
                        letterSpacing: 0.5,
                      ),
                    ),
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
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: 12,
                  ),
                  child:
                      tasks.isEmpty
                          ? const HomeEmptySlot()
                          : Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Display tasks or notes for this hour
                              for (int i = 0; i < tasks.length; i++) ...[
                                if (tasks[i].isNote)
                                  HomeNoteBlock(
                                    note: tasks[i],
                                    onOptions: onNoteOptions,
                                  )
                                else
                                  HomeTaskBlock(
                                    task: tasks[i],
                                    onToggleComplete: onTaskToggled,
                                    onOptions: onTaskOptions,
                                  ),
                                if (i < tasks.length - 1)
                                  const SizedBox(height: 10),
                              ],
                            ],
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
