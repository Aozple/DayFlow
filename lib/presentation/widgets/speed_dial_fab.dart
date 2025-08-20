// This widget creates a speed dial floating action button (FAB) that expands to show options for creating a task or a note.

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
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController; // Controls the FAB's animation.
  bool _isOpen = false; // Tracks whether the FAB is currently open or closed.

  @override
  void initState() {
    super.initState();
    // Initialize the animation controller with a duration and vsync.
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    // Clean up the animation controller to prevent memory leaks.
    _animationController.dispose();
    super.dispose();
  }

  // Toggles the open/close state of the FAB and starts the animation.
  void _toggle() {
    setState(() {
      _isOpen = !_isOpen; // Flip the open state.
      if (_isOpen) {
        _animationController.forward(); // Animate open.
      } else {
        _animationController.reverse(); // Animate closed.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56, // Fixed width to prevent layout issues during animation.
      height: 200, // Enough height to accommodate the expanded state.
      child: Stack(
        alignment: Alignment.bottomCenter, // Align children to the bottom center.
        clipBehavior: Clip.none, // Allow children to overflow the bounds.
        children: [
          // Background overlay when the FAB is open.
          if (_isOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggle, // Close the FAB when tapping the background.
                child: Container(color: Colors.transparent), // Make the background tappable.
              ),
            ),

          // Note button (appears when FAB is open).
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250), // Animation duration.
            curve: Curves.easeOutBack, // Animation curve.
            bottom: _isOpen ? 140 : 0, // Position when open/closed.
            right: 4,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isOpen ? 1.0 : 0.0, // Fade in/out based on open state.
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Label for the note button.
                  if (_isOpen)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface, // Background color.
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(25), // Subtle shadow.
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

                  // The note button itself.
                  SizedBox(
                    width: 54,
                    height: 54,
                    child: FloatingActionButton(
                      heroTag: 'note_fab', // Unique tag for hero animation.
                      onPressed: () {
                        _toggle(); // Close the FAB.
                        widget.onCreateNote(); // Execute the create note callback.
                      },
                      backgroundColor: AppColors.warning, // Warning color for notes.
                      elevation: 4, // Shadow elevation.
                      child: const Icon(
                        CupertinoIcons.doc_text, // Note icon.
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Task button (appears when FAB is open).
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            bottom: _isOpen ? 70 : 0, // Position when open/closed.
            right: 4,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isOpen ? 1.0 : 0.0, // Fade in/out based on open state.
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Label for the task button.
                  if (_isOpen)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface, // Background color.
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(25), // Subtle shadow.
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

                  // The task button itself.
                  SizedBox(
                    width: 54,
                    height: 54,
                    child: FloatingActionButton(
                      heroTag: 'task_fab', // Unique tag for hero animation.
                      onPressed: () {
                        _toggle(); // Close the FAB.
                        widget.onCreateTask(); // Execute the create task callback.
                      },
                      backgroundColor: AppColors.success, // Success color for tasks.
                      elevation: 4, // Shadow elevation.
                      child: const Icon(
                        CupertinoIcons.checkmark_square, // Task icon.
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main FAB (always visible).
          FloatingActionButton(
            heroTag: 'main_fab', // Unique tag for hero animation.
            onPressed: _toggle, // Toggle open/close state.
            backgroundColor: AppColors.accent, // Accent color.
            elevation: 8, // Shadow elevation.
            child: AnimatedBuilder(
              animation: _animationController, // Rebuild when animation changes.
              builder: (context, child) {
                return Transform.rotate(
                  angle: _animationController.value * 0.25 * 2 * math.pi, // Rotate the icon.
                  child: Icon(
                    _isOpen ? Icons.close : Icons.add, // Show add or close icon.
                    color: Colors.white,
                    size: 28,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
