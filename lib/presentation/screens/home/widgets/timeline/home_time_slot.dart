import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/material.dart';
import '../blocks/home_note_block.dart';
import '../blocks/home_task_block.dart';
import 'home_empty_slot.dart';

/// A single hourly time slot in the timeline.
///
/// This widget represents one hour in the timeline, displaying the hour label
/// and any tasks scheduled for that hour. It provides interaction for adding
/// new tasks or notes to empty time slots.
class HomeTimeSlot extends StatelessWidget {
  /// The hour this time slot represents (0-23).
  final int hour;

  /// List of tasks scheduled for this hour.
  final List<TaskModel> tasks;

  /// Whether this hour is the current hour (for highlighting).
  final bool isCurrentHour;

  /// Callback function to show the quick add menu.
  final Function(int) onQuickAddMenu;

  /// Callback function when a task is toggled.
  final Function(TaskModel) onTaskToggled;

  /// Callback function to show task options.
  final Function(TaskModel) onTaskOptions;

  /// Callback function to show note options.
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
        constraints: const BoxConstraints(
          minHeight: 90,
        ), // Minimum height for each slot.
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time label on the left side of the timeline.
            GestureDetector(
              onTap:
                  () => onQuickAddMenu(hour), // Tap to quickly add task/note.
              behavior:
                  HitTestBehavior.opaque, // Ensure the whole area is tappable.
              child: Container(
                width: 70,
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color:
                          isCurrentHour
                              ? AppColors.currentTimeIndicator.withAlpha(
                                100,
                              ) // Highlight if current hour.
                              : AppColors
                                  .timelineLineColor, // Regular timeline line.
                      width:
                          isCurrentHour
                              ? 2
                              : 1, // Thicker line for current hour.
                    ),
                  ),
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${hour.toString().padLeft(2, '0')}:00', // Format hour (e.g., "09:00").
                      style: TextStyle(
                        fontSize:
                            isCurrentHour
                                ? 17
                                : 15, // Larger font for current hour.
                        fontWeight:
                            isCurrentHour
                                ? FontWeight.w700
                                : FontWeight.w500, // Bolder for current hour.
                        color:
                            isCurrentHour
                                ? AppColors
                                    .accent // Accent color for current hour.
                                : AppColors
                                    .hourTextColor, // Regular color otherwise.
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Area where tasks for this hour are displayed.
            Expanded(
              child: GestureDetector(
                onTap:
                    tasks.isEmpty
                        ? () => onQuickAddMenu(hour)
                        : null, // Tap empty space to add.
                behavior:
                    HitTestBehavior
                        .translucent, // Allow taps to pass through transparent areas.
                child: Container(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: 12,
                  ),
                  child:
                      tasks.isEmpty
                          ? const HomeEmptySlot() // Show empty slot indicator if no tasks.
                          : Column(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .start, // Align tasks to the top.
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Iterate through tasks and build their compact blocks.
                              for (int i = 0; i < tasks.length; i++) ...[
                                if (tasks[i].isNote)
                                  HomeNoteBlock(
                                    note: tasks[i],
                                    onOptions: onNoteOptions,
                                  ) // Build note block if it's a note.
                                else
                                  HomeTaskBlock(
                                    task: tasks[i],
                                    onToggleComplete: onTaskToggled,
                                    onOptions: onTaskOptions,
                                  ), // Build task block otherwise.
                                if (i < tasks.length - 1)
                                  const SizedBox(
                                    height: 10,
                                  ), // Spacer between tasks.
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
