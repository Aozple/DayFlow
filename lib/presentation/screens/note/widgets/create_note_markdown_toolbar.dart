import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The horizontal toolbar for Markdown formatting options.
///
/// This widget provides a set of buttons for inserting common Markdown syntax
/// into the note content, such as bold, italic, headings, lists, links, etc.
/// It's designed to be horizontally scrollable to accommodate all formatting options.
class CreateNoteMarkdownToolbar extends StatelessWidget {
  /// Callback function when a Markdown formatting option is selected.
  final Function(String, String) onInsertMarkdown;

  const CreateNoteMarkdownToolbar({super.key, required this.onInsertMarkdown});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight, // Lighter surface background.
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.divider.withAlpha(50),
          width: 1,
        ), // Subtle border.
      ),
      child: SingleChildScrollView(
        scrollDirection:
            Axis.horizontal, // Allows horizontal scrolling for more buttons.
        physics: const BouncingScrollPhysics(), // iOS-style scroll physics.
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            // Buttons for common Markdown formatting.
            _toolbarButton(
              icon: CupertinoIcons.bold,
              onTap:
                  () => onInsertMarkdown('**', '**'), // Inserts bold markdown.
              tooltip: 'Bold',
            ),
            _toolbarButton(
              icon: CupertinoIcons.italic,
              onTap:
                  () => onInsertMarkdown('*', '*'), // Inserts italic markdown.
              tooltip: 'Italic',
            ),
            _toolbarDivider(), // A visual separator.
            _toolbarButton(
              icon: Icons.title,
              onTap:
                  () => onInsertMarkdown('# ', ''), // Inserts heading markdown.
              tooltip: 'Heading',
            ),
            _toolbarButton(
              icon: CupertinoIcons.list_bullet,
              onTap:
                  () => onInsertMarkdown(
                    '- ',
                    '',
                  ), // Inserts bullet list markdown.
              tooltip: 'Bullet List',
            ),
            _toolbarButton(
              icon: CupertinoIcons.list_number,
              onTap:
                  () => onInsertMarkdown(
                    '1. ',
                    '',
                  ), // Inserts numbered list markdown.
              tooltip: 'Numbered List',
            ),
            _toolbarDivider(),
            _toolbarButton(
              icon: CupertinoIcons.checkmark_square,
              onTap:
                  () => onInsertMarkdown(
                    '- [ ] ',
                    '',
                  ), // Inserts checkbox markdown.
              tooltip: 'Checkbox',
            ),
            _toolbarButton(
              icon: CupertinoIcons.quote_bubble,
              onTap:
                  () => onInsertMarkdown('> ', ''), // Inserts quote markdown.
              tooltip: 'Quote',
            ),
            _toolbarDivider(),
            _toolbarButton(
              icon: CupertinoIcons.link,
              onTap:
                  () => onInsertMarkdown(
                    '[Link](',
                    ')',
                  ), // Inserts link markdown.
              tooltip: 'Link',
            ),
            _toolbarButton(
              icon: CupertinoIcons.photo,
              onTap:
                  () => onInsertMarkdown(
                    '![Image](',
                    ')',
                  ), // Inserts image markdown.
              tooltip: 'Image',
            ),
          ],
        ),
      ),
    );
  }

  /// Helper widget for creating a single toolbar button.
  Widget _toolbarButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip, // Shows a tooltip on long press/hover.
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minSize: 34,
        onPressed: () {
          HapticFeedback.lightImpact(); // Provide haptic feedback on tap.
          onTap(); // Execute the button's action.
        },
        child: Icon(
          icon,
          size: 18,
          color: AppColors.textPrimary,
        ), // Icon with primary text color.
      ),
    );
  }

  /// Helper widget for creating a vertical divider in the toolbar.
  Widget _toolbarDivider() {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppColors.divider, // Divider color.
    );
  }
}
