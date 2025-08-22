import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// A floating widget to display word and character counts.
///
/// This widget displays the current word and character count of the note content
/// in a floating container that appears in the bottom-right corner of the editor.
/// It fades in and out based on whether there is content in the editor.
class CreateNoteWordCount extends StatelessWidget {
  /// Controller for the content being counted.
  final TextEditingController contentController;

  const CreateNoteWordCount({super.key, required this.contentController});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: AnimatedOpacity(
        opacity:
            contentController.text.isNotEmpty
                ? 1.0
                : 0.0, // Fade in/out based on content.
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface.withAlpha(
              200,
            ), // Semi-transparent background.
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.divider.withAlpha(100),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.background.withAlpha(100), // Subtle shadow.
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            '${_getWordCount()} words • ${_getCharCount()} chars', // Display counts.
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  /// Calculates the number of words in the content.
  int _getWordCount() {
    return contentController.text
        .trim()
        .split(RegExp(r'\s+')) // Split by one or more whitespace characters.
        .where((word) => word.isNotEmpty) // Filter out empty strings.
        .length;
  }

  /// Calculates the number of characters in the content.
  int _getCharCount() {
    return contentController.text.length;
  }
}
