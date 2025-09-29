import 'package:dayflow/data/models/habit_instance_model.dart';
import 'package:dayflow/data/models/habit_model.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dayflow/core/constants/app_colors.dart';
import 'home_time_slot.dart';

/// Interactive 24-hour timeline with pull-to-navigate between days
class HomeTimeline extends StatefulWidget {
  final ScrollController scrollController;
  final DateTime selectedDate;
  final List<TaskModel> tasks;
  final List<HabitWithInstance> habits;
  final List<TaskModel> filteredTasks;
  final List<HabitWithInstance> filteredHabits;
  final bool hasActiveFilters;
  final Function(int) onQuickAddMenu;
  final Function(TaskModel) onTaskToggled;
  final Function(TaskModel) onTaskOptions;
  final Function(TaskModel) onNoteOptions;
  final Function(HabitInstanceModel) onHabitComplete;
  final Function(HabitInstanceModel) onHabitUncomplete;
  final Function(HabitInstanceModel) onHabitUpdateInstance;
  final Function(HabitModel) onHabitOptions;
  final Function(DateTime) onDateChanged;

  const HomeTimeline({
    super.key,
    required this.scrollController,
    required this.selectedDate,
    required this.tasks,
    this.habits = const [],
    required this.filteredTasks,
    required this.filteredHabits,
    required this.hasActiveFilters,
    required this.onQuickAddMenu,
    required this.onTaskToggled,
    required this.onTaskOptions,
    required this.onNoteOptions,
    required this.onHabitComplete,
    required this.onHabitUncomplete,
    required this.onHabitUpdateInstance,
    required this.onHabitOptions,
    required this.onDateChanged,
  });

  @override
  State<HomeTimeline> createState() => _HomeTimelineState();
}

class _HomeTimelineState extends State<HomeTimeline>
    with SingleTickerProviderStateMixin {
  // Animation controllers
  late AnimationController _indicatorController;
  late Animation<double> _indicatorAnimation;

  // Overscroll state management
  double _overscrollAmount = 0.0;
  bool _isOverscrolling = false;
  bool _isAtTop = false;
  bool _isAtBottom = false;
  bool _hasNavigated = false;
  bool _canStartNewGesture = true;
  DateTime? _lastNavigationTime;

  // Constants
  static const double _overscrollThreshold = 200.0;
  static const double _maxOverscroll = 250.0;
  static const double _scrollEdgeBuffer = 25.0;
  static const int _navigationCooldown = 500; // milliseconds
  static const int _navigationDelay = 100; // milliseconds
  static const int _resetDelay = 500; // milliseconds

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _indicatorController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _indicatorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _indicatorController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    super.dispose();
  }

  // === Build Methods ===

  @override
  Widget build(BuildContext context) {
    final displayTasks =
        widget.hasActiveFilters ? widget.filteredTasks : widget.tasks;
    final displayHabits =
        widget.hasActiveFilters ? widget.filteredHabits : widget.habits;
    final now = DateTime.now();
    final isToday = _isSameDay(widget.selectedDate, now);

    return Stack(
      children: [
        _buildTimeline(displayTasks, displayHabits, isToday, now),
        if (_isOverscrolling && !_hasNavigated) _buildNavigationOverlay(),
      ],
    );
  }

  Widget _buildTimeline(
    List<TaskModel> displayTasks,
    List<HabitWithInstance> displayHabits,
    bool isToday,
    DateTime now,
  ) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: ListView.builder(
        controller: widget.scrollController,
        padding: const EdgeInsets.only(top: 0, bottom: 48),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: 24,
        itemBuilder: (context, hour) {
          final hourTasks = _getTasksForHour(displayTasks, hour);
          final hourHabits = _getHabitsForHour(displayHabits, hour);

          return HomeTimeSlot(
            hour: hour,
            tasks: hourTasks,
            habits: hourHabits,
            isCurrentHour: isToday && now.hour == hour,
            selectedDate: widget.selectedDate,
            onQuickAddMenu: widget.onQuickAddMenu,
            onTaskToggled: widget.onTaskToggled,
            onTaskOptions: widget.onTaskOptions,
            onNoteOptions: widget.onNoteOptions,
            onHabitComplete: widget.onHabitComplete,
            onHabitUncomplete: widget.onHabitUncomplete,
            onHabitUpdateInstance: widget.onHabitUpdateInstance,
            onHabitOptions: widget.onHabitOptions,
          );
        },
      ),
    );
  }

  Widget _buildNavigationOverlay() {
    return AnimatedBuilder(
      animation: _indicatorAnimation,
      builder: (context, child) {
        return Positioned(
          top: _isAtTop ? 20 : null,
          bottom: _isAtBottom ? 100 : null,
          left: 0,
          right: 0,
          child: Opacity(
            opacity: _indicatorAnimation.value,
            child: Transform.scale(
              scale: 0.8 + (_indicatorAnimation.value * 0.2),
              child: _buildNavigationIndicator(),
            ),
          ),
        );
      },
    );
  }

  // === Data Processing ===

  List<TaskModel> _getTasksForHour(List<TaskModel> tasks, int hour) {
    return tasks.where((task) => task.dueDate?.hour == hour).toList()
      ..sort((a, b) {
        final minuteComparison = (a.dueDate?.minute ?? 0).compareTo(
          b.dueDate?.minute ?? 0,
        );
        return minuteComparison != 0
            ? minuteComparison
            : b.priority.compareTo(a.priority);
      });
  }

  List<HabitWithInstance> _getHabitsForHour(
    List<HabitWithInstance> habits,
    int hour,
  ) {
    return habits.where((habitWithInstance) {
      final preferredTime = habitWithInstance.habit.preferredTime;
      return preferredTime != null && preferredTime.hour == hour;
    }).toList();
  }

  // === Scroll Handling ===

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!_canStartNewGesture) {
      if (notification is ScrollStartNotification) {
        _canStartNewGesture = true;
        _hasNavigated = false;
      }
      return false;
    }

    if (notification is OverscrollNotification) {
      _handleOverscroll(notification);
    } else if (notification is ScrollEndNotification) {
      _handleScrollEnd();
    } else if (notification is ScrollUpdateNotification) {
      _checkForScrollReset(notification);
    }
    return false;
  }

  void _checkForScrollReset(ScrollUpdateNotification notification) {
    if (_isOverscrolling &&
        notification.metrics.pixels >
            notification.metrics.minScrollExtent + _scrollEdgeBuffer &&
        notification.metrics.pixels <
            notification.metrics.maxScrollExtent - _scrollEdgeBuffer) {
      _resetOverscroll();
    }
  }

  void _handleOverscroll(OverscrollNotification notification) {
    if (_hasNavigated || !_canNavigate()) return;

    final metrics = notification.metrics;
    final overscroll = notification.overscroll;

    final isCurrentlyAtTop =
        metrics.pixels <= metrics.minScrollExtent && overscroll < 0;
    final isCurrentlyAtBottom =
        metrics.pixels >= metrics.maxScrollExtent && overscroll > 0;

    if (isCurrentlyAtTop || isCurrentlyAtBottom) {
      _updateOverscrollState(isCurrentlyAtTop, isCurrentlyAtBottom, overscroll);

      if (_overscrollAmount >= _overscrollThreshold && !_hasNavigated) {
        _performNavigation();
      }
    }
  }

  void _updateOverscrollState(bool atTop, bool atBottom, double overscroll) {
    if (!_isOverscrolling) {
      _isAtTop = atTop;
      _isAtBottom = atBottom;
    }

    setState(() {
      _isOverscrolling = true;
      _overscrollAmount = (_overscrollAmount + overscroll.abs()).clamp(
        0.0,
        _maxOverscroll,
      );
    });

    if (!_indicatorController.isAnimating ||
        _indicatorController.status == AnimationStatus.reverse) {
      _indicatorController.forward();
    }
  }

  void _handleScrollEnd() {
    if (_isOverscrolling &&
        _overscrollAmount >= _overscrollThreshold &&
        !_hasNavigated) {
      _performNavigation();
    } else {
      _resetOverscroll();
    }
  }

  // === Navigation Logic ===

  bool _canNavigate() {
    if (_lastNavigationTime == null) return true;

    final timeSinceLastNav = DateTime.now().difference(_lastNavigationTime!);
    return timeSinceLastNav.inMilliseconds >= _navigationCooldown;
  }

  void _performNavigation() {
    if (_hasNavigated) return;

    setState(() {
      _hasNavigated = true;
      _canStartNewGesture = false;
    });

    final direction = _isAtBottom ? 1 : -1;
    final newDate = widget.selectedDate.add(Duration(days: direction));

    _lastNavigationTime = DateTime.now();
    HapticFeedback.mediumImpact();
    widget.onDateChanged(newDate);

    _scrollToEdgeAfterNavigation();
    _scheduleReset();
  }

  void _scrollToEdgeAfterNavigation() {
    Future.delayed(const Duration(milliseconds: _navigationDelay), () {
      if (mounted && widget.scrollController.hasClients) {
        final targetOffset =
            _isAtBottom
                ? 0.0
                : widget.scrollController.position.maxScrollExtent;

        widget.scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _scheduleReset() {
    Future.delayed(const Duration(milliseconds: _resetDelay), () {
      if (mounted) {
        _resetOverscroll();
      }
    });
  }

  void _resetOverscroll() {
    if (!mounted) return;

    setState(() {
      _isOverscrolling = false;
      _overscrollAmount = 0.0;
      _isAtTop = false;
      _isAtBottom = false;
    });
    _indicatorController.reverse();
  }

  // === UI Components ===

  Widget _buildNavigationIndicator() {
    final isNext = _isAtBottom;
    final targetDate =
        isNext
            ? widget.selectedDate.add(const Duration(days: 1))
            : widget.selectedDate.subtract(const Duration(days: 1));

    final progress = (_overscrollAmount / _overscrollThreshold).clamp(0.0, 1.0);
    final isReady = progress >= 1.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isReady) _buildGlowEffect(),
          _buildIndicatorCard(isReady, targetDate, progress, isNext),
        ],
      ),
    );
  }

  Widget _buildGlowEffect() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.accent.withAlpha(40),
            AppColors.accent.withAlpha(20),
            AppColors.accent.withAlpha(0),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorCard(
    bool isReady,
    DateTime targetDate,
    double progress,
    bool isNext,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: _getIndicatorDecoration(isReady),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildDirectionIcon(isReady, isNext),
          const SizedBox(width: 12),
          _buildDateInfo(isReady, targetDate),
          const SizedBox(width: 12),
          _buildProgressIndicator(isReady, progress),
        ],
      ),
    );
  }

  BoxDecoration _getIndicatorDecoration(bool isReady) {
    return BoxDecoration(
      gradient:
          isReady
              ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.accent, AppColors.accent.withAlpha(230)],
              )
              : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.surface, AppColors.surfaceLight],
              ),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: isReady ? AppColors.accent : AppColors.divider.withAlpha(60),
        width: 0.5,
      ),
      boxShadow: _getIndicatorShadows(isReady),
    );
  }

  List<BoxShadow> _getIndicatorShadows(bool isReady) {
    return [
      BoxShadow(
        color:
            isReady
                ? AppColors.accent.withAlpha(50)
                : AppColors.background.withAlpha(40),
        blurRadius: isReady ? 20 : 10,
        offset: const Offset(0, 4),
        spreadRadius: isReady ? 2 : 0,
      ),
      if (isReady)
        BoxShadow(
          color: AppColors.accent.withAlpha(30),
          blurRadius: 30,
          offset: const Offset(0, 8),
          spreadRadius: -5,
        ),
    ];
  }

  Widget _buildDirectionIcon(bool isReady, bool isNext) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isReady ? Colors.white.withAlpha(20) : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              isReady
                  ? Colors.white.withAlpha(30)
                  : AppColors.divider.withAlpha(40),
          width: 0.5,
        ),
      ),
      child: Icon(
        isNext ? CupertinoIcons.arrow_down : CupertinoIcons.arrow_up,
        color: isReady ? Colors.white : AppColors.textSecondary,
        size: 18,
      ),
    );
  }

  Widget _buildDateInfo(bool isReady, DateTime targetDate) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isReady ? 'Release to navigate' : 'Pull to continue',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color:
                isReady ? Colors.white.withAlpha(200) : AppColors.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Text(
              _formatDate(targetDate),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isReady ? Colors.white : AppColors.textPrimary,
                letterSpacing: 0.1,
              ),
            ),
            if (_isSameDay(targetDate, DateTime.now()))
              _buildTodayBadge(isReady),
          ],
        ),
      ],
    );
  }

  Widget _buildTodayBadge(bool isReady) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color:
            isReady
                ? Colors.white.withAlpha(20)
                : AppColors.accent.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color:
              isReady
                  ? Colors.white.withAlpha(30)
                  : AppColors.accent.withAlpha(40),
          width: 0.5,
        ),
      ),
      child: Text(
        'TODAY',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: isReady ? Colors.white : AppColors.accent,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(bool isReady, double progress) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isReady ? Colors.white.withAlpha(15) : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  isReady
                      ? Colors.white.withAlpha(30)
                      : AppColors.divider.withAlpha(40),
              width: 0.5,
            ),
          ),
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 2.5,
            backgroundColor:
                isReady
                    ? Colors.white.withAlpha(20)
                    : AppColors.divider.withAlpha(40),
            valueColor: AlwaysStoppedAnimation<Color>(
              isReady ? Colors.white : AppColors.accent,
            ),
          ),
        ),
        if (isReady)
          const Icon(
            CupertinoIcons.checkmark_alt,
            size: 14,
            color: Colors.white,
          ),
      ],
    );
  }

  // === Utility Methods ===

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final yesterday = now.subtract(const Duration(days: 1));

    if (_isSameDay(date, now)) return 'Today';
    if (_isSameDay(date, tomorrow)) return 'Tomorrow';
    if (_isSameDay(date, yesterday)) return 'Yesterday';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
