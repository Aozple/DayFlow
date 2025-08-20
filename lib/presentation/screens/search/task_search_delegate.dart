import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/task_model.dart';

// This class handles the search functionality for tasks.
// It extends SearchDelegate, which is a built-in Flutter class for search.
class TaskSearchDelegate extends SearchDelegate<TaskModel?> {
  // Constructor for our search delegate.
  TaskSearchDelegate()
    : super(
        searchFieldLabel: 'Search tasks...', // This is the hint text in the search bar.
        keyboardType: TextInputType.text, // We expect text input.
      );

  // This method customizes the theme of the app bar specifically for the search screen.
  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface, // Set the background color.
        elevation: 0, // Remove the shadow under the app bar.
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: AppColors.textSecondary), // Style for the hint text.
        border: InputBorder.none, // Remove the default input field border.
      ),
    );
  }

  // This method builds the actions that appear on the right side of the app bar.
  // Here, we're adding a clear button if there's any text in the search query.
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty) // Only show the clear button if the search query isn't empty.
        IconButton(
          icon: const Icon(
            CupertinoIcons.clear_circled_solid, // A clear icon.
            color: AppColors.textSecondary,
          ),
          onPressed: () {
            query = ''; // Clear the current search query.
            showSuggestions(context); // Show suggestions again after clearing.
          },
        ),
    ];
  }

  // This method builds the leading icon (on the left side) of the app bar.
  // It's typically a back button to close the search.
  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(CupertinoIcons.back, color: AppColors.textPrimary), // A back arrow icon.
      onPressed: () {
        close(context, null); // Close the search delegate and return null (no selected task).
      },
    );
  }

  // This method builds the results of the search.
  // It's called when the user submits their search query.
  @override
  Widget buildResults(BuildContext context) {
    // Get the TaskBloc to access the current state of tasks.
    final taskBloc = context.read<TaskBloc>();
    final state = taskBloc.state;

    // If tasks are loaded, filter them based on the query and display.
    if (state is TaskLoaded) {
      final filteredTasks = _filterTasks(state.tasks); // Filter the tasks.

      if (filteredTasks.isEmpty) {
        return _buildEmptyState(); // Show an empty state if no tasks match.
      }

      return _buildTaskList(filteredTasks); // Display the list of filtered tasks.
    }

    // Fallback if tasks aren't loaded yet.
    return const Center(child: Text('No tasks loaded'));
  }

  // This method builds suggestions as the user types in the search bar.
  // If the query is empty, it shows all tasks. Otherwise, it shows search results.
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
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'All Tasks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(child: _buildTaskList(state.tasks)), // Display all tasks.
          ],
        );
      }
    }

    // If there's a query, just show the results (suggestions are the same as results here).
    return buildResults(context);
  }

  // This helper method filters the list of tasks based on the current search query.
  // It performs a case-insensitive search across title, description, tags, priority, and status.
  List<TaskModel> _filterTasks(List<TaskModel> tasks) {
    if (query.isEmpty) return tasks; // If no query, return all tasks.

    final searchLower = query.toLowerCase().trim(); // Convert query to lowercase for case-insensitive search.

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

  // This method builds the UI to show when no search results are found.
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.search, size: 64, color: AppColors.textTertiary), // A search icon.
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

  // This method builds a scrollable list of tasks.
  Widget _buildTaskList(List<TaskModel> tasks) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTaskItem(context, task); // Build each individual task item.
      },
    );
  }

  // This method builds a single task item for display in the search results.
  Widget _buildTaskItem(BuildContext context, TaskModel task) {
    final taskColor = AppColors.fromHex(task.color); // Get the color from the task's hex string.

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent, // Make the material transparent so InkWell's splash is visible.
        child: InkWell(
          onTap: () {
            // When a task is tapped, close the search and navigate to its details screen.
            close(context, task);
            context.push('/task-details', extra: task);
          },
          borderRadius: BorderRadius.circular(12), // Rounded corners for the tap effect.
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface, // Background color of the task card.
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: taskColor, width: 3)), // Left border with task's color.
            ),
            child: Row(
              children: [
                // Expanded widget to take available space for task info.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display the task title, highlighting the search term.
                      RichText(
                        text: _highlightSearchTerm(task.title),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis, // Truncate if too long.
                      ),

                      const SizedBox(height: 4),

                      // Row for task metadata like date, priority, and tags.
                      Row(
                        children: [
                          // Show due date if available.
                          if (task.dueDate != null) ...[
                            const Icon(
                              CupertinoIcons.calendar,
                              size: 12,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d').format(task.dueDate!), // Format the date.
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],

                          // Display task priority.
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(
                                task.priority,
                              ).withAlpha(30), // Background color based on priority.
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'P${task.priority}', // "P1", "P2", etc.
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _getPriorityColor(task.priority), // Text color based on priority.
                              ),
                            ),
                          ),

                          // Show the first tag if tags exist.
                          if (task.tags.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              CupertinoIcons.tag,
                              size: 12,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              task.tags.first, // Display only the first tag.
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

                // Show a checkmark if the task is completed.
                if (task.isCompleted)
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

  // This helper method highlights the search term within a given text string.
  TextSpan _highlightSearchTerm(String text) {
    if (query.isEmpty) {
      // If no search query, just return the text without highlighting.
      return TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      );
    }

    final matches = query.toLowerCase(); // The search term in lowercase.
    final textLower = text.toLowerCase(); // The text to search within, in lowercase.

    if (!textLower.contains(matches)) {
      // If the text doesn't contain the search term, return it unhighlighted.
      return TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      );
    }

    // Find the start and end indices of the search term in the original text.
    final startIndex = textLower.indexOf(matches);
    final endIndex = startIndex + matches.length;

    // Return a RichText with the matching part highlighted.
    return TextSpan(
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      children: [
        TextSpan(text: text.substring(0, startIndex)), // Text before the match.
        TextSpan(
          text: text.substring(startIndex, endIndex), // The matched text.
          style: TextStyle(
            backgroundColor: AppColors.accent.withAlpha(50), // Highlight background.
            color: AppColors.accent, // Highlight text color.
          ),
        ),
        TextSpan(text: text.substring(endIndex)), // Text after the match.
      ],
    );
  }

  // This helper method returns a color based on the task's priority level.
  Color _getPriorityColor(int priority) {
    if (priority >= 4) return AppColors.error; // High priority tasks get an error color.
    if (priority == 3) return AppColors.warning; // Medium priority tasks get a warning color.
    return AppColors.textSecondary; // Low priority tasks get a secondary text color.
  }
}
