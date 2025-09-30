import 'package:flutter/material.dart';
import 'package:dayflow/core/constants/app_colors.dart';

class MarkdownTextWidget extends StatelessWidget {
  final String text;
  final TextStyle baseStyle;
  final TextDirection? textDirection;

  const MarkdownTextWidget({
    super.key,
    required this.text,
    required this.baseStyle,
    this.textDirection,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: _buildTextSpan(text, baseStyle),
      textDirection: textDirection,
    );
  }

  TextSpan _buildTextSpan(String text, TextStyle baseStyle) {
    final List<InlineSpan> spans = [];

    final RegExp markdownRegex = RegExp(
      r'(\*\*\*[^*]+\*\*\*)|'
      r'(\*\*[^*]+\*\*)|'
      r'(\*[^*]+\*)|'
      r'(<u>[^<]+</u>)|'
      r'(~~[^~]+~~)|'
      r'(`[^`]+`)|'
      r'(```math[^```]+```KATEX_INLINE_OPEN[^)]+KATEX_INLINE_CLOSE)|'
      r'(#{1,6}\s[^\n]+)|'
      r'(>\s[^\n]+)',
      multiLine: true,
    );

    int lastIndex = 0;

    for (final match in markdownRegex.allMatches(text)) {
      if (match.start > lastIndex) {
        final plainText = text.substring(lastIndex, match.start);
        if (plainText.isNotEmpty) {
          spans.add(TextSpan(text: plainText, style: baseStyle));
        }
      }

      final matchText = match.group(0)!;
      spans.add(_createFormattedSpan(matchText, baseStyle));

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      final remainingText = text.substring(lastIndex);
      if (remainingText.isNotEmpty) {
        spans.add(TextSpan(text: remainingText, style: baseStyle));
      }
    }

    return TextSpan(children: spans, style: baseStyle);
  }

  InlineSpan _createFormattedSpan(String text, TextStyle baseStyle) {
    if (text.startsWith('***') && text.endsWith('***')) {
      return TextSpan(
        text: text.substring(3, text.length - 3),
        style: baseStyle.copyWith(
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
        ),
      );
    } else if (text.startsWith('**') && text.endsWith('**')) {
      return TextSpan(
        text: text.substring(2, text.length - 2),
        style: baseStyle.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      );
    } else if (text.startsWith('*') && text.endsWith('*')) {
      return TextSpan(
        text: text.substring(1, text.length - 1),
        style: baseStyle.copyWith(
          fontStyle: FontStyle.italic,
          letterSpacing: 0.1,
        ),
      );
    } else if (text.startsWith('<u>') && text.endsWith('</u>')) {
      return TextSpan(
        text: text.substring(3, text.length - 4),
        style: baseStyle.copyWith(
          decoration: TextDecoration.underline,
          decorationColor: baseStyle.color?.withAlpha(180),
          decorationThickness: 1.5,
        ),
      );
    } else if (text.startsWith('~~') && text.endsWith('~~')) {
      return TextSpan(
        text: text.substring(2, text.length - 2),
        style: baseStyle.copyWith(
          decoration: TextDecoration.lineThrough,
          decorationColor: AppColors.textTertiary,
          decorationThickness: 2,
          color: baseStyle.color?.withAlpha(150),
        ),
      );
    } else if (text.startsWith('`') && text.endsWith('`')) {
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surface.withAlpha(80),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppColors.divider.withAlpha(40),
              width: 0.5,
            ),
          ),
          child: Text(
            text.substring(1, text.length - 1),
            style: baseStyle.copyWith(
              fontFamily: 'monospace',
              fontSize: baseStyle.fontSize! * 0.85,
              color: AppColors.accent,
              letterSpacing: 0,
            ),
          ),
        ),
      );
    } else if (text.contains('](')) {
      final linkRegex = RegExp(
        r'```math([^```]+)```KATEX_INLINE_OPEN([^)]+)KATEX_INLINE_CLOSE',
      );
      final linkMatch = linkRegex.firstMatch(text);

      if (linkMatch != null) {
        final linkText = linkMatch.group(1)!;
        final linkUrl = linkMatch.group(2)!;

        return WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            onTap: () {
              debugPrint('Link tapped: $linkUrl');
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Text(
                  linkText,
                  style: baseStyle.copyWith(
                    color: AppColors.accent,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.accent.withAlpha(100),
                    decorationStyle: TextDecorationStyle.dotted,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    } else if (text.startsWith('#')) {
      final headerMatch = RegExp(r'^(#{1,6})\s(.+)$').firstMatch(text);
      if (headerMatch != null) {
        final level = headerMatch.group(1)!.length;
        final headerText = headerMatch.group(2)!;

        return TextSpan(
          text: headerText,
          style: baseStyle.copyWith(
            fontSize: baseStyle.fontSize! + (7 - level) * 2,
            fontWeight: FontWeight.values[8 - level],
            height: 1.4,
          ),
        );
      }
    } else if (text.startsWith('> ')) {
      return WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: AppColors.accent.withAlpha(100),
                width: 3,
              ),
            ),
          ),
          child: Text(
            text.substring(2),
            style: baseStyle.copyWith(
              fontStyle: FontStyle.italic,
              color: baseStyle.color?.withAlpha(200),
            ),
          ),
        ),
      );
    }

    return TextSpan(text: text, style: baseStyle);
  }
}
