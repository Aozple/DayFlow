import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/habit_model.dart';
import 'package:flutter/cupertino.dart';

class HomeHabitOptionsSheet extends StatelessWidget {
  final HabitModel habit;
  final VoidCallback onEdit;
  final VoidCallback onViewStats;
  final VoidCallback onPause;
  final VoidCallback onDelete;

  const HomeHabitOptionsSheet({
    super.key,
    required this.habit,
    required this.onEdit,
    required this.onViewStats,
    required this.onPause,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheet(
      title: Text(
        habit.title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      message: Column(
        children: [
          Text(habit.frequencyLabel, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          if (habit.currentStreak > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.flame_fill,
                  size: 14,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 4),
                Text(
                  '${habit.currentStreak} day streak',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
      actions: [
        CupertinoActionSheetAction(
          onPressed: onEdit,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.pencil,
                size: 20,
                color: AppColors.textPrimary,
              ),
              SizedBox(width: 8),
              Text('Edit Habit'),
            ],
          ),
        ),

        CupertinoActionSheetAction(
          onPressed: onViewStats,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.chart_bar_fill,
                size: 20,
                color: AppColors.info,
              ),
              SizedBox(width: 8),
              Text('View Statistics'),
            ],
          ),
        ),

        CupertinoActionSheetAction(
          onPressed: onPause,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                habit.isActive
                    ? CupertinoIcons.pause_fill
                    : CupertinoIcons.play_fill,
                size: 20,
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              Text(habit.isActive ? 'Pause Habit' : 'Resume Habit'),
            ],
          ),
        ),

        CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: onDelete,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.trash_fill, size: 20),
              SizedBox(width: 8),
              Text('Delete Habit'),
            ],
          ),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
    );
  }
}
