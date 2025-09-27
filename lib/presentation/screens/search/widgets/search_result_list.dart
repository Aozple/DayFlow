import 'package:flutter/material.dart';
import '../models/search_result.dart';
import 'search_task_item.dart';
import 'search_note_item.dart';
import 'search_habit_item.dart';
import 'search_header.dart';

/// Displays a list of search results grouped by type
class SearchResultList extends StatelessWidget {
  final List<SearchResult> results;
  final String searchQuery;
  final bool showCategories;
  final Function(SearchResult) onResultTap;

  const SearchResultList({
    super.key,
    required this.results,
    required this.searchQuery,
    required this.showCategories,
    required this.onResultTap,
  });

  @override
  Widget build(BuildContext context) {
    if (showCategories) {
      return _buildCategorizedResults();
    } else {
      return _buildFlatResults();
    }
  }

  /// Build results grouped by category
  Widget _buildCategorizedResults() {
    // Group results by type
    final Map<SearchResultType, List<SearchResult>> groupedResults = {};
    for (final result in results) {
      groupedResults.putIfAbsent(result.type, () => []).add(result);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Tasks section
        if (groupedResults[SearchResultType.task]?.isNotEmpty == true) ...[
          SearchHeader(
            title: 'Tasks',
            count: groupedResults[SearchResultType.task]!.length,
          ),
          const SizedBox(height: 8),
          ...groupedResults[SearchResultType.task]!.map(
            (result) => _buildResultItem(result as TaskSearchResult),
          ),
          const SizedBox(height: 16),
        ],

        // Notes section
        if (groupedResults[SearchResultType.note]?.isNotEmpty == true) ...[
          SearchHeader(
            title: 'Notes',
            count: groupedResults[SearchResultType.note]!.length,
          ),
          const SizedBox(height: 8),
          ...groupedResults[SearchResultType.note]!.map(
            (result) => _buildResultItem(result as TaskSearchResult),
          ),
          const SizedBox(height: 16),
        ],

        // Habits section
        if (groupedResults[SearchResultType.habit]?.isNotEmpty == true) ...[
          SearchHeader(
            title: 'Habits',
            count: groupedResults[SearchResultType.habit]!.length,
          ),
          const SizedBox(height: 8),
          ...groupedResults[SearchResultType.habit]!.map(
            (result) => _buildResultItem(result as HabitSearchResult),
          ),
        ],
      ],
    );
  }

  /// Build flat list of results
  Widget _buildFlatResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        return _buildResultItem(results[index]);
      },
    );
  }

  /// Build appropriate widget for each result type
  Widget _buildResultItem(SearchResult result) {
    switch (result.type) {
      case SearchResultType.task:
        return SearchTaskItem(
          result: result as TaskSearchResult,
          searchQuery: searchQuery,
          onTap: () => onResultTap(result),
        );
      case SearchResultType.note:
        return SearchNoteItem(
          result: result as TaskSearchResult,
          searchQuery: searchQuery,
          onTap: () => onResultTap(result),
        );
      case SearchResultType.habit:
        return SearchHabitItem(
          result: result as HabitSearchResult,
          searchQuery: searchQuery,
          onTap: () => onResultTap(result),
        );
    }
  }
}
