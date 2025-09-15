import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../core/constants/app_colors.dart';

// Resizable and draggable modal sheet with iOS-style behavior
class DraggableModal extends StatefulWidget {
  final Widget child;
  final double initialHeight;
  final double minHeight;
  final String? title;
  final VoidCallback? onClose;
  final Widget? leftAction;
  final Widget? rightAction;
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

class _DraggableModalState extends State<DraggableModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;

  double _currentHeight = 0;
  double _dragStartHeight = 0;
  bool _isExpanded = false;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _currentHeight = widget.initialHeight;

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Create height animation
    _heightAnimation = Tween<double>(
      begin: widget.initialHeight,
      end: widget.initialHeight,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Store initial height when drag starts
  void _handleDragStart(DragStartDetails details) {
    _dragStartHeight = _currentHeight;
  }

  // Update height during drag
  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      final screenHeight = MediaQuery.of(context).size.height;
      final maxHeight =
          widget.allowFullScreen ? screenHeight : screenHeight * 0.9;

      _currentHeight = (_dragStartHeight - details.localPosition.dy).clamp(
        widget.minHeight,
        maxHeight,
      );

      _isFullScreen = _currentHeight >= screenHeight - 50;
    });
  }

  // Handle drag end with velocity-based snapping
  void _handleDragEnd(DragEndDetails details) {
    final screenHeight = MediaQuery.of(context).size.height;
    final velocity = details.velocity.pixelsPerSecond.dy;

    double targetHeight;

    if (velocity < -500) {
      // Fast swipe up - expand to fullscreen
      if (widget.allowFullScreen) {
        targetHeight = screenHeight;
        _isFullScreen = true;
      } else {
        targetHeight = screenHeight * 0.9;
      }
      _isExpanded = true;
    } else if (velocity > 500) {
      // Fast swipe down - collapse or dismiss
      if (_isFullScreen) {
        // From full screen to expanded
        targetHeight = screenHeight * 0.75;
        _isFullScreen = false;
        _isExpanded = true;
      } else if (_currentHeight < widget.initialHeight * 0.7) {
        // Dismiss if dragged down significantly
        Navigator.of(context).pop();
        return;
      } else {
        // Return to initial height
        targetHeight = widget.initialHeight;
        _isExpanded = false;
        _isFullScreen = false;
      }
    } else {
      // Slow drag - snap to nearest position
      if (_currentHeight > screenHeight * 0.85) {
        // Near top - go full screen
        targetHeight = screenHeight;
        _isFullScreen = true;
        _isExpanded = true;
      } else if (_currentHeight > screenHeight * 0.6) {
        // More than 60% - expanded
        targetHeight = screenHeight * 0.75;
        _isExpanded = true;
        _isFullScreen = false;
      } else if (_currentHeight < widget.initialHeight * 0.5) {
        // Less than half - dismiss
        Navigator.of(context).pop();
        return;
      } else {
        // Return to initial height
        targetHeight = widget.initialHeight;
        _isExpanded = false;
        _isFullScreen = false;
      }
    }

    // Animate to target height
    _heightAnimation = Tween<double>(
      begin: _currentHeight,
      end: targetHeight,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward(from: 0).then((_) {
      setState(() {
        _currentHeight = targetHeight;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;

    return AnimatedBuilder(
      animation: _heightAnimation,
      builder: (context, child) {
        final height =
            _animationController.isAnimating
                ? _heightAnimation.value
                : _currentHeight;

        final isCurrentlyFullScreen = height >= screenHeight - 10;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: height,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(isCurrentlyFullScreen ? 0 : 20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              children: [
                // Status bar padding in fullscreen mode
                if (isCurrentlyFullScreen)
                  Container(height: topPadding, color: AppColors.surface),

                // Drag handle and header
                GestureDetector(
                  onVerticalDragStart: _handleDragStart,
                  onVerticalDragUpdate: _handleDragUpdate,
                  onVerticalDragEnd: _handleDragEnd,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(isCurrentlyFullScreen ? 0 : 20),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Drag handle (hidden in fullscreen)
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

                        // Header with title and actions
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: isCurrentlyFullScreen ? 16 : 12,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isCurrentlyFullScreen
                                    ? AppColors.surfaceLight
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
                              // Left action (cancel/close)
                              widget.leftAction ??
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed:
                                        widget.onClose ??
                                        () => Navigator.pop(context),
                                    child: Text(
                                      isCurrentlyFullScreen
                                          ? 'Close'
                                          : 'Cancel',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),

                              // Title with swipe indicator
                              Column(
                                children: [
                                  if (widget.title != null)
                                    Text(
                                      widget.title!,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  // "Swipe up" indicator
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
                                            CupertinoIcons.arrow_up,
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

                              // Right action
                              widget.rightAction ?? const SizedBox(width: 60),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Content area
                Expanded(
                  child:
                      isCurrentlyFullScreen
                          ? widget.child
                          : Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).padding.bottom,
                            ),
                            child: widget.child,
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
