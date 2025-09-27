import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:dayflow/core/constants/app_colors.dart';
import '../models/search_result.dart';

/// Widget for displaying note search results
class SearchNoteItem extends StatelessWidget {
  final TaskSearchResult
  result; // Notes are stored as TaskModel with isNote=true
  final String searchQuery;
  final VoidCallback onTap;

  const SearchNoteItem({
    super.key,
    required this.result,
    required this.searchQuery,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final noteColor = AppColors.fromHex(result.color);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: noteColor, width: 3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Note icon
                    Icon(CupertinoIcons.doc_text, size: 16, color: noteColor),
                    const SizedBox(width: 8),

                    // Note title with search highlighting
                    Expanded(
                      child: RichText(
                        text: _highlightSearchTerm(result.title, searchQuery),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Note content preview
                if (result.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  RichText(
                    text: _highlightSearchTerm(
                      result.description!,
                      searchQuery,
                      isContent: true,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 8),

                // Note metadata
                Row(
                  children: [
                    // Created date
                    const Icon(
                      CupertinoIcons.time,
                      size: 12,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, y').format(result.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),

                    // Tags
                    if (result.tags.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      const Icon(
                        CupertinoIcons.tag,
                        size: 12,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          result.tags.join(', '),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Highlight search terms in text
  TextSpan _highlightSearchTerm(
    String text,
    String query, {
    bool isContent = false,
  }) {
    final baseStyle = TextStyle(
      fontSize: isContent ? 14 : 16,
      fontWeight: isContent ? FontWeight.w400 : FontWeight.w600,
      color: isContent ? AppColors.textSecondary : AppColors.textPrimary,
    );

    if (query.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    final matches = query.toLowerCase();
    final textLower = text.toLowerCase();

    if (!textLower.contains(matches)) {
      return TextSpan(text: text, style: baseStyle);
    }

    final startIndex = textLower.indexOf(matches);
    final endIndex = startIndex + matches.length;

    return TextSpan(
      style: baseStyle,
      children: [
        TextSpan(text: text.substring(0, startIndex)),
        TextSpan(
          text: text.substring(startIndex, endIndex),
          style: TextStyle(
            backgroundColor: AppColors.accent.withAlpha(50),
            color: AppColors.accent,
          ),
        ),
        TextSpan(text: text.substring(endIndex)),
      ],
    );
  }
}
