import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CreateTaskHeader extends StatelessWidget {
  final bool isEditMode;
  final bool canSave;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const CreateTaskHeader({
    super.key,
    required this.isEditMode,
    required this.canSave,
    required this.onCancel,
    required this.onSave,
  });

  static const double _buttonHeight = 40.0;
  static const double _buttonVerticalPadding = 8.0;
  static const double _buttonHorizontalPadding = 18.0;

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
          _buildTitleSection(),
          _buildSaveButton(context, ),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onCancel,
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
                isEditMode ? 'Edit Task' : 'New Task',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.0,
                ),
              ),
            ],
          ),
          if (!canSave) ...[
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

  Widget _buildSaveButton(BuildContext context, ) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: canSave ? onSave : null,
      child: Container(
        height: _buttonHeight,
        padding: const EdgeInsets.symmetric(
          horizontal: _buttonHorizontalPadding,
          vertical: _buttonVerticalPadding,
        ),
        decoration: BoxDecoration(
          color: canSave ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary.withAlpha(100),
          borderRadius: BorderRadius.circular(8),
          boxShadow: canSave
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withAlpha(50),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            isEditMode ? 'Update' : 'Create',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

