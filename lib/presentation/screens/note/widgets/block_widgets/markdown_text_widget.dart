import 'package:flutter/material.dart';
import 'package:dayflow/core/constants/app_colors.dart';

class MarkdownTextWidget extends StatelessWidget {
  final String text;
  final TextStyle baseStyle;

  const MarkdownTextWidget({
    super.key,
    required this.text,
    required this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(text: _buildTextSpan(text, baseStyle));
  }

  TextSpan _buildTextSpan(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];
    final RegExp markdownRegex = RegExp(
      r'(\*\*[^*]+\*\*)|(\*[^*]+\*)|(<u>[^<]+</u>)|(~~[^~]+~~)|(`[^`]+`)',
    );

    int lastIndex = 0;

    for (final match in markdownRegex.allMatches(text)) {
      // Add text before match
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, match.start),
            style: baseStyle,
          ),
        );
      }

      // Add formatted text
      final matchText = match.group(0)!;
      spans.add(_createFormattedSpan(matchText, baseStyle));

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex), style: baseStyle));
    }

    return TextSpan(children: spans);
  }

  TextSpan _createFormattedSpan(String text, TextStyle baseStyle) {
    if (text.startsWith('**') && text.endsWith('**')) {
      // Bold text
      return TextSpan(
        text: text.substring(2, text.length - 2),
        style: baseStyle.copyWith(fontWeight: FontWeight.bold),
      );
    } else if (text.startsWith('*') && text.endsWith('*')) {
      // Italic text
      return TextSpan(
        text: text.substring(1, text.length - 1),
        style: baseStyle.copyWith(fontStyle: FontStyle.italic),
      );
    } else if (text.startsWith('<u>') && text.endsWith('</u>')) {
      // Underline text
      return TextSpan(
        text: text.substring(3, text.length - 4),
        style: baseStyle.copyWith(decoration: TextDecoration.underline),
      );
    } else if (text.startsWith('~~') && text.endsWith('~~')) {
      // Strikethrough text
      return TextSpan(
        text: text.substring(2, text.length - 2),
        style: baseStyle.copyWith(decoration: TextDecoration.lineThrough),
      );
    } else if (text.startsWith('`') && text.endsWith('`')) {
      // Code text
      return TextSpan(
        text: text.substring(1, text.length - 1),
        style: baseStyle.copyWith(
          fontFamily: 'monospace',
          backgroundColor: AppColors.surfaceLight,
          color: AppColors.accent,
        ),
      );
    }

    return TextSpan(text: text, style: baseStyle);
  }
}
