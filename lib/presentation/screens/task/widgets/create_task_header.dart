import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Header widget for task creation and editing screen.
///
/// Provides navigation controls and visual feedback based on form validity.
/// Features a pulsing animation on the save button when enabled and
/// visual indicators for required fields.
class CreateTaskHeader extends StatefulWidget {
  /// Whether we are in edit mode.
  final bool isEditMode;

  /// Whether the task can be saved (i.e., if the title is not empty).
  final bool canSave;

  /// Callback function when the cancel button is pressed.
  final VoidCallback onCancel;

  /// Callback function when the save button is pressed.
  final VoidCallback onSave;

  const CreateTaskHeader({
    super.key,
    required this.isEditMode,
    required this.canSave,
    required this.onCancel,
    required this.onSave,
  });

  @override
  State<CreateTaskHeader> createState() => _CreateTaskHeaderState();
}

class _CreateTaskHeaderState extends State<CreateTaskHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Button dimensions
  static const double _buttonHeight = 40.0;
  static const double _buttonVerticalPadding = 8.0;
  static const double _buttonHorizontalPadding = 18.0;

  @override
  void initState() {
    super.initState();
    _initializePulseAnimation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Initialize pulse animation for save button when enabled
  void _initializePulseAnimation() {
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
          // Cancel button with error styling
          _buildCancelButton(),

          // Header title with validation status
          _buildTitleSection(),

          // Save button with pulse animation
          _buildSaveButton(),
        ],
      ),
    );
  }

  /// Build cancel button with error styling to indicate data loss
  Widget _buildCancelButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: widget.onCancel,
      child: Container(
        height: _buttonHeight,
        padding: const EdgeInsets.symmetric(
          horizontal: _buttonHorizontalPadding,
          vertical: _buttonVerticalPadding,
        ),
        decoration: BoxDecoration(
          color: AppColors.error.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.error.withAlpha(40), width: 1),
        ),
        child: const Center(
          child: Text(
            'Cancel',
            style: TextStyle(
              color: AppColors.error,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  /// Build title section with task icon and validation indicator
  Widget _buildTitleSection() {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.checkmark_circle,
                color: AppColors.info,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                widget.isEditMode ? 'Edit Task' : 'New Task',
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(20),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Title required',
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
    );
  }

  /// Build save button with pulse animation and dynamic styling
  Widget _buildSaveButton() {
    return AnimatedBuilder(
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
                height: _buttonHeight,
                padding: const EdgeInsets.symmetric(
                  horizontal: _buttonHorizontalPadding,
                  vertical: _buttonVerticalPadding,
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
    );
  }
}
