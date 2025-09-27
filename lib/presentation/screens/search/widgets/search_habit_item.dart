import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:dayflow/core/constants/app_colors.dart';
import '../models/search_result.dart';

/// Widget for displaying habit search results
class SearchHabitItem extends StatelessWidget {
  final HabitSearchResult result;
  final String searchQuery;
  final VoidCallback onTap;

  const SearchHabitItem({
    super.key,
    required this.result,
    required this.searchQuery,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final habitColor = AppColors.fromHex(result.color);

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
              border: Border(left: BorderSide(color: habitColor, width: 3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Habit icon
                    Icon(CupertinoIcons.repeat, size: 16, color: habitColor),
                    const SizedBox(width: 8),

                    // Habit title with search highlighting
                    Expanded(
                      child: RichText(
                        text: _highlightSearchTerm(result.title, searchQuery),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Active/Inactive status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            result.isActive
                                ? AppColors.success.withAlpha(30)
                                : AppColors.textTertiary.withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        result.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color:
                              result.isActive
                                  ? AppColors.success
                                  : AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),

                // Habit description if available
                if (result.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  RichText(
                    text: _highlightSearchTerm(
                      result.description!,
                      searchQuery,
                      isSecondary: true,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 8),

                // Habit metadata
                Row(
                  children: [
                    // Frequency
                    const Icon(
                      CupertinoIcons.clock,
                      size: 12,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      result.frequencyLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Current streak
                    const Icon(
                      CupertinoIcons.flame,
                      size: 12,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${result.currentStreak} day streak',
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
    bool isSecondary = false,
  }) {
    final baseStyle = TextStyle(
      fontSize: isSecondary ? 14 : 16,
      fontWeight: isSecondary ? FontWeight.w400 : FontWeight.w600,
      color: isSecondary ? AppColors.textSecondary : AppColors.textPrimary,
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
