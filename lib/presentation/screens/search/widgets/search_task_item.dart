import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:dayflow/core/constants/app_colors.dart';
import '../models/search_result.dart';

/// Widget for displaying task search results
class SearchTaskItem extends StatelessWidget {
  final TaskSearchResult result;
  final String searchQuery;
  final VoidCallback onTap;

  const SearchTaskItem({
    super.key,
    required this.result,
    required this.searchQuery,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final taskColor = AppColors.fromHex(result.color);

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
              border: Border(left: BorderSide(color: taskColor, width: 3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Task title with search highlighting
                      RichText(
                        text: _highlightSearchTerm(result.title, searchQuery),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Task description if available
                      if (result.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        RichText(
                          text: _highlightSearchTerm(
                            result.description!,
                            searchQuery,
                            isSecondary: true,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 8),

                      // Task metadata
                      Row(
                        children: [
                          // Due date
                          if (result.dueDate != null) ...[
                            const Icon(
                              CupertinoIcons.calendar,
                              size: 12,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d').format(result.dueDate!),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],

                          // Priority
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.getPriorityColor(
                                result.priority,
                              ).withAlpha(30),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'P${result.priority}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.getPriorityColor(
                                  result.priority,
                                ),
                              ),
                            ),
                          ),

                          // First tag
                          if (result.tags.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              CupertinoIcons.tag,
                              size: 12,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              result.tags.first,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Completion status
                if (result.isCompleted)
                  const Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: AppColors.success,
                    size: 24,
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
