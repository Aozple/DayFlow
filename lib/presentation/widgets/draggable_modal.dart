import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../core/constants/app_colors.dart';

// This widget creates a draggable modal sheet that can be resized and dismissed.
// It's designed to provide a flexible container for content that can be dragged up and down.
class DraggableModal extends StatefulWidget {
  // The content to display inside the modal.
  final Widget child;
  // The initial height of the modal when it's first opened.
  final double initialHeight;
  // The minimum height the modal can be dragged to.
  final double minHeight;
  // An optional title to display in the modal's header.
  final String? title;
  // An optional callback function to execute when the modal is closed.
  final VoidCallback? onClose;
  // An optional widget to display on the left side of the header (e.g., a cancel button).
  final Widget? leftAction;
  // An optional widget to display on the right side of the header (e.g., an apply button).
  final Widget? rightAction;
  // Whether to allow the modal to expand to full screen.
  final bool allowFullScreen;

  const DraggableModal({
    super.key,
    required this.child,
    this.initialHeight = 400,
    this.minHeight = 200,
    this.title,
    this.onClose,
    this.leftAction,
    this.rightAction,
    this.allowFullScreen = true,
  });

  @override
  State<DraggableModal> createState() => _DraggableModalState();
}

// The state class for our DraggableModal, managing its size, animations, and drag behavior.
class _DraggableModalState extends State<DraggableModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController; // Controls the height animation.
  late Animation<double> _heightAnimation; // The animation for the modal's height.

  double _currentHeight = 0; // The current height of the modal.
  double _dragStartHeight = 0; // The height of the modal when a drag starts.
  bool _isExpanded = false; // Whether the modal is in an expanded state.
  bool _isFullScreen = false; // Whether the modal is taking up the full screen.

  @override
  void initState() {
    super.initState();
    _currentHeight = widget.initialHeight; // Initialize current height.

    // Set up the animation controller.
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300), // Animation duration.
      vsync: this, // Use this widget as the vsync provider.
    );

    // Create the height animation with a smooth curve.
    _heightAnimation = Tween<double>(
      begin: widget.initialHeight,
      end: widget.initialHeight,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    // Clean up the animation controller to prevent memory leaks.
    _animationController.dispose();
    super.dispose();
  }

  // Called when a drag gesture starts.
  void _handleDragStart(DragStartDetails details) {
    _dragStartHeight = _currentHeight; // Record the starting height.
  }

  // Called continuously as the drag gesture updates.
  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      final screenHeight = MediaQuery.of(context).size.height; // Get screen height.
      // Calculate the maximum height the modal can reach.
      final maxHeight =
          widget.allowFullScreen
              ? screenHeight // Full screen including status bar.
              : screenHeight * 0.9; // 90% of screen.

      // Calculate the new height based on the drag gesture.
      _currentHeight = (_dragStartHeight - details.localPosition.dy).clamp(
        widget.minHeight, // Minimum height.
        maxHeight, // Maximum height.
      );

      // Check if we're in full screen territory.
      _isFullScreen = _currentHeight >= screenHeight - 50;
    });
  }

  // Called when the drag gesture ends.
  void _handleDragEnd(DragEndDetails details) {
    final screenHeight = MediaQuery.of(context).size.height;
    final velocity = details.velocity.pixelsPerSecond.dy; // Get drag velocity.

    double targetHeight; // The height we'll animate to.

    if (velocity < -500) {
      // Fast swipe up - go full screen if allowed.
      if (widget.allowFullScreen) {
        targetHeight = screenHeight;
        _isFullScreen = true;
      } else {
        targetHeight = screenHeight * 0.9;
      }
      _isExpanded = true;
    } else if (velocity > 500) {
      // Fast swipe down.
      if (_isFullScreen) {
        // From full screen to expanded.
        targetHeight = screenHeight * 0.75;
        _isFullScreen = false;
        _isExpanded = true;
      } else if (_currentHeight < widget.initialHeight * 0.7) {
        // Close the modal if dragged down significantly.
        Navigator.of(context).pop();
        return;
      } else {
        targetHeight = widget.initialHeight; // Return to initial height.
        _isExpanded = false;
        _isFullScreen = false;
      }
    } else {
      // Slow drag - snap to positions.
      if (_currentHeight > screenHeight * 0.85) {
        // Near top - go full screen.
        targetHeight = screenHeight;
        _isFullScreen = true;
        _isExpanded = true;
      } else if (_currentHeight > screenHeight * 0.6) {
        // More than 60% - expanded but not full.
        targetHeight = screenHeight * 0.75;
        _isExpanded = true;
        _isFullScreen = false;
      } else if (_currentHeight < widget.initialHeight * 0.5) {
        // Less than half initial - close.
        Navigator.of(context).pop();
        return;
      } else {
        // Return to initial.
        targetHeight = widget.initialHeight;
        _isExpanded = false;
        _isFullScreen = false;
      }
    }

    // Animate to the target height.
    _heightAnimation = Tween<double>(
      begin: _currentHeight,
      end: targetHeight,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward(from: 0).then((_) {
      setState(() {
        _currentHeight = targetHeight; // Update current height after animation.
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top; // Get status bar height.

    return AnimatedBuilder(
      animation: _heightAnimation, // Rebuild when the height animation changes.
      builder: (context, child) {
        final height =
            _animationController.isAnimating
                ? _heightAnimation.value // Use animated value during animation.
                : _currentHeight; // Otherwise, use the current height.

        // Calculate if we're in full screen mode.
        final isCurrentlyFullScreen = height >= screenHeight - 10;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200), // Smooth transition.
          height: height, // Set the animated height.
          decoration: BoxDecoration(
            color: AppColors.surface, // Background color.
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(isCurrentlyFullScreen ? 0 : 20), // No rounding in full screen.
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50), // Subtle shadow.
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency, // Make the content transparent.
            child: Column(
              children: [
                // Add safe area padding when full screen.
                if (isCurrentlyFullScreen)
                  Container(height: topPadding, color: AppColors.surface),

                // Drag handle and header.
                GestureDetector(
                  onVerticalDragStart: _handleDragStart, // Start drag gesture.
                  onVerticalDragUpdate: _handleDragUpdate, // Update drag gesture.
                  onVerticalDragEnd: _handleDragEnd, // End drag gesture.
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(isCurrentlyFullScreen ? 0 : 20), // No rounding in full screen.
                      ),
                    ),
                    child: Column(
                      children: [
                        // Drag handle (hide in full screen).
                        if (!isCurrentlyFullScreen)
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.divider,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),

                        // Header with title and action buttons.
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: isCurrentlyFullScreen ? 16 : 12, // Adjust padding for full screen.
                          ),
                          decoration: BoxDecoration(
                            color:
                                isCurrentlyFullScreen
                                    ? AppColors.surfaceLight // Lighter surface in full screen.
                                    : AppColors.surface,
                            border: const Border(
                              bottom: BorderSide(
                                color: AppColors.divider,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Left action button (e.g., cancel).
                              widget.leftAction ??
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed:
                                        widget.onClose ??
                                        () => Navigator.pop(context), // Default close action.
                                    child: Text(
                                      isCurrentlyFullScreen
                                          ? 'Close' // "Close" in full screen.
                                          : 'Cancel', // "Cancel" otherwise.
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),

                              // Title with swipe up indicator.
                              Column(
                                children: [
                                  if (widget.title != null)
                                    Text(
                                      widget.title!, // Display the title.
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  // Show "Swipe up" indicator if not full screen and not expanded.
                                  if (!isCurrentlyFullScreen &&
                                      !_isExpanded) ...[
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withAlpha(20),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            CupertinoIcons.arrow_up, // Up arrow icon.
                                            size: 10,
                                            color: AppColors.accent,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Swipe up',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: AppColors.accent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              // Right action button (e.g., apply).
                              widget.rightAction ?? const SizedBox(width: 60),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Content with proper padding.
                Expanded(
                  child:
                      isCurrentlyFullScreen
                          ? widget.child // No extra padding in full screen.
                          : Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).padding.bottom, // Safe area padding.
                            ),
                            child: widget.child, // The actual content.
                          ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
