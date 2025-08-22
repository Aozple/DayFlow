import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

/// The header section of the CreateNoteScreen with blur effect, cancel, and save buttons.
///
/// This widget displays the screen title, action buttons (preview, delete, save),
/// and handles the auto-save status display. It provides visual feedback for
/// unsaved changes and differentiates between create and edit modes.
class CreateNoteHeader extends StatelessWidget {
  /// Whether we are in edit mode (true) or create mode (false).
  final bool isEditMode;

  /// Whether there are unsaved changes in the note.
  final bool hasChanges;

  /// Whether auto-save functionality is enabled.
  final bool autoSaveEnabled;

  /// Whether the preview mode is currently active.
  final bool isPreviewMode;

  /// Callback function when the preview/editor toggle is pressed.
  final VoidCallback onTogglePreview;

  /// Callback function when the delete button is pressed.
  final VoidCallback onDelete;

  /// Callback function when the save/update button is pressed.
  final VoidCallback onSave;

  /// Callback function when the cancel button is pressed.
  final VoidCallback onCancel;

  const CreateNoteHeader({
    super.key,
    required this.isEditMode,
    required this.hasChanges,
    required this.autoSaveEnabled,
    required this.isPreviewMode,
    required this.onTogglePreview,
    required this.onDelete,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 10,
          sigmaY: 10,
        ), // Apply a blur effect.
        child: Container(
          color: AppColors.surface.withAlpha(
            200,
          ), // Semi-transparent background.
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Cancel button, shows discard dialog if there are changes.
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onCancel,
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color:
                        hasChanges
                            ? AppColors.error
                            : AppColors
                                .textSecondary, // Red if changes, gray otherwise.
                    fontSize: 17,
                  ),
                ),
              ),
              // Title of the screen and auto-save status.
              Column(
                children: [
                  Text(
                    isEditMode
                        ? 'Edit Note'
                        : 'New Note', // Title changes based on mode.
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  // Show "Auto-saving..." text if changes exist and auto-save is enabled.
                  if (hasChanges && autoSaveEnabled)
                    Text(
                      'Auto-saving...',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.accent.withAlpha(200),
                      ),
                    ),
                ],
              ),
              // Action buttons (Preview, Delete, Save).
              Row(
                children: [
                  // Preview/Editor toggle button.
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 32,
                    onPressed:
                        onTogglePreview, // Toggles between editor and preview.
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color:
                            isPreviewMode
                                ? AppColors.accent.withAlpha(
                                  30,
                                ) // Highlight if in preview mode.
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isPreviewMode
                            ? CupertinoIcons
                                .pencil // Show pencil icon in preview mode.
                            : CupertinoIcons
                                .eye, // Show eye icon in editor mode.
                        color:
                            isPreviewMode
                                ? AppColors.accent
                                : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete button, only visible in edit mode.
                  if (isEditMode) ...[
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 32,
                      onPressed: onDelete, // Show delete confirmation dialog.
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.error.withAlpha(
                            20,
                          ), // Red background for destructive action.
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          CupertinoIcons.trash, // Trash icon.
                          color: AppColors.error,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const SizedBox(width: 8),
                  // Save/Update button, disabled if title is empty.
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: onSave, // Call save function.
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent, // Accent color.
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isEditMode
                            ? 'Update'
                            : 'Save', // Text changes based on mode.
                        style: const TextStyle(
                          color: Colors.white, // White text.
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
