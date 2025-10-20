import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../core/constants/app_colors.dart';

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

  @override
  void initState() {
    super.initState();
    _currentHeight = widget.initialHeight;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

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

  void _handleDragStart(DragStartDetails details) {
    _dragStartHeight = _currentHeight;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      final screenHeight = MediaQuery.of(context).size.height;
      final maxHeight =
          widget.allowFullScreen ? screenHeight : screenHeight * 0.9;

      _currentHeight = (_dragStartHeight - details.localPosition.dy).clamp(
        widget.minHeight,
        maxHeight,
      );
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final screenHeight = MediaQuery.of(context).size.height;
    final velocity = details.velocity.pixelsPerSecond.dy;
    final startHeight = _currentHeight;

    double targetHeight;

    if (velocity < -500) {
      targetHeight = widget.allowFullScreen ? screenHeight : screenHeight * 0.9;
    } else if (velocity > 500) {
      if (startHeight >= screenHeight - 50) {
        targetHeight = screenHeight * 0.75;
      } else if (_currentHeight < widget.initialHeight * 0.7) {
        Navigator.of(context).pop();
        return;
      } else {
        targetHeight = widget.initialHeight;
      }
    } else {
      if (startHeight > screenHeight * 0.85) {
        targetHeight = screenHeight;
      } else if (startHeight > screenHeight * 0.6) {
        targetHeight = screenHeight * 0.75;
      } else if (startHeight < widget.initialHeight * 0.5) {
        Navigator.of(context).pop();
        return;
      } else {
        targetHeight = widget.initialHeight;
      }
    }

    _heightAnimation = Tween<double>(
      begin: startHeight,
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
    final topPadding = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _heightAnimation,
      builder: (context, child) {
        final height =
            _animationController.isAnimating
                ? _heightAnimation.value
                : _currentHeight;

        final isCurrentlyFullScreen = height >= screenHeight - 16;

        return Material(
          type: MaterialType.transparency,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(isCurrentlyFullScreen ? 0 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.196),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(isCurrentlyFullScreen, topPadding),
                Expanded(
                  child: SafeArea(
                    top: false,
                    bottom: true,
                    left: false,
                    right: false,
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

  Widget _buildHeader(bool isCurrentlyFullScreen, double topPadding) {
    return GestureDetector(
      onVerticalDragStart: _handleDragStart,
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      behavior: HitTestBehavior.translucent,
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isCurrentlyFullScreen ? 0 : 20),
        ),
        child: Column(
          children: [
            if (!isCurrentlyFullScreen)
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            Padding(
              padding: EdgeInsets.only(
                top: isCurrentlyFullScreen ? topPadding : 0.0,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color:
                      isCurrentlyFullScreen
                          ? AppColors.surfaceLight
                          : AppColors.surface,
                  border: const Border(
                    bottom: BorderSide(color: AppColors.divider, width: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    widget.leftAction ??
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed:
                              widget.onClose ?? () => Navigator.pop(context),
                          child: Text(
                            isCurrentlyFullScreen ? 'Close' : 'Cancel',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                    if (widget.title != null)
                      Text(
                        widget.title!,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    widget.rightAction ?? const SizedBox(width: 60),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
