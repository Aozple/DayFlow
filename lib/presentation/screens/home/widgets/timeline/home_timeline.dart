import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dayflow/core/constants/app_colors.dart';
import 'home_current_time_indicator.dart';
import 'home_time_slot.dart';

/// Main timeline view with overscroll day navigation
class HomeTimeline extends StatefulWidget {
  final ScrollController scrollController;
  final DateTime selectedDate;
  final List<TaskModel> tasks;
  final List<TaskModel> filteredTasks;
  final bool hasActiveFilters;
  final Function(int) onQuickAddMenu;
  final Function(TaskModel) onTaskToggled;
  final Function(TaskModel) onTaskOptions;
  final Function(TaskModel) onNoteOptions;
  final Function(DateTime) onDateChanged;

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
    required this.onDateChanged,
  });

  @override
  State<HomeTimeline> createState() => _HomeTimelineState();
}

class _HomeTimelineState extends State<HomeTimeline>
    with SingleTickerProviderStateMixin {
  late AnimationController _indicatorController;
  late Animation<double> _indicatorAnimation;

  double _overscrollAmount = 0.0;
  bool _isOverscrolling = false;
  bool _isAtTop = false;
  bool _isAtBottom = false;
  bool _hasNavigated = false;
  bool _canStartNewGesture = true; // New flag for gesture control
  DateTime? _lastNavigationTime; // Track last navigation

  static const double _threshold = 250.0;

  @override
  void initState() {
    super.initState();
    _indicatorController = AnimationController(
      duration: const Duration(milliseconds: 500),
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

  @override
  Widget build(BuildContext context) {
    final displayTasks =
        widget.hasActiveFilters ? widget.filteredTasks : widget.tasks;
    final now = DateTime.now();
    final isToday = _isSameDay(widget.selectedDate, now);

    return Stack(
      children: [
        // Main timeline with overscroll detection
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            // Check if we can process new gestures
            if (!_canStartNewGesture) {
              // Check if user has released and started a new gesture
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
              // Reset if scrolling normally (not at edges)
              if (_isOverscrolling &&
                  notification.metrics.pixels >
                      notification.metrics.minScrollExtent + 10 &&
                  notification.metrics.pixels <
                      notification.metrics.maxScrollExtent - 10) {
                _resetOverscroll();
              }
            }
            return false;
          },
          child: ListView.builder(
            controller: widget.scrollController,
            padding: const EdgeInsets.only(top: 16, bottom: 100),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: 24,
            itemBuilder: (context, index) {
              final hour = index;
              final hourTasks =
                  displayTasks
                      .where((task) => task.dueDate?.hour == hour)
                      .toList()
                    ..sort((a, b) {
                      final minuteComparison = (a.dueDate?.minute ?? 0)
                          .compareTo(b.dueDate?.minute ?? 0);
                      if (minuteComparison == 0) {
                        return b.priority.compareTo(a.priority);
                      }
                      return minuteComparison;
                    });

              return HomeTimeSlot(
                hour: hour,
                tasks: hourTasks,
                isCurrentHour: isToday && now.hour == hour,
                onQuickAddMenu: widget.onQuickAddMenu,
                onTaskToggled: widget.onTaskToggled,
                onTaskOptions: widget.onTaskOptions,
                onNoteOptions: widget.onNoteOptions,
              );
            },
          ),
        ),

        // Current time indicator
        if (isToday)
          HomeCurrentTimeIndicator(
            selectedDate: widget.selectedDate,
            displayTasks: displayTasks,
          ),

        // Navigation indicator
        if (_isOverscrolling && !_hasNavigated)
          AnimatedBuilder(
            animation: _indicatorAnimation,
            builder: (context, child) {
              return Positioned(
                top: _isAtTop ? 20 : null,
                bottom: _isAtBottom ? 120 : null,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _indicatorAnimation.value,
                  child: Transform.scale(
                    scale: 0.9 + (_indicatorAnimation.value * 0.1),
                    child: _buildNavigationIndicator(),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  void _handleOverscroll(OverscrollNotification notification) {
    // Don't process if already navigated in this gesture
    if (_hasNavigated) return;

    // Check for cooldown period (prevent rapid navigation)
    if (_lastNavigationTime != null) {
      final timeSinceLastNav = DateTime.now().difference(_lastNavigationTime!);
      if (timeSinceLastNav.inMilliseconds < 500) {
        return;
      }
    }

    final metrics = notification.metrics;
    final overscroll = notification.overscroll;

    // Check position
    final isCurrentlyAtTop =
        metrics.pixels <= metrics.minScrollExtent && overscroll < 0;
    final isCurrentlyAtBottom =
        metrics.pixels >= metrics.maxScrollExtent && overscroll > 0;

    if (isCurrentlyAtTop || isCurrentlyAtBottom) {
      // Only update if we're starting a new overscroll
      if (!_isOverscrolling) {
        _isAtTop = isCurrentlyAtTop;
        _isAtBottom = isCurrentlyAtBottom;
      }

      setState(() {
        _isOverscrolling = true;
        _overscrollAmount += overscroll.abs();
        _overscrollAmount = _overscrollAmount.clamp(
          0.0,
          _threshold + 20,
        ); // Cap the amount
      });

      if (!_indicatorController.isAnimating ||
          _indicatorController.status == AnimationStatus.reverse) {
        _indicatorController.forward();
      }

      // Navigate if threshold reached (only once)
      if (_overscrollAmount >= _threshold && !_hasNavigated) {
        _performNavigation();
      }
    }
  }

  void _handleScrollEnd() {
    // Only navigate if we haven't already
    if (_isOverscrolling && _overscrollAmount >= _threshold && !_hasNavigated) {
      _performNavigation();
    } else {
      _resetOverscroll();
    }
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

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Navigate
    widget.onDateChanged(newDate);

    // Scroll to appropriate position after navigation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && widget.scrollController.hasClients) {
        final targetOffset =
            _isAtBottom
                ? 0.0 // Go to start of next day (00:00)
                : widget
                    .scrollController
                    .position
                    .maxScrollExtent; // Go to end of previous day (23:00)

        widget.scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });

    // Reset after delay
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _resetOverscroll();
      }
    });
  }

  void _resetOverscroll() {
    if (mounted) {
      setState(() {
        _isOverscrolling = false;
        _overscrollAmount = 0.0;
        _isAtTop = false;
        _isAtBottom = false;
        // Don't reset _hasNavigated here - it should stay true until new gesture
      });
      _indicatorController.reverse();
    }
  }

  Widget _buildNavigationIndicator() {
    final isNext = _isAtBottom;
    final targetDate =
        isNext
            ? widget.selectedDate.add(const Duration(days: 1))
            : widget.selectedDate.subtract(const Duration(days: 1));

    final progress = (_overscrollAmount / _threshold).clamp(0.0, 1.0);
    final isReady = progress >= 1.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isReady ? AppColors.accent : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isReady ? AppColors.accent : AppColors.divider.withAlpha(100),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isReady ? AppColors.accent : Colors.black).withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isNext ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            color: isReady ? Colors.white : AppColors.textSecondary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isReady ? 'Release to go to' : 'Pull to navigate',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isReady ? Colors.white : AppColors.textSecondary,
                ),
              ),
              Text(
                _formatDate(targetDate),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isReady ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 2,
              backgroundColor:
                  isReady
                      ? Colors.white.withAlpha(50)
                      : AppColors.divider.withAlpha(100),
              valueColor: AlwaysStoppedAnimation<Color>(
                isReady ? Colors.white : AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final yesterday = now.subtract(const Duration(days: 1));

    if (_isSameDay(date, now)) {
      return 'Today';
    } else if (_isSameDay(date, tomorrow)) {
      return 'Tomorrow';
    } else if (_isSameDay(date, yesterday)) {
      return 'Yesterday';
    } else {
      final months = [
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
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
