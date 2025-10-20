import 'dart:ui';
import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/core/utils/app_color_utils.dart';
import 'package:dayflow/data/models/habit_instance_model.dart';
import 'package:dayflow/data/models/habit_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

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
            ? Theme.of(context).colorScheme.primary
            : AppColorUtils.fromHex(widget.habit.color);

    final isCompleted = widget.instance?.isCompleted ?? false;
    final isForToday = _isForToday();
    final isToday = _isToday();
    final canInteract = isToday && isForToday && widget.instance != null;

    final currentValue = widget.instance?.value ?? 0;
    final targetValue = widget.habit.targetValue ?? 1;
    final progress =
        _shouldShowProgressBar()
            ? (currentValue / targetValue).clamp(0.0, 1.0)
            : 0.0;

    return Dismissible(
      key: ValueKey(widget.habit.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        decoration: BoxDecoration(
          color: habitColor.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        child: Icon(CupertinoIcons.ellipsis, color: habitColor),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          HapticFeedback.lightImpact();
          widget.onOptions(widget.habit);
        }
        return false;
      },
      child: GestureDetector(
        onTap: () => context.push('/habit-details', extra: widget.habit),
        child: _buildCardWithProgressBorder(
          context: context,
          habitColor: habitColor,
          isCompleted: isCompleted,
          isDefaultColor: isDefaultColor,
          canInteract: canInteract,
          progress: progress,
          child: Row(
            children: [
              Expanded(
                child: _buildMainContent(habitColor, isCompleted, canInteract),
              ),
              const SizedBox(width: 8),
              _buildCompletionControl(habitColor, isCompleted, canInteract),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardWithProgressBorder({
    required BuildContext context,
    required Color habitColor,
    required bool isCompleted,
    required bool isDefaultColor,
    required bool canInteract,
    required double progress,
    required Widget child,
  }) {
    Color backgroundColor;
    Color progressBgColor;

    if (!canInteract) {
      backgroundColor = AppColors.surface.withAlpha(40);
      progressBgColor = AppColors.divider.withAlpha(30);
    } else if (isCompleted) {
      backgroundColor = habitColor.withAlpha(15);
      progressBgColor = habitColor.withAlpha(50);
    } else if (isDefaultColor) {
      backgroundColor = AppColors.surfaceLight;
      progressBgColor = AppColors.divider.withAlpha(50);
    } else {
      backgroundColor = habitColor.withAlpha(20);
      progressBgColor = habitColor.withAlpha(60);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: progress),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, animatedProgress, _) {
        return CustomPaint(
          painter: _ProgressBorderPainter(
            progress: animatedProgress,
            color: habitColor,
            backgroundColor: progressBgColor,
            strokeWidth: 2.0,
            radius: 12,
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
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
            ),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildMainContent(
    Color habitColor,
    bool isCompleted,
    bool canInteract,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTitleRow(habitColor, isCompleted, canInteract),
        if (_shouldShowMetadata()) ...[
          const SizedBox(height: 8),
          _buildMetadataRow(habitColor, isCompleted, canInteract),
        ],
      ],
    );
  }

  Widget _buildTitleRow(Color habitColor, bool isCompleted, bool canInteract) {
    final textColor = _getTextColor(isCompleted, canInteract);
    final iconColor = _getIconColor(habitColor, isCompleted, canInteract);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(_getHabitFrequencyIcon(), size: 12, color: iconColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.habit.title,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: isCompleted ? FontWeight.w500 : FontWeight.w600,
              decoration:
                  isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.habit.currentStreak > 0) ...[
          const SizedBox(width: 8),
          _buildCompactStreakBadge(isCompleted, canInteract),
        ],
      ],
    );
  }

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

  Widget _buildMetadataRow(
    Color habitColor,
    bool isCompleted,
    bool canInteract,
  ) {
    final color = _getSecondaryTextColor(isCompleted, canInteract);
    final List<Widget> chips = [];

    if (widget.habit.preferredTime != null) {
      chips.add(
        _buildInfoChip(
          icon: CupertinoIcons.clock,
          text: _formatTimeOfDay(widget.habit.preferredTime!),
          color: color,
        ),
      );
    }
    chips.add(
      _buildInfoChip(
        icon: CupertinoIcons.repeat,
        text: widget.habit.frequencyLabel,
        color: color,
      ),
    );
    if (widget.habit.tags.isNotEmpty) {
      chips.add(
        _buildInfoChip(
          icon: CupertinoIcons.tag_fill,
          text: '#${widget.habit.tags.length}',
          color: color,
        ),
      );
    }
    if (_shouldShowProgressBar()) {
      chips.add(
        _buildInfoChip(
          icon: CupertinoIcons.flag_fill,
          text: '/ ${widget.habit.targetValue}',
          color: color,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(chips.length, (index) {
          return Padding(
            padding: EdgeInsets.only(right: index == chips.length - 1 ? 0 : 12),
            child: chips[index],
          );
        }),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

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
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCompleted ? habitColor : Colors.transparent,
          border: Border.all(
            color: isCompleted ? habitColor : AppColors.divider,
            width: 2,
          ),
        ),
        child:
            isCompleted
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
                : null,
      ),
    );
  }

  Widget _buildCompactQuantifiableControls(
    Color habitColor,
    bool isCompleted,
    bool canInteract,
  ) {
    final currentValue = widget.instance?.value ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMiniButton(
          icon: CupertinoIcons.minus,
          onTap: currentValue > 0 ? () => _updateQuantifiableValue(-1) : null,
          habitColor: habitColor,
          canInteract: canInteract,
        ),
        const SizedBox(width: 8),
        _buildMiniButton(
          icon: CupertinoIcons.plus,
          onTap: !isCompleted ? () => _updateQuantifiableValue(1) : null,
          habitColor: habitColor,
          canInteract: canInteract,
        ),
      ],
    );
  }

  Widget _buildMiniButton({
    required IconData icon,
    VoidCallback? onTap,
    required Color habitColor,
    required bool canInteract,
  }) {
    final isEnabled = onTap != null && canInteract;
    return GestureDetector(
      onTap: () {
        if (isEnabled) {
          HapticFeedback.lightImpact();
          onTap();
        }
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              isEnabled
                  ? habitColor.withAlpha(20)
                  : AppColors.surface.withAlpha(50),
          border: Border.all(
            color:
                isEnabled
                    ? habitColor.withAlpha(80)
                    : AppColors.divider.withAlpha(50),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isEnabled ? habitColor : AppColors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildUnavailableIndicator() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface.withAlpha(30),
        border: Border.all(color: AppColors.divider.withAlpha(20), width: 2),
      ),
      child: Icon(
        CupertinoIcons.minus_circle,
        size: 16,
        color: AppColors.textTertiary.withAlpha(80),
      ),
    );
  }

  void _handleCheckboxTap(bool isCompleted) {
    if (widget.instance == null) return;
    if (!isCompleted) {
      widget.onComplete(widget.instance!);
    } else {
      widget.onUncomplete(widget.instance!);
    }
  }

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

  Color _getTextColor(bool isCompleted, bool canInteract) {
    if (!canInteract) return AppColors.textSecondary.withAlpha(140);
    return isCompleted ? AppColors.textSecondary : AppColors.textPrimary;
  }

  Color _getSecondaryTextColor(bool isCompleted, bool canInteract) {
    if (!canInteract) return AppColors.textTertiary.withAlpha(120);
    return isCompleted ? AppColors.textTertiary : AppColors.textSecondary;
  }

  Color _getIconColor(Color habitColor, bool isCompleted, bool canInteract) {
    if (!canInteract) return AppColors.textSecondary.withAlpha(140);
    return isCompleted ? AppColors.textSecondary : AppColors.textPrimary;
  }

  bool _shouldShowMetadata() =>
      widget.habit.currentStreak > 0 ||
      widget.habit.preferredTime != null ||
      widget.habit.tags.isNotEmpty ||
      widget.habit.frequency != HabitFrequency.daily ||
      _shouldShowProgressBar();

  bool _shouldShowProgressBar() =>
      widget.habit.habitType == HabitType.quantifiable &&
      widget.habit.targetValue != null &&
      widget.instance != null;

  bool _isDefaultHabitColor(String color) =>
      color == '#2C2C2E' || color == '#8E8E93';

  bool _isToday() {
    final now = DateTime.now();
    final selected = widget.selectedDate;
    return now.year == selected.year &&
        now.month == selected.month &&
        now.day == selected.day;
  }

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
        final refDate =
            widget.habit.lastCompletedDate ?? widget.habit.createdAt;
        final diff = today.difference(refDate).inDays;
        return diff >= 0 && diff % widget.habit.customInterval! == 0;
    }
  }

  String _formatTimeOfDay(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

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

class _ProgressBorderPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;
  final double radius;

  _ProgressBorderPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintBg =
        Paint()
          ..color = backgroundColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    final paintProgress =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius - strokeWidth / 2),
    );

    canvas.drawRRect(rrect, paintBg);

    if (progress > 0.001) {
      final Path path = Path()..addRRect(rrect);
      final PathMetric pathMetric = path.computeMetrics().first;
      final Path extractPath = pathMetric.extractPath(
        0.0,
        pathMetric.length * progress,
      );
      canvas.drawPath(extractPath, paintProgress);
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressBorderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
