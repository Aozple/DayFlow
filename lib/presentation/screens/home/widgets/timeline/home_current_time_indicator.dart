import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/material.dart';
import 'dart:async';

/// The current time indicator line in the timeline.
///
/// This widget displays a horizontal line with a circle indicator that shows
/// the current time within the timeline. It updates every minute to accurately
/// reflect the current time. Only visible when viewing today's schedule.
class HomeCurrentTimeIndicator extends StatelessWidget {
  /// The currently selected date.
  final DateTime selectedDate;

  /// List of tasks being displayed in the timeline.
  final List<TaskModel> displayTasks;

  const HomeCurrentTimeIndicator({
    super.key,
    required this.selectedDate,
    required this.displayTasks,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(
        const Duration(minutes: 1),
      ), // Update every minute.
      builder: (context, snapshot) {
        final currentTime = DateTime.now();
        final currentMinute = currentTime.minute;
        final hourProgress =
            currentMinute / 60.0; // Progress within the current hour.
        double position = 16; // Initial offset.

        // Calculate vertical position based on previous hour slots and tasks.
        for (int i = 0; i < currentTime.hour; i++) {
          final hourTaskCount =
              displayTasks.where((t) => t.dueDate?.hour == i).length;
          position +=
              hourTaskCount == 0
                  ? 80
                  : 80 + (hourTaskCount * 58); // Adjust height based on tasks.
        }
        position += hourProgress * 80; // Add progress within current hour.

        return Positioned(
          top: position,
          left: 60, // Aligned with the timeline.
          right: 0,
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(50),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withAlpha(25),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  height: 1.5,
                  color: AppColors.accent.withAlpha(50),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
