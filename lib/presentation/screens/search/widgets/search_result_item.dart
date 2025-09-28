import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dayflow/presentation/screens/home/widgets/blocks/home_habit_block.dart';
import 'package:dayflow/presentation/screens/home/widgets/blocks/home_task_block.dart';
import 'package:dayflow/presentation/screens/home/widgets/blocks/home_note_block.dart';
import 'package:dayflow/core/constants/app_colors.dart';
import '../models/search_result.dart';

class SearchResultItem extends StatelessWidget {
  final SearchResult result;
  final String searchQuery;
  final VoidCallback onTap;

  const SearchResultItem({
    super.key,
    required this.result,
    required this.searchQuery,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.divider.withAlpha(40),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _buildResultContent(),
        ),
      ),
    );
  }

  Widget _buildResultContent() {
    switch (result.type) {
      case SearchResultType.task:
        final taskResult = result as TaskSearchResult;
        return HomeTaskBlock(
          task: taskResult.task,
          onToggleComplete: (_) {},
          onOptions: (_) {},
        );

      case SearchResultType.note:
        final noteResult = result as TaskSearchResult;
        return HomeNoteBlock(note: noteResult.task, onOptions: (_) {});

      case SearchResultType.habit:
        final habitResult = result as HabitSearchResult;
        return HomeHabitBlock(
          habit: habitResult.habit,
          instance: null,
          selectedDate: DateTime.now(),
          onComplete: (_) {},
          onUncomplete: (_) {},
          onUpdateInstance: (_) {},
          onOptions: (_) {},
        );
    }
  }
}