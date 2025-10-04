import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CreateNoteHeader extends StatelessWidget {
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

  static const double _buttonHeight = 40.0;
  static const double _buttonVerticalPadding = 8.0;
  static const double _buttonHorizontalPadding = 18.0;

  bool get _shouldShowStatus {
    return (hasChanges && autoSaveEnabled) || isSaving || isDeleting;
  }

  String get _statusText {
    if (isDeleting) return 'Deleting...';
    if (isSaving) return 'Saving...';
    if (hasChanges && autoSaveEnabled) {
      return 'Auto-saving enabled';
    }
    return '';
  }

  Color _statusColor(BuildContext context) {
    if (isDeleting) return AppColors.error;
    if (isSaving) return Theme.of(context).colorScheme.primary;
    return Theme.of(context).colorScheme.primary.withAlpha(200);
  }

  bool get _canInteract => !isSaving && !isDeleting;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
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
          _buildCancelButton(),
          _buildTitleSection(context),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _canInteract ? onCancel : null,
      child: Container(
        height: _buttonHeight,
        padding: const EdgeInsets.symmetric(
          horizontal: _buttonHorizontalPadding,
          vertical: _buttonVerticalPadding,
        ),
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
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isEditMode ? 'Edit Note' : 'New Note',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.0,
            ),
          ),
          _buildStatusIndicator(context),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    if (!_shouldShowStatus) {
      return const SizedBox.shrink();
    }

    final statusColor = _statusColor(context);

    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSaving || isDeleting) ...[
            SizedBox(
              width: 10,
              height: 10,
              child: CupertinoActivityIndicator(radius: 5, color: statusColor),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            _statusText,
            style: TextStyle(
              fontSize: 11,
              color: statusColor,
              fontWeight: FontWeight.w500,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isEditMode) ...[_buildDeleteButton(), const SizedBox(width: 12)],
        _buildSaveButton(context),
      ],
    );
  }

  Widget _buildDeleteButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _canInteract ? onDelete : null,
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
              if (isDeleting) ...[
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
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _canInteract ? onSave : null,
      child: Container(
        height: _buttonHeight,
        padding: const EdgeInsets.symmetric(
          horizontal: _buttonHorizontalPadding,
          vertical: _buttonVerticalPadding,
        ),
        decoration: BoxDecoration(
          color:
              _canInteract
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.primary.withAlpha(100),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSaving) ...[
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
                isSaving ? 'Saving...' : (isEditMode ? 'Update' : 'Save'),
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
    );
  }
}
