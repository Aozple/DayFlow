import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

class CreateNoteHeader extends StatelessWidget {
  final bool isEditMode;
  final bool hasChanges;
  final bool autoSaveEnabled;
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
            // Cancel button
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onCancel,
              child: Text(
                'Cancel',
                style: TextStyle(
                  color:
                      hasChanges ? AppColors.error : AppColors.textSecondary,
                  fontSize: 17,
                ),
              ),
            ),
            // Title and auto-save status
            Column(
              children: [
                Text(
                  isEditMode ? 'Edit Note' : 'New Note',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                // Show "Auto-saving..." text if changes exist and auto-save is enabled
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
            // Action buttons (removed preview toggle)
            Row(
              children: [
                // Delete button, only visible in edit mode
                if (isEditMode) ...[
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 32,
                    onPressed: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        CupertinoIcons.trash,
                        color: AppColors.error,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                const SizedBox(width: 8),
                // Save/Update button
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onSave,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isEditMode ? 'Update' : 'Save',
                      style: const TextStyle(
                        color: Colors.white,
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
    );
  }
}
