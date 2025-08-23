import 'package:flutter/material.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'search_task_item.dart';

/// A scrollable list of tasks for search results.
///
/// This widget builds a ListView of SearchTaskItem widgets to display
/// the search results. It handles the layout and scrolling behavior
/// of the task list.
class SearchTaskList extends StatelessWidget {
  /// List of tasks to display.
  final List<TaskModel> tasks;

  /// Callback function when a task is tapped.
  final Function(TaskModel) onTaskTap;

  /// The current search query for highlighting matching text.
  final String searchQuery;

  const SearchTaskList({
    super.key,
    required this.tasks,
    required this.onTaskTap,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return SearchTaskItem(
          task: task,
          onTap: () => onTaskTap(task),
          searchQuery: searchQuery, // Pass the search query to each item
        );
      },
    );
  }
}
