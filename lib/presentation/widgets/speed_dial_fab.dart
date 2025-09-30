import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;
import '../../core/constants/app_colors.dart';

class SpeedDialFab extends StatefulWidget {
  final VoidCallback onCreateTask;
  final VoidCallback onCreateNote;
  final VoidCallback onCreateHabit;

  const SpeedDialFab({
    super.key,
    required this.onCreateTask,
    required this.onCreateNote,
    required this.onCreateHabit,
  });

  @override
  State<SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<SpeedDialFab>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  bool _isOpen = false;
  OverlayEntry? _overlayEntry;
  final GlobalKey _fabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _animationController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
        _insertOverlay();
        _expandController.forward();
      } else {
        _animationController.reverse();
        _expandController.reverse().then((_) {
          _removeOverlay();
        });
      }
    });
  }

  void _insertOverlay() {
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
                Positioned.fill(
                  child: GestureDetector(
                    onTapDown: (_) {
                      if (_isOpen) _toggle();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(color: Colors.transparent),
                  ),
                ),

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

                AnimatedBuilder(
                  animation: _expandAnimation,
                  builder: (context, child) {
                    final animValue = _expandAnimation.value.clamp(0.0, 1.0);
                    return Positioned(
                      right: screenWidth - fabPosition.dx - 54,
                      top: fabPosition.dy - (210 * animValue),
                      child: Opacity(
                        opacity: animValue,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
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
                                  'Habit',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            SizedBox(
                              width: 56,
                              height: 56,
                              child: FloatingActionButton(
                                heroTag: 'habit_fab_overlay',
                                onPressed: () {
                                  _toggle();
                                  widget.onCreateHabit();
                                },
                                backgroundColor: AppColors.info,
                                elevation: 4,
                                child: const Icon(
                                  CupertinoIcons.repeat,
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

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      key: _fabKey,
      heroTag: 'main_fab',
      onPressed: _toggle,
      backgroundColor: AppColors.accent,
      elevation: 8,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
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
