import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Header widget for the "All Tasks" section in search suggestions.
///
/// This widget displays a title when showing all tasks in the search suggestions
/// (when the search query is empty). It provides a clear visual indication
/// that the user is viewing all available tasks.
class SearchSuggestionsHeader extends StatelessWidget {
  const SearchSuggestionsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Text(
        'All Tasks',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
