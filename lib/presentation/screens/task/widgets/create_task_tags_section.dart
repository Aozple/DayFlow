import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Section for adding tags to the task.
///
/// This widget provides a text input field for entering comma-separated tags,
/// with appropriate styling and an icon.
class CreateTaskTagsSection extends StatelessWidget {
  /// Controller for the tags input field.
  final TextEditingController tagsController;

  const CreateTaskTagsSection({super.key, required this.tagsController});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: tagsController, // Controller for the tags input.
        style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
        decoration: const InputDecoration(
          hintText: 'Add tags (comma separated)', // Placeholder text.
          hintStyle: TextStyle(color: AppColors.textTertiary),
          prefixIcon: Icon(
            CupertinoIcons.tag, // Tag icon.
            color: AppColors.textSecondary,
            size: 22,
          ),
          border: InputBorder.none, // No border for the input field.
          contentPadding: EdgeInsets.all(16),
        ),
      ),
    );
  }
}
