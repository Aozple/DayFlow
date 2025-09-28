import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
import 'package:dayflow/presentation/blocs/habits/habit_bloc.dart';
import 'package:dayflow/core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';
import '../models/search_result.dart';
import 'search_category_section.dart';

class SearchResultsView extends StatefulWidget {
  final String searchQuery;

  const SearchResultsView({super.key, required this.searchQuery});

  @override
  State<SearchResultsView> createState() => _SearchResultsViewState();
}

class _SearchResultsViewState extends State<SearchResultsView> {
  Map<SearchResultType, List<SearchResult>> _categorizedResults = {};
  final Map<SearchResultType, bool> _expandedStates = {
    SearchResultType.task: false,
    SearchResultType.note: false,
    SearchResultType.habit: false,
  };

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  @override
  void didUpdateWidget(SearchResultsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _performSearch();
    }
  }

  void _performSearch() {
    if (widget.searchQuery.isEmpty) {
      _loadRecentContent();
    } else {
      _searchContent(widget.searchQuery);
    }
  }

  void _loadRecentContent() {
    final taskState = context.read<TaskBloc>().state;
    final habitState = context.read<HabitBloc>().state;

    final allResults = <SearchResult>[];

    if (taskState is TaskLoaded) {
      allResults.addAll(
        taskState.tasks
            .where((task) => !task.isDeleted)
            .take(15)
            .map((task) => TaskSearchResult(task)),
      );
    }

    if (habitState is HabitLoaded) {
      allResults.addAll(
        habitState.habits
            .where((habit) => !habit.isDeleted)
            .take(10)
            .map((habit) => HabitSearchResult(habit)),
      );
    }

    _categorizeAndUpdate(allResults);
  }

  void _searchContent(String query) {
    final taskState = context.read<TaskBloc>().state;
    final habitState = context.read<HabitBloc>().state;

    final results = <SearchResult>[];
    final queryLower = query.toLowerCase();

    if (taskState is TaskLoaded) {
      final matchingTasks = taskState.tasks
          .where((task) {
            if (task.isDeleted) return false;

            return task.title.toLowerCase().contains(queryLower) ||
                (task.description?.toLowerCase().contains(queryLower) ??
                    false) ||
                task.tags.any((tag) => tag.toLowerCase().contains(queryLower));
          })
          .map((task) => TaskSearchResult(task));

      results.addAll(matchingTasks);
    }

    if (habitState is HabitLoaded) {
      final matchingHabits = habitState.habits
          .where((habit) {
            if (habit.isDeleted) return false;

            return habit.title.toLowerCase().contains(queryLower) ||
                (habit.description?.toLowerCase().contains(queryLower) ??
                    false) ||
                habit.tags.any((tag) => tag.toLowerCase().contains(queryLower));
          })
          .map((habit) => HabitSearchResult(habit));

      results.addAll(matchingHabits);
    }

    _categorizeAndUpdate(results);
  }

  void _categorizeAndUpdate(List<SearchResult> results) {
    final categorized = <SearchResultType, List<SearchResult>>{};

    for (final result in results) {
      categorized.putIfAbsent(result.type, () => []).add(result);
    }

    for (final category in categorized.keys) {
      categorized[category]!.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    setState(() {
      _categorizedResults = categorized;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_categorizedResults.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.searchQuery.isNotEmpty) _buildSearchHeader(),
          ..._buildCategorySections(),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    final totalResults = _categorizedResults.values.fold(
      0,
      (sum, list) => sum + list.length,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.divider.withAlpha(30),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              CupertinoIcons.search,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    children: [
                      TextSpan(
                        text: '$totalResults',
                        style:  TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                      const TextSpan(text: ' results found'),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'for "${widget.searchQuery}"',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategorySections() {
    final sections = <Widget>[];
    final orderedTypes = [
      SearchResultType.task,
      SearchResultType.note,
      SearchResultType.habit,
    ];

    for (int i = 0; i < orderedTypes.length; i++) {
      final type = orderedTypes[i];
      final results = _categorizedResults[type];

      if (results != null && results.isNotEmpty) {
        sections.add(
          SearchCategorySection(
            type: type,
            results: results,
            isExpanded: _expandedStates[type]!,
            searchQuery: widget.searchQuery,
            onToggleExpanded: () {
              setState(() {
                _expandedStates[type] = !_expandedStates[type]!;
              });
            },
            onResultTap: _handleResultTap,
          ),
        );

        if (i < orderedTypes.length - 1) {
          sections.add(const SizedBox(height: 12));
        }
      }
    }

    return sections;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.divider.withAlpha(30),
                  width: 0.5,
                ),
              ),
              child: Icon(
                widget.searchQuery.isEmpty
                    ? CupertinoIcons.search
                    : CupertinoIcons.exclamationmark_circle,
                size: 32,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.searchQuery.isEmpty
                  ? 'Start searching'
                  : 'No results found',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.searchQuery.isEmpty
                  ? 'Search across all your tasks, habits, and notes'
                  : 'Try different keywords or check your spelling',
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleResultTap(SearchResult result) {
    switch (result.type) {
      case SearchResultType.task:
        final taskResult = result as TaskSearchResult;
        context.push('/task-details', extra: taskResult.task);
        break;
      case SearchResultType.note:
        final noteResult = result as TaskSearchResult;
        context.push('/edit-note', extra: noteResult.task);
        break;
      case SearchResultType.habit:
        final habitResult = result as HabitSearchResult;
        context.push('/habit-details', extra: habitResult.habit);
        break;
    }
  }
}