import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

/// Custom app bar that expands and collapses for the task details screen.
///
/// This widget provides a visually appealing header with the task title and
/// completion status, along with navigation and options buttons.
class TaskDetailsAppBar extends StatelessWidget {
  /// The task to display in the app bar.
  final TaskModel task;

  /// Callback function when the back button is pressed.
  final VoidCallback onBackPressed;

  /// Callback function when the more options button is pressed.
  final VoidCallback onMoreOptions;

  const TaskDetailsAppBar({
    super.key,
    required this.task,
    required this.onBackPressed,
    required this.onMoreOptions,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120, // Height when fully expanded.
      floating: false, // Does not float above content.
      pinned: true, // Stays visible at the top when scrolling up.
      backgroundColor: Colors.transparent, // Transparent background.
      elevation: 0, // No shadow.
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 20,
            sigmaY: 20,
          ), // Apply a blur effect.
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.surface.withAlpha(
                    220,
                  ), // Semi-transparent surface for gradient.
                  AppColors.surface.withAlpha(180),
                ],
              ),
            ),
            child: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 14),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Task title.
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis, // Truncate long titles.
                  ),
                  const SizedBox(height: 2),
                  // Task completion status.
                  Text(
                    task.isCompleted ? 'Completed' : 'In Progress',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color:
                          task.isCompleted
                              ? AppColors
                                  .success // Green for completed.
                              : AppColors
                                  .accent, // Accent color for in progress.
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.only(left: 8),
        child: CircleAvatar(
          backgroundColor: AppColors.surfaceLight,
          child: IconButton(
            icon: const Icon(
              CupertinoIcons.chevron_back, // Back arrow icon.
              color: AppColors.textPrimary,
              size: 22,
            ),
            onPressed: onBackPressed, // Pop the current screen.
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: CircleAvatar(
            backgroundColor: AppColors.surfaceLight,
            child: IconButton(
              icon: Icon(
                CupertinoIcons.ellipsis, // Ellipsis (more options) icon.
                color: AppColors.accent,
                size: 22,
              ),
              onPressed: onMoreOptions, // Show more options action sheet.
            ),
          ),
        ),
      ],
    );
  }
}
