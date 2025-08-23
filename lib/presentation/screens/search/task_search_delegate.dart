import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_state.dart';
import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'widgets/search_empty_state.dart';
import 'widgets/search_task_list.dart';
import 'widgets/search_suggestions_header.dart';

/// Search delegate for finding tasks in the app.
///
/// This class handles the search functionality for tasks, extending Flutter's
/// SearchDelegate to provide a consistent search experience. It supports searching
/// across task titles, descriptions, tags, priority, and completion status.
class TaskSearchDelegate extends SearchDelegate<TaskModel?> {
  /// Constructor for the search delegate.
  TaskSearchDelegate()
    : super(
        searchFieldLabel: 'Search tasks...', // Hint text in the search bar.
        keyboardType: TextInputType.text, // Text input type.
      );

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface, // Background color.
        elevation: 0, // Remove shadow.
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(
          color: AppColors.textSecondary,
        ), // Hint text style.
        border: InputBorder.none, // Remove input field border.
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty) // Show clear button only when there's text.
        IconButton(
          icon: const Icon(
            CupertinoIcons.clear_circled_solid, // Clear icon.
            color: AppColors.textSecondary,
          ),
          onPressed: () {
            query = ''; // Clear the search query.
            showSuggestions(context); // Show suggestions again.
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(
        CupertinoIcons.back,
        color: AppColors.textPrimary,
      ), // Back arrow icon.
      onPressed: () {
        close(context, null); // Close search and return null.
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Get the TaskBloc to access the current state of tasks.
    final taskBloc = context.read<TaskBloc>();
    final state = taskBloc.state;

    // If tasks are loaded, filter them based on the query and display.
    if (state is TaskLoaded) {
      final filteredTasks = _filterTasks(state.tasks); // Filter the tasks.
      if (filteredTasks.isEmpty) {
        return const SearchEmptyState(); // Show empty state if no tasks match.
      }
      return SearchTaskList(
        tasks: filteredTasks,
        onTaskTap: (task) {
          close(context, task); // Close search and return the selected task.
          context.push(
            '/task-details',
            extra: task,
          ); // Navigate to task details.
        },
        searchQuery: query, // Pass the current search query
      ); // Display the list of filtered tasks.
    }

    // Fallback if tasks aren't loaded yet.
    return const Center(child: Text('No tasks loaded'));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      // If the search query is empty, show all tasks.
      final taskBloc = context.read<TaskBloc>();
      final state = taskBloc.state;
      if (state is TaskLoaded) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SearchSuggestionsHeader(), // Header for "All Tasks"
            Expanded(
              child: SearchTaskList(
                tasks: state.tasks,
                onTaskTap: (task) {
                  close(
                    context,
                    task,
                  ); // Close search and return the selected task.
                  context.push(
                    '/task-details',
                    extra: task,
                  ); // Navigate to task details.
                },
                searchQuery: query, // Pass the current search query
              ),
            ), // Display all tasks.
          ],
        );
      }
    }
    // If there's a query, just show the results.
    return buildResults(context);
  }

  /// Filters the list of tasks based on the current search query.
  ///
  /// Performs a case-insensitive search across title, description, tags,
  /// priority, and completion status.
  List<TaskModel> _filterTasks(List<TaskModel> tasks) {
    if (query.isEmpty) return tasks; // If no query, return all tasks.

    final searchLower = query.toLowerCase().trim(); // Case-insensitive search.
    return tasks.where((task) {
      // Don't show deleted tasks in search results.
      if (task.isDeleted) return false;

      // Check if the task title contains the search term.
      if (task.title.toLowerCase().contains(searchLower)) {
        return true;
      }

      // Check if the task description contains the search term (if description exists).
      if (task.description != null &&
          task.description!.toLowerCase().contains(searchLower)) {
        return true;
      }

      // Check if any of the task's tags contain the search term.
      for (final tag in task.tags) {
        if (tag.toLowerCase().contains(searchLower)) {
          return true;
        }
      }

      // Allow searching by priority (e.g., "priority 5", "p5", "high").
      if (searchLower.contains('priority') || searchLower.startsWith('p')) {
        final priorityStr = task.priority.toString();
        if (searchLower.contains(priorityStr)) return true;
      }

      // Allow searching by task status ("completed" or "pending").
      if (task.isCompleted && searchLower.contains('completed')) return true;
      if (!task.isCompleted && searchLower.contains('pending')) return true;

      return false; // If no match, exclude the task.
    }).toList();
  }
}
