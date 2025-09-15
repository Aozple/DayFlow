import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/material.dart';
import 'dart:async';

/// Enhanced current time indicator with pulse animation
class HomeCurrentTimeIndicator extends StatefulWidget {
  final DateTime selectedDate;
  final List<TaskModel> displayTasks;

  const HomeCurrentTimeIndicator({
    super.key,
    required this.selectedDate,
    required this.displayTasks,
  });

  @override
  State<HomeCurrentTimeIndicator> createState() =>
      _HomeCurrentTimeIndicatorState();
}

class _HomeCurrentTimeIndicatorState extends State<HomeCurrentTimeIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Pulse animation for the indicator dot
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);

    // Update every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  double _calculatePosition() {
    final currentTime = DateTime.now();
    final currentMinute = currentTime.minute;
    final hourProgress = currentMinute / 60.0;
    double position = 16;

    // Calculate position based on hour slots and tasks
    for (int i = 0; i < currentTime.hour; i++) {
      final hourTaskCount =
          widget.displayTasks.where((t) => t.dueDate?.hour == i).length;
      position += hourTaskCount == 0 ? 90 : 90 + (hourTaskCount * 58);
    }
    position += hourProgress * 90;

    return position;
  }

  @override
  Widget build(BuildContext context) {
    final position = _calculatePosition();

    return Positioned(
      top: position,
      left: 0,
      right: 0,
      child: Row(
        children: [
          // Time label
          Container(
            width: 70,
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // Animated indicator dot
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withAlpha(60),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Line
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accent, AppColors.accent.withAlpha(50)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
