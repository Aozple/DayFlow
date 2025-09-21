import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Header widget for note creation and editing screen.
///
/// Handles navigation, save/delete actions, and provides visual feedback
/// for auto-save status, loading states, and form changes.
class CreateNoteHeader extends StatefulWidget {
  final bool isEditMode;
  final bool hasChanges;
  final bool autoSaveEnabled;
  final bool isSaving;
  final bool isDeleting;
  final VoidCallback onDelete;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const CreateNoteHeader({
    super.key,
    required this.isEditMode,
    required this.hasChanges,
    required this.autoSaveEnabled,
    required this.onDelete,
    required this.onSave,
    required this.onCancel,
    this.isSaving = false,
    this.isDeleting = false,
  });

  @override
  State<CreateNoteHeader> createState() => _CreateNoteHeaderState();
}

class _CreateNoteHeaderState extends State<CreateNoteHeader>
    with TickerProviderStateMixin {
  late AnimationController _saveAnimationController;
  late AnimationController _statusAnimationController;
  late Animation<double> _statusFadeAnimation;

  // Button dimensions
  static const double _buttonHeight = 40.0;
  static const double _buttonVerticalPadding = 8.0;
  static const double _buttonHorizontalPadding = 18.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _saveAnimationController.dispose();
    _statusAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CreateNoteHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleStateChanges(oldWidget);
  }

  /// Initialize animation controllers and animations
  void _initializeAnimations() {
    _saveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _statusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _statusFadeAnimation = CurvedAnimation(
      parent: _statusAnimationController,
      curve: Curves.easeInOut,
    );
  }

  /// Handle state changes and trigger appropriate animations
  void _handleStateChanges(CreateNoteHeader oldWidget) {
    // Animate save button when saving state changes
    if (widget.isSaving != oldWidget.isSaving) {
      if (widget.isSaving) {
        _saveAnimationController.forward();
      } else {
        _saveAnimationController.reverse();
      }
    }

    // Animate status text when auto-save state changes
    if (widget.hasChanges != oldWidget.hasChanges ||
        widget.isSaving != oldWidget.isSaving) {
      if (_shouldShowStatus) {
        _statusAnimationController.forward();
      } else {
        _statusAnimationController.reverse();
      }
    }
  }

  /// Determine if status indicator should be visible
  bool get _shouldShowStatus {
    return (widget.hasChanges && widget.autoSaveEnabled) ||
        widget.isSaving ||
        widget.isDeleting;
  }

  /// Get appropriate status text based on current state
  String get _statusText {
    if (widget.isDeleting) return 'Deleting...';
    if (widget.isSaving) return 'Saving...';
    if (widget.hasChanges && widget.autoSaveEnabled) {
      return 'Auto-saving enabled';
    }
    return '';
  }

  /// Get appropriate status color based on current state
  Color get _statusColor {
    if (widget.isDeleting) return AppColors.error;
    if (widget.isSaving) return AppColors.accent;
    return AppColors.accent.withAlpha(200);
  }

  /// Check if user interactions should be enabled
  bool get _canInteract => !widget.isSaving && !widget.isDeleting;

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
          // Cancel button with state-aware styling
          _buildCancelButton(),

          // Title and status section
          _buildTitleSection(),

          // Action buttons section
          _buildActionButtons(),
        ],
      ),
    );
  }

  /// Build cancel button with enhanced visual feedback
  Widget _buildCancelButton() {
    return AnimatedOpacity(
      opacity: _canInteract ? 1.0 : 0.6,
      duration: const Duration(milliseconds: 200),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _canInteract ? widget.onCancel : null,
        child: Container(
          height: _buttonHeight,
          padding: const EdgeInsets.symmetric(
            horizontal: _buttonHorizontalPadding,
            vertical: _buttonVerticalPadding,
          ),
          decoration: BoxDecoration(
            color:
                widget.hasChanges
                    ? AppColors.error.withAlpha(25)
                    : AppColors.textSecondary.withAlpha(10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  widget.hasChanges
                      ? AppColors.error.withAlpha(40)
                      : AppColors.textSecondary.withAlpha(30),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              'Cancel',
              style: TextStyle(
                color:
                    widget.hasChanges
                        ? AppColors.error
                        : AppColors.textSecondary,
                fontSize: 15,
                fontWeight:
                    widget.hasChanges ? FontWeight.w600 : FontWeight.w500,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build title section with animated status indicator
  Widget _buildTitleSection() {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main title
          Text(
            widget.isEditMode ? 'Edit Note' : 'New Note',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.0,
            ),
          ),

          // Animated status indicator
          _buildStatusIndicator(),
        ],
      ),
    );
  }

  /// Build animated status indicator with loading states
  Widget _buildStatusIndicator() {
    return AnimatedBuilder(
      animation: _statusFadeAnimation,
      builder: (context, child) {
        if (!_shouldShowStatus && _statusFadeAnimation.value == 0) {
          return const SizedBox.shrink();
        }

        return FadeTransition(
          opacity: _statusFadeAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.5),
              end: Offset.zero,
            ).animate(_statusFadeAnimation),
            child: Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor.withAlpha(10),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Loading indicator for active states
                  if (widget.isSaving || widget.isDeleting) ...[
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: CupertinoActivityIndicator(
                        radius: 5,
                        color: _statusColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    _statusText,
                    style: TextStyle(
                      fontSize: 11,
                      color: _statusColor,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build action buttons section (delete + save)
  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Delete button (only visible in edit mode)
        if (widget.isEditMode) ...[
          _buildDeleteButton(),
          const SizedBox(width: 12),
        ],

        // Save button
        _buildSaveButton(),
      ],
    );
  }

  /// Build delete button with loading state
  Widget _buildDeleteButton() {
    return AnimatedOpacity(
      opacity: _canInteract ? 1.0 : 0.6,
      duration: const Duration(milliseconds: 200),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _canInteract ? widget.onDelete : null,
        child: Container(
          height: _buttonHeight,
          padding: const EdgeInsets.symmetric(
            horizontal: _buttonHorizontalPadding,
            vertical: _buttonVerticalPadding,
          ),
          decoration: BoxDecoration(
            color:
                _canInteract ? AppColors.error : AppColors.error.withAlpha(100),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isDeleting) ...[
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CupertinoActivityIndicator(
                      radius: 7,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                const Icon(CupertinoIcons.trash, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build save button with loading state and dynamic text
  Widget _buildSaveButton() {
    return AnimatedOpacity(
      opacity: _canInteract ? 1.0 : 0.6,
      duration: const Duration(milliseconds: 200),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _canInteract ? widget.onSave : null,
        child: Container(
          height: _buttonHeight,
          padding: const EdgeInsets.symmetric(
            horizontal: _buttonHorizontalPadding,
            vertical: _buttonVerticalPadding,
          ),
          decoration: BoxDecoration(
            color:
                _canInteract
                    ? AppColors.accent
                    : AppColors.accent.withAlpha(100),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isSaving) ...[
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CupertinoActivityIndicator(
                      radius: 7,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  widget.isSaving
                      ? 'Saving...'
                      : (widget.isEditMode ? 'Update' : 'Save'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
