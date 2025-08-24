import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/material.dart';
import 'home_current_time_indicator.dart';
import 'home_time_slot.dart';

/// The main timeline view, displaying tasks by hour.
///
/// This widget creates a scrollable timeline with 24 hourly slots where tasks
/// are displayed according to their due time. It also includes a visual indicator
/// for the current time when viewing today's schedule.
class HomeTimeline extends StatelessWidget {
  /// Controller for the timeline's scroll position.
  final ScrollController scrollController;

  /// The currently selected date.
  final DateTime selectedDate;

  /// List of tasks for the selected day.
  final List<TaskModel> tasks;

  /// List of filtered tasks (if filters are active).
  final List<TaskModel> filteredTasks;

  /// Whether any filters are currently active.
  final bool hasActiveFilters;

  /// Callback function to show the quick add menu.
  final Function(int) onQuickAddMenu;

  /// Callback function when a task is toggled.
  final Function(TaskModel) onTaskToggled;

  /// Callback function to show task options.
  final Function(TaskModel) onTaskOptions;

  /// Callback function to show note options.
  final Function(TaskModel) onNoteOptions;

  const HomeTimeline({
    super.key,
    required this.scrollController,
    required this.selectedDate,
    required this.tasks,
    required this.filteredTasks,
    required this.hasActiveFilters,
    required this.onQuickAddMenu,
    required this.onTaskToggled,
    required this.onTaskOptions,
    required this.onNoteOptions,
  });

  @override
  Widget build(BuildContext context) {
    // Use filtered tasks if filters are active, otherwise use all tasks for the day.
    final displayTasks = hasActiveFilters ? filteredTasks : tasks;
    final now = DateTime.now();
    final isToday = _isSameDay(
      selectedDate,
      now,
    ); // Check if the selected date is today.

    return Stack(
      children: [
        // The main scrollable list of hourly slots.
        ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.only(
            top: 16,
            bottom: 100,
          ), // Padding for content.
          itemCount: 24, // 24 hours in a day.
          itemBuilder: (context, index) {
            final hour = index;
            // Filter tasks that are due in the current hour.
            final hourTasks =
                displayTasks
                    .where((task) => task.dueDate?.hour == hour)
                    .toList()
                  ..sort((a, b) {
                    // First sort by minute
                    final minuteComparison = (a.dueDate?.minute ?? 0).compareTo(
                      b.dueDate?.minute ?? 0,
                    );

                    // If same minute, sort by priority (higher priority first)
                    if (minuteComparison == 0) {
                      return b.priority.compareTo(a.priority);
                    }

                    return minuteComparison;
                  });
            // Build each hourly time slot.
            return HomeTimeSlot(
              hour: hour,
              tasks: hourTasks,
              isCurrentHour: isToday && now.hour == hour,
              onQuickAddMenu: onQuickAddMenu,
              onTaskToggled: onTaskToggled,
              onTaskOptions: onTaskOptions,
              onNoteOptions: onNoteOptions,
            );
          },
        ),
        // Current time indicator line, only visible for today's date.
        if (isToday)
          HomeCurrentTimeIndicator(
            selectedDate: selectedDate,
            displayTasks: displayTasks,
          ),
      ],
    );
  }

  /// Helper method to check if two DateTime objects represent the same day (ignoring time).
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
