import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The Markdown editor text field.
///
/// This widget provides a text area for editing Markdown content, with a header
/// showing the editor title and word count. It's designed to expand to fill
/// available space and provides helpful hints for Markdown syntax.
class CreateNoteEditor extends StatelessWidget {
  /// Controller for the content editor text field.
  final TextEditingController contentController;

  /// Focus node for the content editor text field.
  final FocusNode contentFocus;

  /// Scroll controller for the content editor.
  final ScrollController scrollController;

  const CreateNoteEditor({
    super.key,
    required this.contentController,
    required this.contentFocus,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('editor'), // Unique key for AnimatedSwitcher.
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface, // Background color.
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Editor header with icon, label, and optional word count.
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
                const Icon(
                  CupertinoIcons.pencil_circle, // Pencil icon.
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Markdown Editor',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                // Display word count if content is not empty.
                if (contentController.text.isNotEmpty)
                  Text(
                    '${_getWordCount()} words',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          // The main text field for Markdown content.
          Expanded(
            child: TextField(
              controller: contentController,
              focusNode: contentFocus,
              maxLines: null, // Allows unlimited lines.
              expands:
                  true, // Makes the text field expand to fill available height.
              textAlignVertical:
                  TextAlignVertical.top, // Align text to the top.
              style: const TextStyle(
                fontSize: 16,
                height: 1.6, // Line height for readability.
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText:
                    _getEditorHint(), // Provides helpful Markdown syntax hints.
                hintStyle: const TextStyle(
                  color: AppColors.textTertiary,
                  height: 1.6,
                ),
                border: InputBorder.none, // No border.
                contentPadding: const EdgeInsets.all(16),
              ),
              scrollController:
                  scrollController, // Link to our scroll controller.
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to provide a hint text for the Markdown editor.
  String _getEditorHint() {
    return '''Start writing your note...
You can use Markdown syntax:
# Heading
**Bold** *Italic*
- Lists
- [ ] Checkboxes
> Quotes
[Links](url) and more!''';
  }

  /// Calculates the number of words in the content.
  int _getWordCount() {
    return contentController.text
        .trim()
        .split(RegExp(r'\s+')) // Split by one or more whitespace characters.
        .where((word) => word.isNotEmpty) // Filter out empty strings.
        .length;
  }
}
