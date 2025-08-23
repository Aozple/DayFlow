import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';

/// Header bar with "Cancel", "New Task/Edit Task" title, and "Add/Update" buttons.
///
/// This widget provides a consistent header for the task creation/editing screen,
/// with appropriate button states based on whether the task can be saved.
class CreateTaskHeader extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ClipRect(
      child: Container(
        color: AppColors.surface.withAlpha(200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Button to cancel and go back.
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onCancel,
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.accent, fontSize: 17),
              ),
            ),
            // Title of the screen, changes based on edit or new task mode.
            Text(
              isEditMode ? 'Edit Task' : 'New Task',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            // Button to save or update the task. It's disabled if the title is empty.
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: canSave ? onSave : null,
              child: Text(
                isEditMode ? 'Update' : 'Add',
                style: TextStyle(
                  color: canSave ? AppColors.accent : AppColors.textTertiary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
