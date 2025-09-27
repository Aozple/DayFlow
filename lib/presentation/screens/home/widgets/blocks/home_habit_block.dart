import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/habit_instance_model.dart';
import 'package:dayflow/data/models/habit_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Compact habit display widget optimized for timeline view.
///
/// Provides an efficient and visually appealing interface for displaying
/// and interacting with habits, including completion tracking, progress
/// visualization, and metadata display.
class HomeHabitBlock extends StatefulWidget {
  final HabitModel habit;
  final HabitInstanceModel? instance;
  final Function(HabitInstanceModel) onComplete;
  final Function(HabitInstanceModel) onUncomplete;
  final Function(HabitInstanceModel) onUpdateInstance;
  final Function(HabitModel) onOptions;
  final DateTime selectedDate;

  const HomeHabitBlock({
    super.key,
    required this.habit,
    this.instance,
    required this.onComplete,
    required this.onUncomplete,
    required this.onUpdateInstance,
    required this.onOptions,
    required this.selectedDate,
  });

  @override
  State<HomeHabitBlock> createState() => _HomeHabitBlockState();
}

class _HomeHabitBlockState extends State<HomeHabitBlock> {
  @override
  Widget build(BuildContext context) {
    final isDefaultColor = _isDefaultHabitColor(widget.habit.color);
    final habitColor =
        isDefaultColor
            ? AppColors.accent
            : AppColors.fromHex(widget.habit.color);

    final isCompleted = widget.instance?.isCompleted ?? false;
    final isForToday = _isForToday();
    final isToday = _isToday();
    final canInteract = isToday && isForToday && widget.instance != null;

    return GestureDetector(
      onTap: () => context.push('/habit-details', extra: widget.habit),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: _buildContainerDecoration(
          habitColor,
          isCompleted,
          isDefaultColor,
          canInteract,
        ),
        child: Row(
          children: [
            // Color indicator
            _buildColorIndicator(habitColor, isCompleted, canInteract),
            const SizedBox(width: 12),
            // Main content
            Expanded(
              child: _buildMainContent(habitColor, isCompleted, canInteract),
            ),
            const SizedBox(width: 8),
            // Options button as vertical dots
            _buildVerticalOptionsButton(habitColor, canInteract),
            const SizedBox(width: 8),
            // Completion control
            _buildCompletionControl(habitColor, isCompleted, canInteract),
          ],
        ),
      ),
    );
  }

  /// Build vertical options button with three dots
  Widget _buildVerticalOptionsButton(Color habitColor, bool canInteract) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onOptions(widget.habit);
      },
      child: Container(
        width: 20,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface.withAlpha(30),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDot(habitColor.withAlpha(canInteract ? 120 : 60)),
            const SizedBox(height: 4),
            _buildDot(habitColor.withAlpha(canInteract ? 120 : 60)),
            const SizedBox(height: 4),
            _buildDot(habitColor.withAlpha(canInteract ? 120 : 60)),
          ],
        ),
      ),
    );
  }

  /// Build single dot for options button
  Widget _buildDot(Color color) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  /// Check if habit uses default color scheme
  bool _isDefaultHabitColor(String color) {
    return color == '#2C2C2E' || color == '#8E8E93';
  }

  /// Check if habit is scheduled for today
  bool _isForToday() {
    final today = widget.selectedDate;

    switch (widget.habit.frequency) {
      case HabitFrequency.daily:
        return true;
      case HabitFrequency.weekly:
        return widget.habit.weekdays?.contains(today.weekday) ?? false;
      case HabitFrequency.monthly:
        return today.day == widget.habit.monthDay;
      case HabitFrequency.custom:
        if (widget.habit.customInterval == null) return false;
        final referenceDate =
            widget.habit.lastCompletedDate ?? widget.habit.createdAt;
        final daysDifference = today.difference(referenceDate).inDays;
        return daysDifference >= 0 &&
            daysDifference % widget.habit.customInterval! == 0;
    }
  }

  /// Check if selected date is today
  bool _isToday() {
    final today = DateTime.now();
    final selectedDay = widget.selectedDate;
    return today.year == selectedDay.year &&
        today.month == selectedDay.month &&
        today.day == selectedDay.day;
  }

  /// Build container decoration based on habit state
  BoxDecoration _buildContainerDecoration(
    Color habitColor,
    bool isCompleted,
    bool isDefaultColor,
    bool canInteract,
  ) {
    Color backgroundColor;
    Color borderColor;

    if (!canInteract) {
      backgroundColor = AppColors.surface.withAlpha(40);
      borderColor = AppColors.divider.withAlpha(30);
    } else if (isCompleted) {
      backgroundColor = habitColor.withAlpha(15);
      borderColor = habitColor.withAlpha(50);
    } else if (isDefaultColor) {
      backgroundColor = AppColors.surfaceLight;
      borderColor = AppColors.divider.withAlpha(50);
    } else {
      backgroundColor = habitColor.withAlpha(20);
      borderColor = habitColor.withAlpha(60);
    }

    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: borderColor, width: 1),
      boxShadow:
          isCompleted && canInteract
              ? [
                BoxShadow(
                  color: habitColor.withAlpha(20),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
              : null,
    );
  }

  /// Build color indicator on the left side
  Widget _buildColorIndicator(
    Color habitColor,
    bool isCompleted,
    bool canInteract,
  ) {
    return Container(
      width: 4,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors:
              !canInteract
                  ? [
                    AppColors.textTertiary.withAlpha(50),
                    AppColors.textTertiary.withAlpha(30),
                  ]
                  : isCompleted
                  ? [habitColor, habitColor.withAlpha(150)]
                  : [habitColor.withAlpha(150), habitColor.withAlpha(100)],
        ),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// Build main content area with title and metadata
  Widget _buildMainContent(
    Color habitColor,
    bool isCompleted,
    bool canInteract,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title row
        _buildTitleRow(habitColor, isCompleted, canInteract),
        // Metadata or progress bar
        if (_shouldShowProgressBar()) ...[
          const SizedBox(height: 8),
          _buildProgressBar(habitColor, isCompleted, canInteract),
        ] else if (_shouldShowMetadata()) ...[
          const SizedBox(height: 6),
          _buildCompactMetadata(habitColor, isCompleted, canInteract),
        ],
      ],
    );
  }

  /// Build title row with frequency icon and streak
  Widget _buildTitleRow(Color habitColor, bool isCompleted, bool canInteract) {
    final textColor = _getTextColor(isCompleted, canInteract);
    final iconColor = _getIconColor(habitColor, isCompleted, canInteract);

    return Row(
      children: [
        // Frequency icon
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(_getHabitFrequencyIcon(), size: 12, color: iconColor),
        ),
        const SizedBox(width: 8),
        // Title
        Expanded(
          child: Text(
            widget.habit.title,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: isCompleted ? FontWeight.w500 : FontWeight.w600,
              decoration: null,
              decorationColor: AppColors.textTertiary.withAlpha(80),
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Streak indicator
        if (widget.habit.currentStreak > 0) ...[
          const SizedBox(width: 8),
          _buildCompactStreakBadge(isCompleted, canInteract),
        ],
      ],
    );
  }

  /// Build compact streak badge
  Widget _buildCompactStreakBadge(bool isCompleted, bool canInteract) {
    final color =
        !canInteract
            ? AppColors.textTertiary.withAlpha(100)
            : isCompleted
            ? AppColors.warning.withAlpha(200)
            : AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(40), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.flame_fill, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            '${widget.habit.currentStreak}',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// Build compact metadata row
  Widget _buildCompactMetadata(
    Color habitColor,
    bool isCompleted,
    bool canInteract,
  ) {
    final color = _getSecondaryTextColor(isCompleted, canInteract);

    return Row(
      children: [
        // Time
        if (widget.habit.preferredTime != null) ...[
          Icon(CupertinoIcons.clock, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            _formatTimeOfDay(widget.habit.preferredTime!),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (widget.habit.hasNotification)
            Icon(
              CupertinoIcons.bell_solid,
              size: 8,
              color: habitColor.withAlpha(150),
            ),
          const SizedBox(width: 12),
        ],
        // Frequency
        Icon(CupertinoIcons.repeat, size: 10, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            widget.habit.frequencyLabel,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Tags count
        if (widget.habit.tags.isNotEmpty) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: habitColor.withAlpha(10),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '#${widget.habit.tags.length}',
              style: TextStyle(
                color: habitColor,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Build progress bar for quantifiable habits
  Widget _buildProgressBar(
    Color habitColor,
    bool isCompleted,
    bool canInteract,
  ) {
    final currentValue = widget.instance?.value ?? 0;
    final targetValue = widget.habit.targetValue ?? 1;
    final progress = (currentValue / targetValue).clamp(0.0, 1.0);

    final progressColor =
        !canInteract
            ? AppColors.textTertiary.withAlpha(60)
            : isCompleted
            ? habitColor.withAlpha(150)
            : habitColor;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$currentValue / $targetValue ${widget.habit.unit ?? ""}',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 10,
                color: progressColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.surface.withAlpha(100),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [progressColor, progressColor.withAlpha(200)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build completion control section
  Widget _buildCompletionControl(
    Color habitColor,
    bool isCompleted,
    bool canInteract,
  ) {
    if (widget.instance == null) {
      return _buildUnavailableIndicator();
    }

    if (widget.habit.habitType == HabitType.quantifiable) {
      return _buildCompactQuantifiableControls(
        habitColor,
        isCompleted,
        canInteract,
      );
    }

    return _buildCompactCheckbox(habitColor, isCompleted, canInteract);
  }

  /// Build compact checkbox for simple habits
  Widget _buildCompactCheckbox(
    Color habitColor,
    bool isCompleted,
    bool canInteract,
  ) {
    return GestureDetector(
      onTap:
          canInteract
              ? () {
                HapticFeedback.lightImpact();
                _handleCheckboxTap(isCompleted);
              }
              : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color:
              isCompleted
                  ? habitColor
                  : canInteract
                  ? Colors.transparent
                  : AppColors.surface.withAlpha(30),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                isCompleted || !canInteract
                    ? habitColor.withAlpha(canInteract ? 255 : 50)
                    : AppColors.divider,
            width: 2,
          ),
        ),
        child:
            isCompleted
                ? const Icon(Icons.done_rounded, size: 18, color: Colors.white)
                : null,
      ),
    );
  }

  /// Build compact quantifiable controls with vertical layout
  Widget _buildCompactQuantifiableControls(
    Color habitColor,
    bool isCompleted,
    bool canInteract,
  ) {
    final currentValue = widget.instance?.value ?? 0;
    final targetValue = widget.habit.targetValue ?? 1;

    if (!canInteract) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface.withAlpha(50),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider.withAlpha(30), width: 1),
        ),
        child: Text(
          '$currentValue/$targetValue',
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Value display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color:
                isCompleted
                    ? habitColor.withAlpha(20)
                    : AppColors.surface.withAlpha(100),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCompleted ? habitColor.withAlpha(60) : AppColors.divider,
              width: 1,
            ),
          ),
          child: Text(
            '$currentValue',
            style: TextStyle(
              color: isCompleted ? habitColor : AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Control buttons
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMiniButton(
              icon: CupertinoIcons.minus,
              onTap:
                  currentValue > 0 ? () => _updateQuantifiableValue(-1) : null,
              habitColor: habitColor,
            ),
            const SizedBox(width: 4),
            _buildMiniButton(
              icon: CupertinoIcons.plus,
              onTap:
                  currentValue < targetValue
                      ? () => _updateQuantifiableValue(1)
                      : null,
              habitColor: habitColor,
            ),
          ],
        ),
      ],
    );
  }

  /// Build mini adjustment button
  Widget _buildMiniButton({
    required IconData icon,
    required VoidCallback? onTap,
    required Color habitColor,
  }) {
    final isEnabled = onTap != null;

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.lightImpact();
          onTap();
        }
      },
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color:
              isEnabled
                  ? habitColor.withAlpha(20)
                  : AppColors.surface.withAlpha(50),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color:
                isEnabled
                    ? habitColor.withAlpha(80)
                    : AppColors.divider.withAlpha(50),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 12,
          color: isEnabled ? habitColor : AppColors.textTertiary,
        ),
      ),
    );
  }

  /// Build unavailable indicator
  Widget _buildUnavailableIndicator() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider.withAlpha(20), width: 2),
      ),
      child: Icon(
        CupertinoIcons.minus_circle,
        size: 16,
        color: AppColors.textTertiary.withAlpha(80),
      ),
    );
  }

  /// Handle checkbox tap
  void _handleCheckboxTap(bool isCompleted) {
    if (widget.instance == null) return;

    if (!isCompleted) {
      widget.onComplete(widget.instance!);
    } else {
      widget.onUncomplete(widget.instance!);
    }
  }

  /// Update quantifiable habit value
  void _updateQuantifiableValue(int change) {
    if (widget.instance == null) return;

    final currentValue = widget.instance!.value ?? 0;
    final targetValue = widget.habit.targetValue ?? 1;
    final newValue = (currentValue + change).clamp(0, targetValue);

    final updatedInstance = widget.instance!.copyWith(
      value: newValue,
      status:
          newValue >= targetValue
              ? HabitInstanceStatus.completed
              : HabitInstanceStatus.pending,
      completedAt: newValue >= targetValue ? DateTime.now() : null,
    );

    widget.onUpdateInstance(updatedInstance);
  }

  /// Helper methods for colors and states
  Color _getTextColor(bool isCompleted, bool canInteract) {
    if (!canInteract) {
      return AppColors.textSecondary.withAlpha(140);
    } else if (isCompleted) {
      return AppColors.textSecondary;
    } else {
      return AppColors.textPrimary;
    }
  }

  Color _getSecondaryTextColor(bool isCompleted, bool canInteract) {
    if (!canInteract) {
      return AppColors.textTertiary.withAlpha(120);
    } else if (isCompleted) {
      return AppColors.textTertiary;
    } else {
      return AppColors.textSecondary;
    }
  }

  Color _getIconColor(Color habitColor, bool isCompleted, bool canInteract) {
    if (!canInteract) {
      return AppColors.textTertiary.withAlpha(100);
    } else if (isCompleted) {
      return habitColor.withAlpha(150);
    } else {
      return habitColor;
    }
  }

  bool _shouldShowMetadata() {
    return widget.habit.preferredTime != null ||
        widget.habit.tags.isNotEmpty ||
        widget.habit.frequency != HabitFrequency.daily;
  }

  bool _shouldShowProgressBar() {
    return widget.habit.habitType == HabitType.quantifiable &&
        widget.habit.targetValue != null &&
        widget.instance != null;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  IconData _getHabitFrequencyIcon() {
    switch (widget.habit.frequency) {
      case HabitFrequency.daily:
        return CupertinoIcons.sun_max_fill;
      case HabitFrequency.weekly:
        return CupertinoIcons.calendar;
      case HabitFrequency.monthly:
        return CupertinoIcons.calendar_circle;
      case HabitFrequency.custom:
        return CupertinoIcons.repeat;
    }
  }
}
