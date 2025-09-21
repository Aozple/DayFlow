import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/habit_instance_model.dart';
import 'package:dayflow/data/models/habit_model.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/material.dart';
import '../blocks/home_habit_block.dart';
import '../blocks/home_note_block.dart';
import '../blocks/home_task_block.dart';
import 'home_empty_slot.dart';

/// Single hour slot in the timeline containing tasks, notes, and habits
class HomeTimeSlot extends StatelessWidget {
  final int hour;
  final List<TaskModel> tasks;
  final List<HabitWithInstance> habits;
  final bool isCurrentHour;
  final DateTime selectedDate;
  final Function(int) onQuickAddMenu;
  final Function(TaskModel) onTaskToggled;
  final Function(TaskModel) onTaskOptions;
  final Function(TaskModel) onNoteOptions;
  final Function(HabitInstanceModel) onHabitComplete;
  final Function(HabitInstanceModel) onHabitUncomplete;
  final Function(HabitInstanceModel) onHabitUpdateInstance;
  final Function(HabitModel) onHabitOptions;

  const HomeTimeSlot({
    super.key,
    required this.hour,
    required this.tasks,
    this.habits = const [],
    required this.isCurrentHour,
    required this.selectedDate,
    required this.onQuickAddMenu,
    required this.onTaskToggled,
    required this.onTaskOptions,
    required this.onNoteOptions,
    required this.onHabitComplete,
    required this.onHabitUncomplete,
    required this.onHabitUpdateInstance,
    required this.onHabitOptions,
  });

  // Constants
  static const double _minSlotHeight = 90.0;
  static const double _timeLabelWidth = 75.0;
  static const double _contentPadding = 12.0;
  static const double _emptyContentPadding = 8.0;
  static const double _itemSpacing = 12.0;
  static const double _borderRadius = 8.0;

  @override
  Widget build(BuildContext context) {
    final hasContent = tasks.isNotEmpty || habits.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IntrinsicHeight(
          child: Container(
            constraints: const BoxConstraints(minHeight: _minSlotHeight),
            decoration: _getSlotDecoration(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_buildTimeLabel(), _buildContentArea(hasContent)],
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _getSlotDecoration() {
    return BoxDecoration(
      color: AppColors.background,
      border: Border(
        bottom: BorderSide(color: AppColors.divider.withAlpha(25), width: 0.5),
      ),
    );
  }

  Widget _buildTimeLabel() {
    return GestureDetector(
      onTap: () => onQuickAddMenu(hour),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: _timeLabelWidth,
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
              _buildTimeText(),
              if (isCurrentHour) ...[
                const SizedBox(height: 8),
                _buildCurrentHourIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeText() {
    return Text(
      '${hour.toString().padLeft(2, '0')}:00',
      style: TextStyle(
        fontSize: 14,
        fontWeight: isCurrentHour ? FontWeight.w800 : FontWeight.w500,
        color: isCurrentHour ? AppColors.accent : AppColors.textSecondary,
        letterSpacing: 0.3,
        height: 1.2,
      ),
    );
  }

  Widget _buildCurrentHourIndicator() {
    return Container(
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
    );
  }

  Widget _buildContentArea(bool hasContent) {
    return Expanded(
      child: GestureDetector(
        onTap: !hasContent ? () => onQuickAddMenu(hour) : null,
        behavior: HitTestBehavior.translucent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: EdgeInsets.all(
            hasContent ? _contentPadding : _emptyContentPadding,
          ),
          decoration: _getContentDecoration(hasContent),
          child:
              hasContent
                  ? _buildContentItems()
                  : const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: HomeEmptySlot(),
                  ),
        ),
      ),
    );
  }

  BoxDecoration? _getContentDecoration(bool hasContent) {
    if (!hasContent) return null;

    return BoxDecoration(
      color: AppColors.surface.withAlpha(25),
      borderRadius: BorderRadius.circular(_borderRadius),
      border: Border.all(color: AppColors.divider.withAlpha(30), width: 0.5),
      boxShadow: [
        BoxShadow(
          color: AppColors.background.withAlpha(60),
          blurRadius: 10,
          offset: const Offset(0, 4),
          spreadRadius: -2,
        ),
      ],
    );
  }

  Widget _buildContentItems() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Render habits
        ..._buildHabitsList(),

        // Add spacing between habits and tasks if needed
        if (habits.isNotEmpty && tasks.isNotEmpty)
          const SizedBox(height: _itemSpacing),

        // Render tasks and notes
        ..._buildTasksList(),
      ],
    );
  }

  List<Widget> _buildHabitsList() {
    final widgets = <Widget>[];

    for (int i = 0; i < habits.length; i++) {
      widgets.add(
        _buildItemContainer(
          child: HomeHabitBlock(
            habit: habits[i].habit,
            instance: habits[i].instance,
            selectedDate: selectedDate,
            onComplete: onHabitComplete,
            onUncomplete: onHabitUncomplete,
            onUpdateInstance: onHabitUpdateInstance,
            onOptions: onHabitOptions,
          ),
        ),
      );

      if (i < habits.length - 1) {
        widgets.add(const SizedBox(height: _itemSpacing));
      }
    }

    return widgets;
  }

  List<Widget> _buildTasksList() {
    final widgets = <Widget>[];

    for (int i = 0; i < tasks.length; i++) {
      widgets.add(
        _buildItemContainer(
          child: _buildTaskOrNote(tasks[i]),
          isTask: !tasks[i].isNote,
          isCompleted: tasks[i].isCompleted,
        ),
      );

      if (i < tasks.length - 1) {
        widgets.add(const SizedBox(height: _itemSpacing));
      }
    }

    return widgets;
  }

  Widget _buildTaskOrNote(TaskModel task) {
    return task.isNote
        ? HomeNoteBlock(note: task, onOptions: onNoteOptions)
        : HomeTaskBlock(
          task: task,
          onToggleComplete: onTaskToggled,
          onOptions: onTaskOptions,
        );
  }

  Widget _buildItemContainer({
    required Widget child,
    bool isTask = false,
    bool isCompleted = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(color: AppColors.divider.withAlpha(25), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.background.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
          if (isTask && !isCompleted)
            BoxShadow(
              color: AppColors.accent.withAlpha(8),
              blurRadius: 20,
              offset: Offset.zero,
              spreadRadius: -5,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_borderRadius),
        child: child,
      ),
    );
  }
}

/// Data model combining a habit with its instance for a specific date
class HabitWithInstance {
  final HabitModel habit;
  final HabitInstanceModel? instance;

  const HabitWithInstance({required this.habit, this.instance});
}
