import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';

/// The Markdown preview display.
///
/// This widget displays the rendered Markdown content of the note, providing
/// a preview of how the note will look when formatted. It includes a header
/// with the preview title and date, and handles empty content with a placeholder.
class CreateNotePreview extends StatelessWidget {
  /// Controller for the content being previewed.
  final TextEditingController contentController;

  /// The selected date for the note.
  final DateTime selectedDate;

  const CreateNotePreview({
    super.key,
    required this.contentController,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('preview'), // Unique key for AnimatedSwitcher.
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface, // Background color.
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Preview header with icon, label, and date.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.divider,
                  width: 0.5,
                ), // Bottom border.
              ),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.eye_fill, // Eye icon.
                  size: 16,
                  color: AppColors.accent, // Accent color.
                ),
                const SizedBox(width: 8),
                Text(
                  'Preview',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.accent,
                  ),
                ),
                const Spacer(),
                // Display the selected date.
                Text(
                  DateFormat('MMM d, yyyy').format(selectedDate),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          // The area displaying the rendered Markdown content.
          Expanded(
            child:
                contentController.text.trim().isEmpty
                    ? const Center(
                      // Show a placeholder if the content is empty.
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.doc_text, // Document icon.
                            size: 48,
                            color: AppColors.textTertiary,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Start writing to see preview',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    )
                    : Markdown(
                      data:
                          contentController
                              .text, // The Markdown text to render.
                      selectable: true, // Allow text selection.
                      physics:
                          const BouncingScrollPhysics(), // iOS-style scroll physics.
                      padding: const EdgeInsets.all(16),
                      styleSheet:
                          _buildMarkdownStyle(), // Custom styles for Markdown elements.
                    ),
          ),
        ],
      ),
    );
  }

  /// Defines the styling for various Markdown elements.
  MarkdownStyleSheet _buildMarkdownStyle() {
    return MarkdownStyleSheet(
      h1: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        height: 1.3,
      ),
      h2: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        height: 1.3,
      ),
      h3: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      ),
      p: const TextStyle(
        fontSize: 16,
        height: 1.6,
        color: AppColors.textPrimary,
      ),
      code: TextStyle(
        backgroundColor: AppColors.surfaceLight,
        fontFamily: 'monospace',
        fontSize: 14,
        color: AppColors.accent,
      ),
      codeblockDecoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider.withAlpha(50), width: 1),
      ),
      blockquote: const TextStyle(
        color: AppColors.textSecondary,
        fontStyle: FontStyle.italic,
        fontSize: 16,
      ),
      blockquoteDecoration: BoxDecoration(
        color: AppColors.accent.withAlpha(10),
        border: Border(left: BorderSide(color: AppColors.accent, width: 4)),
      ),
      listBullet: TextStyle(color: AppColors.accent),
      checkbox: TextStyle(color: AppColors.accent),
      a: TextStyle(
        color: AppColors.accent,
        decoration: TextDecoration.underline,
      ),
      strong: const TextStyle(
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      em: const TextStyle(
        fontStyle: FontStyle.italic,
        color: AppColors.textPrimary,
      ),
    );
  }
}
