import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';

/// Widget to display when no search results are found.
///
/// This widget shows a centered message with an icon to indicate that
/// no tasks match the current search query, along with a helpful
/// suggestion for the user.
class SearchEmptyState extends StatelessWidget {
  const SearchEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.search,
            size: 64,
            color: AppColors.textTertiary,
          ), // Search icon.
          SizedBox(height: 16),
          Text(
            'No tasks found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
