import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

/// A single task item for display in the search results.
///
/// This widget represents a single task in the search results list, showing
/// the task title with search term highlighting, along with metadata like
/// due date, priority, and tags. It handles tap gestures to navigate to
/// the task details screen.
class SearchTaskItem extends StatelessWidget {
  /// The task to display.
  final TaskModel task;

  /// Callback function when the task is tapped.
  final VoidCallback onTap;

  /// The current search query for highlighting matching text.
  final String searchQuery;

  const SearchTaskItem({
    super.key,
    required this.task,
    required this.onTap,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final taskColor = AppColors.fromHex(
      task.color,
    ); // Get the color from the task's hex string.

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent, // Transparent for InkWell's splash effect.
        child: InkWell(
          onTap: onTap, // Handle tap to navigate to task details.
          borderRadius: BorderRadius.circular(12), // Rounded corners.
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface, // Background color.
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(
                  color: taskColor,
                  width: 3,
                ), // Left border with task's color.
              ),
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
                        text: _highlightSearchTerm(task.title, searchQuery),
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis, // Truncate if too long.
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
                              DateFormat(
                                'MMM d',
                              ).format(task.dueDate!), // Format the date.
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
                              color: AppColors.getPriorityColor(
                                task.priority,
                              ).withAlpha(
                                30,
                              ), // Background color based on priority.
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'P${task.priority}', // "P1", "P2", etc.
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.getPriorityColor(
                                  task.priority,
                                ), // Text color based on priority.
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

  /// Highlights the search term within a given text string.
  TextSpan _highlightSearchTerm(String text, String query) {
    // If no search query, just return the text without highlighting.
    if (query.isEmpty) {
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
    final textLower =
        text.toLowerCase(); // The text to search within, in lowercase.

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
    final endIndex =
        startIndex + matches.length; // Fixed: was incorrectly using 'endtask'

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
            backgroundColor: AppColors.accent.withAlpha(
              50,
            ), // Highlight background.
            color: AppColors.accent, // Highlight text color.
          ),
        ),
        TextSpan(text: text.substring(endIndex)), // Text after the match.
      ],
    );
  }
}
