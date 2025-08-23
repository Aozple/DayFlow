import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math; // For mathematical calculations like rotation.
import '../../core/constants/app_colors.dart';

class SpeedDialFab extends StatefulWidget {
  // Callback function to execute when the "Create Task" option is selected.
  final VoidCallback onCreateTask;
  // Callback function to execute when the "Create Note" option is selected.
  final VoidCallback onCreateNote;

  const SpeedDialFab({
    super.key,
    required this.onCreateTask,
    required this.onCreateNote,
  });

  @override
  State<SpeedDialFab> createState() => _SpeedDialFabState();
}

// The state class for our SpeedDialFab, managing its animation and open/close state.
class _SpeedDialFabState extends State<SpeedDialFab>
    with TickerProviderStateMixin {
  late AnimationController
  _animationController; // Controls the FAB's rotation animation.
  late AnimationController
  _expandController; // Controls the expand/collapse animation.
  late Animation<double>
  _expandAnimation; // Curved animation for smooth movement.
  bool _isOpen = false; // Tracks whether the FAB is currently open or closed.
  OverlayEntry?
  _overlayEntry; // Manages the overlay for background and buttons.
  final GlobalKey _fabKey = GlobalKey(); // Key to get FAB position on screen.

  @override
  void initState() {
    super.initState();
    // Initialize the rotation animation controller.
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    // Initialize the expand animation controller.
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    // Create curved animation for smooth easing effect like AnimatedPositioned.
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    // Clean up resources to prevent memory leaks.
    _removeOverlay();
    _animationController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  // Toggles the open/close state of the FAB and manages animations.
  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        // Opening sequence: rotate icon, show overlay, then expand buttons.
        _animationController.forward();
        _insertOverlay();
        _expandController.forward();
      } else {
        // Closing sequence: rotate icon, collapse buttons, then remove overlay.
        _animationController.reverse();
        _expandController.reverse().then((_) {
          _removeOverlay();
        });
      }
    });
  }

  // Creates and inserts the overlay containing background and action buttons.
  void _insertOverlay() {
    // Get the FAB's position on screen for proper button placement.
    final RenderBox? renderBox =
        _fabKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final fabPosition = renderBox.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;

    _overlayEntry = OverlayEntry(
      builder:
          (context) => Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                // Semi-transparent background that captures any touch to close the FAB.
                Positioned.fill(
                  child: GestureDetector(
                    onTapDown: (_) {
                      if (_isOpen) _toggle(); // Close on any touch.
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(color: Colors.transparent),
                  ),
                ),

                // Task button with slide-up animation.
                AnimatedBuilder(
                  animation: _expandAnimation,
                  builder: (context, child) {
                    final animValue = _expandAnimation.value.clamp(0.0, 1.0);
                    return Positioned(
                      right: screenWidth - fabPosition.dx - 54,
                      top: fabPosition.dy - (70 * animValue),
                      child: Opacity(
                        opacity: animValue,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Label appears after button is halfway through animation.
                            if (animValue > 0.5)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(25),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Task',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                            // Task button.
                            SizedBox(
                              width: 56,
                              height: 56,
                              child: FloatingActionButton(
                                heroTag: 'task_fab_overlay',
                                onPressed: () {
                                  _toggle();
                                  widget.onCreateTask();
                                },
                                backgroundColor: AppColors.success,
                                elevation: 4,
                                child: const Icon(
                                  CupertinoIcons.checkmark_square,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Note button with slide-up animation.
                AnimatedBuilder(
                  animation: _expandAnimation,
                  builder: (context, child) {
                    final animValue = _expandAnimation.value.clamp(0.0, 1.0);
                    return Positioned(
                      right: screenWidth - fabPosition.dx - 54,
                      top: fabPosition.dy - (140 * animValue),
                      child: Opacity(
                        opacity: animValue,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Label appears after button is halfway through animation.
                            if (animValue > 0.5)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(25),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Note',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                            // Note button.
                            SizedBox(
                              width: 56,
                              height: 56,
                              child: FloatingActionButton(
                                heroTag: 'note_fab_overlay',
                                onPressed: () {
                                  _toggle();
                                  widget.onCreateNote();
                                },
                                backgroundColor: AppColors.warning,
                                elevation: 4,
                                child: const Icon(
                                  CupertinoIcons.doc_text,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
    );

    // Insert the overlay into the widget tree.
    Overlay.of(context).insert(_overlayEntry!);
  }

  // Removes the overlay from the widget tree.
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    // Main FAB button that's always visible.
    return FloatingActionButton(
      key: _fabKey, // Key to track position for overlay placement.
      heroTag: 'main_fab', // Unique tag for hero animations.
      onPressed: _toggle, // Toggle open/close state.
      backgroundColor: AppColors.accent,
      elevation: 8,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          // Rotate icon 45 degrees when opening (+ becomes ×).
          return Transform.rotate(
            angle: _animationController.value * 0.25 * 2 * math.pi,
            child: Icon(
              _isOpen ? Icons.close : Icons.add,
              color: Colors.white,
              size: 28,
            ),
          );
        },
      ),
    );
  }
}
