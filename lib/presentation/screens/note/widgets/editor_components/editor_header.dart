import 'package:flutter/material.dart';
import 'package:dayflow/core/constants/app_colors.dart';

class EditorHeader extends StatelessWidget {
  final VoidCallback onAddBlock;

  const EditorHeader({super.key, required this.onAddBlock});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Editor title with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.edit_note_rounded,
                  size: 20,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Content Editor',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Create rich content with blocks',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // Quick add button
          Container(
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: onAddBlock,
              icon: Icon(
                Icons.add_circle_outline,
                size: 22,
                color: AppColors.accent,
              ),
              tooltip: 'Add Block',
            ),
          ),
        ],
      ),
    );
  }
}
