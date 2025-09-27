import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
import 'package:dayflow/presentation/blocs/habits/habit_bloc.dart';
import 'package:dayflow/core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'models/search_result.dart';
import 'widgets/search_empty_state.dart';
import 'widgets/search_result_list.dart';
import 'widgets/search_header.dart';

/// Universal search delegate for all app content (tasks, notes, habits)
class UniversalSearchDelegate extends SearchDelegate<void> {
  UniversalSearchDelegate()
    : super(
        searchFieldLabel: 'Search tasks, notes, habits...',
        keyboardType: TextInputType.text,
      );

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: AppColors.textSecondary),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(
            CupertinoIcons.clear_circled_solid,
            color: AppColors.textSecondary,
          ),
          onPressed: () {
            query = '';
            _clearAllFilters(context);
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(CupertinoIcons.back, color: AppColors.textPrimary),
      onPressed: () {
        _clearAllFilters(context);
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Trigger search in all BLoCs
    if (query.isNotEmpty) {
      _triggerSearch(context, query);
    }

    return _buildSearchContent(context, showCategories: true);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildAllContent(context);
    }

    // Show live search results
    _triggerSearch(context, query);
    return _buildSearchContent(context, showCategories: false);
  }

  /// Build search results with optional category headers
  Widget _buildSearchContent(
    BuildContext context, {
    required bool showCategories,
  }) {
    return MultiBlocBuilder(
      builders: [
        BlocProvider.of<TaskBloc>(context),
        BlocProvider.of<HabitBloc>(context),
      ],
      builder: (context, states) {
        final taskState = states[0] as TaskState;
        final habitState = states[1] as HabitState;

        final searchResults = _combineSearchResults(taskState, habitState);

        if (searchResults.isEmpty) {
          return const SearchEmptyState();
        }

        return SearchResultList(
          results: searchResults,
          searchQuery: query,
          showCategories: showCategories,
          onResultTap: (result) {
            _handleResultNavigation(context, result);
            close(context, null);
          },
        );
      },
    );
  }

  /// Build all content when no search query
  Widget _buildAllContent(BuildContext context) {
    return MultiBlocBuilder(
      builders: [
        BlocProvider.of<TaskBloc>(context),
        BlocProvider.of<HabitBloc>(context),
      ],
      builder: (context, states) {
        final taskState = states[0] as TaskState;
        final habitState = states[1] as HabitState;

        final allResults = _getAllResults(taskState, habitState);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SearchHeader(title: 'All Content'),
            Expanded(
              child: SearchResultList(
                results: allResults,
                searchQuery: '',
                showCategories: true,
                onResultTap: (result) {
                  _handleResultNavigation(context, result);
                  close(context, null);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Trigger search in all relevant BLoCs
  void _triggerSearch(BuildContext context, String searchQuery) {
    context.read<TaskBloc>().add(SearchTasks(searchQuery));
    context.read<HabitBloc>().add(SearchHabits(searchQuery));
  }

  /// Clear all search filters
  void _clearAllFilters(BuildContext context) {
    context.read<TaskBloc>().add(const FilterTasks(TaskFilter()));
    context.read<HabitBloc>().add(const FilterHabits(HabitFilter()));
  }

  /// Combine filtered search results from all BLoCs
  List<SearchResult> _combineSearchResults(
    TaskState taskState,
    HabitState habitState,
  ) {
    final results = <SearchResult>[];

    // Add filtered tasks and notes
    if (taskState is TaskLoaded) {
      final filteredTasks =
          taskState
              .getFilteredTasks()
              .where((task) => !task.isDeleted)
              .map((task) => TaskSearchResult(task))
              .toList();
      results.addAll(filteredTasks);
    }

    // Add filtered habits
    if (habitState is HabitLoaded) {
      final filteredHabits =
          habitState
              .getFilteredHabits()
              .where((habit) => !habit.isDeleted)
              .map((habit) => HabitSearchResult(habit))
              .toList();
      results.addAll(filteredHabits);
    }

    // Sort by relevance (created date for now)
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return results;
  }

  /// Get all content when no search query
  List<SearchResult> _getAllResults(
    TaskState taskState,
    HabitState habitState,
  ) {
    final results = <SearchResult>[];

    // Add all tasks and notes
    if (taskState is TaskLoaded) {
      final allTasks =
          taskState.tasks
              .where((task) => !task.isDeleted)
              .map((task) => TaskSearchResult(task))
              .toList();
      results.addAll(allTasks);
    }

    // Add all habits
    if (habitState is HabitLoaded) {
      final allHabits =
          habitState.habits
              .where((habit) => !habit.isDeleted)
              .map((habit) => HabitSearchResult(habit))
              .toList();
      results.addAll(allHabits);
    }

    // Sort by created date
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return results;
  }

  /// Handle navigation based on result type
  void _handleResultNavigation(BuildContext context, SearchResult result) {
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
        context.push('/edit-habit', extra: habitResult.habit);
        break;
    }
  }
}

/// Helper widget for listening to multiple BLoCs
class MultiBlocBuilder extends StatelessWidget {
  final List<BlocBase> builders;
  final Widget Function(BuildContext, List<dynamic>) builder;

  const MultiBlocBuilder({
    super.key,
    required this.builders,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, taskState) {
        return BlocBuilder<HabitBloc, HabitState>(
          builder: (context, habitState) {
            return builder(context, [taskState, habitState]);
          },
        );
      },
    );
  }
}
