import 'package:flutter/cupertino.dart';
import 'package:dayflow/core/constants/app_colors.dart';

/// Widget to display when no search results are found
class SearchEmptyState extends StatelessWidget {
  final String? customMessage;

  const SearchEmptyState({super.key, this.customMessage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Search icon
            const Icon(
              CupertinoIcons.search,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),

            // Main message
            Text(
              customMessage ?? 'No results found',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Help text
            const Text(
              'Try searching for:\n• Task or note titles\n• Habit names\n• Tags and descriptions',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
