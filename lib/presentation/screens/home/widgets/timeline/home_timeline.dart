import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/material.dart';
import 'home_current_time_indicator.dart';
import 'home_time_slot.dart';

/// Main timeline view showing tasks organized by hour
class HomeTimeline extends StatelessWidget {
  final ScrollController scrollController;
  final DateTime selectedDate;
  final List<TaskModel> tasks;
  final List<TaskModel> filteredTasks;
  final bool hasActiveFilters;
  final Function(int) onQuickAddMenu;
  final Function(TaskModel) onTaskToggled;
  final Function(TaskModel) onTaskOptions;
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
    // Use filtered tasks if filters are active
    final displayTasks = hasActiveFilters ? filteredTasks : tasks;
    final now = DateTime.now();
    final isToday = _isSameDay(selectedDate, now);

    return Stack(
      children: [
        // Scrollable hourly timeline
        ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.only(top: 16, bottom: 100),
          itemCount: 24,
          itemBuilder: (context, index) {
            final hour = index;
            // Get tasks for this hour and sort them
            final hourTasks =
                displayTasks
                    .where((task) => task.dueDate?.hour == hour)
                    .toList()
                  ..sort((a, b) {
                    // Sort by minute first
                    final minuteComparison = (a.dueDate?.minute ?? 0).compareTo(
                      b.dueDate?.minute ?? 0,
                    );

                    // If same minute, sort by priority
                    if (minuteComparison == 0) {
                      return b.priority.compareTo(a.priority);
                    }

                    return minuteComparison;
                  });

            // Build time slot with tasks
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

        // Current time indicator (only for today)
        if (isToday)
          HomeCurrentTimeIndicator(
            selectedDate: selectedDate,
            displayTasks: displayTasks,
          ),
      ],
    );
  }

  /// Check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
