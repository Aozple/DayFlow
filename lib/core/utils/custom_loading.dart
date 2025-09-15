import 'package:flutter/material.dart';
import 'dart:math' as math;

// Custom loading animation widget
class CustomLoading extends StatefulWidget {
  final double size;
  final Color? color;

  const CustomLoading({super.key, this.size = 50, this.color});

  @override
  State<CustomLoading> createState() => _CustomLoadingState();
}

class _CustomLoadingState extends State<CustomLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Create eased animation
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use provided color or theme primary color
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _animation.value * 2 * math.pi,
            child: CustomPaint(
              painter: _LoadingPainter(
                color: color,
                progress: _animation.value,
              ),
            ),
          );
        },
      ),
    );
  }
}

// Custom painter for drawing the loading animation
class _LoadingPainter extends CustomPainter {
  final Color color;
  final double progress;

  _LoadingPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Configure arc paint style
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - paint.strokeWidth) / 2;

    // Calculate sweep angle (75% of a circle)
    final sweepAngle = 2 * math.pi * progress * 0.75;

    // Draw the animated arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      paint,
    );

    // Configure dot paint style
    final dotPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    // Calculate dot position at end of arc
    final angle = -math.pi / 2 + sweepAngle;
    final dotX = center.dx + radius * math.cos(angle);
    final dotY = center.dy + radius * math.sin(angle);

    // Draw the dot
    canvas.drawCircle(Offset(dotX, dotY), 6, dotPaint);
  }

  @override
  bool shouldRepaint(_LoadingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
