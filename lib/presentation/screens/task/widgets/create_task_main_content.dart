import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Main content section including title and description input fields.
///
/// This widget provides input fields for the task title and description,
/// with appropriate styling and focus management.
class CreateTaskMainContent extends StatelessWidget {
  /// Controller for the title input field.
  final TextEditingController titleController;

  /// Controller for the description input field.
  final TextEditingController descriptionController;

  /// Focus node for the title input field.
  final FocusNode titleFocus;

  /// Focus node for the description input field.
  final FocusNode descriptionFocus;

  /// Callback function when the content changes.
  final VoidCallback onChanged;

  const CreateTaskMainContent({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.titleFocus,
    required this.descriptionFocus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Text field for the task title.
          TextField(
            controller: titleController,
            focusNode: titleFocus,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: 'Task title',
              hintStyle: TextStyle(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.normal,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            textCapitalization: TextCapitalization.sentences,
            onChanged:
                (_) => onChanged(), // Rebuild to update save button state.
          ),
          // A thin divider line.
          Container(
            height: 0.5,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: AppColors.divider,
          ),
          // Text field for the task description.
          TextField(
            controller: descriptionController,
            focusNode: descriptionFocus,
            style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Add description',
              hintStyle: TextStyle(color: AppColors.textTertiary),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 3, // Allows up to 3 lines before scrolling.
            minLines: 1, // Starts with at least 1 line.
          ),
        ],
      ),
    );
  }
}
