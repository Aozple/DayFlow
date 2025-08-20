import 'package:flutter/material.dart';
import 'dart:math' as math; // Import math library for trigonometric functions.

// This widget provides a custom loading animation.
class CustomLoading extends StatefulWidget {
  final double size; // The size (width and height) of the loading indicator.
  final Color? color; // Optional color for the loading indicator.

  const CustomLoading({super.key, this.size = 50, this.color});

  @override
  State<CustomLoading> createState() => _CustomLoadingState();
}

// The state for our CustomLoading widget, handling the animation.
class _CustomLoadingState extends State<CustomLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller; // Controls the animation's progress.
  late Animation<double> _animation; // The animation value, from 0.0 to 1.0.

  @override
  void initState() {
    super.initState();
    // Set up the animation controller for a continuous rotation.
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500), // Animation duration.
      vsync: this, // Use this widget as the vsync provider.
    )..repeat(); // Make the animation repeat indefinitely.

    // Create a curved animation for a smoother start and end to each rotation.
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose(); // Clean up the animation controller to prevent memory leaks.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use the provided color or default to the primary color from the theme.
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation, // Rebuilds the widget whenever the animation value changes.
        builder: (context, child) {
          return Transform.rotate(
            angle:
                _animation.value * 2 * math.pi, // Rotate based on animation progress (full circle).
            child: CustomPaint(
              painter: _LoadingPainter(
                color: color,
                progress: _animation.value, // Pass animation progress to the painter.
              ),
            ),
          );
        },
      ),
    );
  }
}

// This custom painter draws the unique loading animation.
class _LoadingPainter extends CustomPainter {
  final Color color; // The color of the loading arc and dot.
  final double progress; // The current animation progress (0.0 to 1.0).

  _LoadingPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Set up the paint properties for the arc.
    final paint =
        Paint()
          ..color = color // Use the specified color.
          ..strokeWidth = 4 // Thickness of the arc.
          ..style = PaintingStyle.stroke // Draw only the outline.
          ..strokeCap = StrokeCap.round; // Rounded ends for the arc.

    final center = Offset(size.width / 2, size.height / 2); // Center of the canvas.
    final radius = (size.width - paint.strokeWidth) / 2; // Radius of the arc.

    // Calculate the sweep angle for the arc, making it animate up to 75% of a circle.
    final sweepAngle = 2 * math.pi * progress * 0.75;

    // Draw the animated arc.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius), // Define the bounding circle for the arc.
      -math.pi / 2, // Start the arc from the top (12 o'clock position).
      sweepAngle, // The length of the arc.
      false, // Don't connect the center to the arc.
      paint, // The paint style.
    );

    // Set up the paint properties for the dot.
    final dotPaint =
        Paint()
          ..color = color // Same color as the arc.
          ..style = PaintingStyle.fill; // Fill the dot.

    // Calculate the position of the dot at the end of the arc using trigonometry.
    final angle = -math.pi / 2 + sweepAngle; // Current angle of the arc's end.
    final dotX = center.dx + radius * math.cos(angle); // X coordinate of the dot.
    final dotY = center.dy + radius * math.sin(angle); // Y coordinate of the dot.

    canvas.drawCircle(Offset(dotX, dotY), 6, dotPaint); // Draw the dot.
  }

  @override
  bool shouldRepaint(_LoadingPainter oldDelegate) {
    // Only repaint if the progress has changed, to optimize performance.
    return oldDelegate.progress != progress;
  }
}
