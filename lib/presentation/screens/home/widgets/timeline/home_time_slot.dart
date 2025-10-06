import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/habit_instance_model.dart';
import 'package:dayflow/data/models/habit_model.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/material.dart';
import '../blocks/home_habit_block.dart';
import '../blocks/home_note_block.dart';
import '../blocks/home_task_block.dart';
import 'home_empty_slot.dart';

class HomeTimeSlot extends StatefulWidget {
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
  final Function(TaskModel, int) onTaskDropped;
  final Function(HabitModel, int) onHabitDropped;

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
    required this.onTaskDropped,
    required this.onHabitDropped,
  });

  @override
  State<HomeTimeSlot> createState() => _HomeTimeSlotState();
}

class _HomeTimeSlotState extends State<HomeTimeSlot>
    with SingleTickerProviderStateMixin {
  bool _isDragOver = false;
  bool _canAcceptDrop = false;
  late AnimationController _highlightController;
  late Animation<double> _highlightAnimation;

  static const double _minSlotHeight = 90.0;
  static const double _timeLabelWidth = 75.0;
  static const double _contentPadding = 12.0;
  static const double _emptyContentPadding = 8.0;
  static const double _itemSpacing = 12.0;
  static const double _borderRadius = 8.0;

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _highlightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _highlightController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasContent = widget.tasks.isNotEmpty || widget.habits.isNotEmpty;

    return DragTarget<DraggableItem>(
      onWillAcceptWithDetails: (details) => _onWillAcceptItem(details.data),
      onAcceptWithDetails: (details) => _onAcceptItem(details.data),
      onLeave: (item) => _onLeaveItem(),
      builder: (context, candidateData, rejectedData) {
        return AnimatedBuilder(
          animation: _highlightAnimation,
          builder: (context, child) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IntrinsicHeight(
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: _minSlotHeight,
                    ),
                    decoration: _getSlotDecoration(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTimeLabel(),
                        _buildContentArea(hasContent),
                      ],
                    ),
                  ),
                ),
                if (_isDragOver && _canAcceptDrop) _buildDropHighlight(),
              ],
            );
          },
        );
      },
    );
  }

  bool _onWillAcceptItem(DraggableItem? item) {
    if (item == null) return false;

    final currentHour = item.currentHour;
    final canAccept = currentHour != widget.hour;

    setState(() {
      _isDragOver = true;
      _canAcceptDrop = canAccept;
    });

    if (canAccept) {
      _highlightController.forward();
    }

    return canAccept;
  }

  void _onAcceptItem(DraggableItem item) {
    setState(() {
      _isDragOver = false;
      _canAcceptDrop = false;
    });

    _highlightController.reverse();

    if (item.type == DraggableItemType.task && item.task != null) {
      widget.onTaskDropped(item.task!, widget.hour);
    } else if (item.type == DraggableItemType.habit && item.habit != null) {
      widget.onHabitDropped(item.habit!, widget.hour);
    }
  }

  void _onLeaveItem() {
    setState(() {
      _isDragOver = false;
      _canAcceptDrop = false;
    });
    _highlightController.reverse();
  }

  Widget _buildDropHighlight() {
    return Positioned.fill(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withAlpha(
            (25.5 * _highlightAnimation.value).round(),
          ),
          borderRadius: BorderRadius.circular(_borderRadius),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withAlpha(
              (153 * _highlightAnimation.value).round(),
            ),
            width: 2,
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(
                (230 * _highlightAnimation.value).round(),
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Drop here',
              style: TextStyle(
                color: Colors.white.withAlpha(
                  (255 * _highlightAnimation.value).round(),
                ),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
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
      onTap: () => widget.onQuickAddMenu(widget.hour),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: _timeLabelWidth,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            right: BorderSide(
              color:
                  widget.isCurrentHour
                      ? Theme.of(context).colorScheme.primary
                      : AppColors.divider.withAlpha(100),
              width: widget.isCurrentHour ? 4 : 1,
            ),
          ),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTimeText(),
              if (widget.isCurrentHour) ...[
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
      '${widget.hour.toString().padLeft(2, '0')}:00',
      style: TextStyle(
        fontSize: 14,
        fontWeight: widget.isCurrentHour ? FontWeight.w800 : FontWeight.w500,
        color:
            widget.isCurrentHour ? Theme.of(context).colorScheme.primary : AppColors.textSecondary,
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
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withAlpha(150),
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
        onTap: !hasContent ? () => widget.onQuickAddMenu(widget.hour) : null,
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
      borderRadius: BorderRadius.circular(_borderRadius),
    );
  }

  Widget _buildContentItems() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ..._buildHabitsList(),
        if (widget.habits.isNotEmpty && widget.tasks.isNotEmpty)
          const SizedBox(height: _itemSpacing),
        ..._buildTasksList(),
      ],
    );
  }

  List<Widget> _buildHabitsList() {
    final widgets = <Widget>[];

    for (int i = 0; i < widget.habits.length; i++) {
      widgets.add(
        _buildItemContainer(
          child: LongPressDraggable<DraggableItem>(
            data: DraggableItem(
              type: DraggableItemType.habit,
              habit: widget.habits[i].habit,
              currentHour: widget.hour,
            ),
            delay: const Duration(milliseconds: 500),
            feedback: _buildDragFeedback(
              child: HomeHabitBlock(
                habit: widget.habits[i].habit,
                instance: widget.habits[i].instance,
                selectedDate: widget.selectedDate,
                onComplete: widget.onHabitComplete,
                onUncomplete: widget.onHabitUncomplete,
                onUpdateInstance: widget.onHabitUpdateInstance,
                onOptions: widget.onHabitOptions,
              ),
            ),
            childWhenDragging: _buildDragPlaceholder(),
            child: HomeHabitBlock(
              habit: widget.habits[i].habit,
              instance: widget.habits[i].instance,
              selectedDate: widget.selectedDate,
              onComplete: widget.onHabitComplete,
              onUncomplete: widget.onHabitUncomplete,
              onUpdateInstance: widget.onHabitUpdateInstance,
              onOptions: widget.onHabitOptions,
            ),
          ),
        ),
      );

      if (i < widget.habits.length - 1) {
        widgets.add(const SizedBox(height: _itemSpacing));
      }
    }

    return widgets;
  }

  List<Widget> _buildTasksList() {
    final widgets = <Widget>[];

    for (int i = 0; i < widget.tasks.length; i++) {
      widgets.add(
        _buildItemContainer(
          child: _buildTaskOrNote(widget.tasks[i]),
          isTask: !widget.tasks[i].isNote,
          isCompleted: widget.tasks[i].isCompleted,
        ),
      );

      if (i < widget.tasks.length - 1) {
        widgets.add(const SizedBox(height: _itemSpacing));
      }
    }

    return widgets;
  }

  Widget _buildTaskOrNote(TaskModel task) {
    return task.isNote
        ? LongPressDraggable<DraggableItem>(
          data: DraggableItem(
            type: DraggableItemType.note,
            task: task,
            currentHour: widget.hour,
          ),
          delay: const Duration(milliseconds: 500),
          feedback: _buildDragFeedback(
            child: HomeNoteBlock(note: task, onOptions: widget.onNoteOptions),
          ),
          childWhenDragging: _buildDragPlaceholder(),
          child: HomeNoteBlock(note: task, onOptions: widget.onNoteOptions),
        )
        : LongPressDraggable<DraggableItem>(
          data: DraggableItem(
            type: DraggableItemType.task,
            task: task,
            currentHour: widget.hour,
          ),
          delay: const Duration(milliseconds: 500),
          feedback: _buildDragFeedback(
            child: HomeTaskBlock(
              task: task,
              onToggleComplete: widget.onTaskToggled,
              onOptions: widget.onTaskOptions,
            ),
          ),
          childWhenDragging: _buildDragPlaceholder(),
          child: HomeTaskBlock(
            task: task,
            onToggleComplete: widget.onTaskToggled,
            onOptions: widget.onTaskOptions,
          ),
        );
  }

  Widget _buildDragFeedback({required Widget child}) {
    return Material(
      color: Colors.transparent,
      child: Transform.scale(
        scale: 1.05,
        child: Container(
          width: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_borderRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.background.withAlpha(100),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withAlpha(50),
                blurRadius: 30,
                offset: const Offset(0, 12),
                spreadRadius: -5,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildDragPlaceholder() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(50),
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(
          color: AppColors.divider.withAlpha(100),
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.drag_indicator,
          color: AppColors.textTertiary.withAlpha(100),
          size: 24,
        ),
      ),
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
              color: Theme.of(context).colorScheme.primary.withAlpha(8),
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

class DraggableItem {
  final DraggableItemType type;
  final TaskModel? task;
  final HabitModel? habit;
  final int currentHour;

  const DraggableItem({
    required this.type,
    this.task,
    this.habit,
    required this.currentHour,
  });
}

enum DraggableItemType { task, habit, note }

class HabitWithInstance {
  final HabitModel habit;
  final HabitInstanceModel? instance;

  const HabitWithInstance({required this.habit, this.instance});
}
