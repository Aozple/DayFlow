import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Header widget for habit creation and editing screen.
///
/// Provides navigation controls and visual feedback based on form validity.
/// Features a pulsing animation on the save button when enabled.
class CreateHabitHeader extends StatefulWidget {
  final bool isEditMode;
  final bool canSave;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const CreateHabitHeader({
    super.key,
    required this.isEditMode,
    required this.canSave,
    required this.onCancel,
    required this.onSave,
  });

  @override
  State<CreateHabitHeader> createState() => _CreateHabitHeaderState();
}

class _CreateHabitHeaderState extends State<CreateHabitHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize pulse animation for save button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(200),
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider.withAlpha(30),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Cancel button
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: widget.onCancel,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withAlpha(10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.textSecondary.withAlpha(30),
                  width: 1,
                ),
              ),
              child: const Center(
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),

          // Header title with status indicator
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.repeat,
                      color: AppColors.info,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.isEditMode ? 'Edit Habit' : 'New Habit',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
                // Validation warning indicator
                if (!widget.canSave) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withAlpha(20),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Fill required fields',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Save button with pulse animation
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.canSave ? _pulseAnimation.value : 1.0,
                child: AnimatedOpacity(
                  opacity: widget.canSave ? 1.0 : 0.6,
                  duration: const Duration(milliseconds: 200),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: widget.canSave ? widget.onSave : null,
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            widget.canSave
                                ? AppColors.accent
                                : AppColors.accent.withAlpha(100),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow:
                            widget.canSave
                                ? [
                                  BoxShadow(
                                    color: AppColors.accent.withAlpha(50),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                                : null,
                      ),
                      child: Center(
                        child: Text(
                          widget.isEditMode ? 'Update' : 'Create',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
