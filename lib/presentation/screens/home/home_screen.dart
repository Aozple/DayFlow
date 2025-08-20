import 'package:dayflow/presentation/blocs/settings/settings_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_event.dart';
import 'package:dayflow/presentation/blocs/tasks/task_state.dart';
import 'package:dayflow/presentation/screens/search/task_search_delegate.dart';
import 'package:dayflow/presentation/widgets/speed_dial_fab.dart';
import 'package:dayflow/presentation/widgets/task_filter_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/custom_snackbar.dart';
import '../../../data/models/task_model.dart';

// This is the main home screen of our app, showing tasks and notes.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// The state for our HomeScreen, managing selected date, filters, and task list.
class _HomeScreenState extends State<HomeScreen> {
  // The date currently selected in the date selector.
  DateTime _selectedDate = DateTime.now();
  // Controller for the timeline's scroll position.
  final ScrollController _scrollController = ScrollController();
  // Current filter options applied to tasks.
  TaskFilterOptions _currentFilters = TaskFilterOptions();
  // The list of tasks after applying filters.
  List<TaskModel> _filteredTasks = [];

  @override
  void initState() {
    super.initState();
    // After the first frame, scroll the timeline to the current time.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
  }

  @override
  void dispose() {
    // Clean up the scroll controller when the widget is removed.
    _scrollController.dispose();
    super.dispose();
  }

  // Scrolls the timeline to approximately the current hour.
  void _scrollToCurrentTime() {
    if (!_scrollController.hasClients) return; // Don't scroll if controller isn't attached.

    final now = DateTime.now();
    // Calculate scroll position: each hour slot is about 80 pixels.
    final scrollPosition = (now.hour * 80.0) - 200; // Offset to show some hours before current.

    _scrollController.animateTo(
      scrollPosition.clamp(0, _scrollController.position.maxScrollExtent), // Keep scroll within bounds.
      duration: const Duration(milliseconds: 800), // Smooth animation duration.
      curve: Curves.easeInOutCubic, // Animation curve.
    );
  }

  // Opens the search delegate to allow users to search for tasks.
  void _openSearch() async {
    final selectedTask = await showSearch<TaskModel?>(
      context: context,
      delegate: TaskSearchDelegate(), // Our custom search delegate.
    );

    // If a task was selected from the search results, navigate to its details.
    if (selectedTask != null && mounted) {
      context.push('/task-details', extra: selectedTask);
    }
  }

  // Checks if any filters are currently active.
  bool _hasActiveFilters() {
    return _currentFilters.dateFilter != null ||
        _currentFilters.priorityFilter != null ||
        _currentFilters.completedFilter != null ||
        _currentFilters.tagFilters.isNotEmpty;
  }

  // Opens the modal bottom sheet for task filtering options.
  void _openFilterModal() async {
    // Collect all unique tags from the loaded tasks to populate filter options.
    final allTags = <String>{};
    final state = context.read<TaskBloc>().state;

    if (state is TaskLoaded) {
      for (final task in state.tasks) {
        allTags.addAll(task.tags);
      }
    }

    // Show the filter modal and wait for a result.
    final result = await showModalBottomSheet<TaskFilterOptions>(
      context: context,
      isScrollControlled: true, // Allows the modal to take full height.
      backgroundColor: Colors.transparent, // Transparent background for custom styling.
      builder:
          (context) => TaskFilterModal(
            initialFilters: _currentFilters, // Pass current filters to pre-select.
            availableTags: allTags.toList()..sort(), // Pass available tags, sorted.
          ),
    );

    // If new filters were selected, update the state and re-apply filters.
    if (result != null) {
      setState(() {
        _currentFilters = result;
        _applyFilters();
      });
    }
  }

  // Applies the currently selected filters to the list of tasks.
  void _applyFilters() {
    final state = context.read<TaskBloc>().state;

    if (state is TaskLoaded) {
      // Start with all non-deleted tasks.
      var filtered = state.tasks.where((task) => !task.isDeleted).toList();

      // Apply date filter if set.
      if (_currentFilters.dateFilter != null) {
        final now = DateTime.now();
        filtered =
            filtered.where((task) {
              if (task.dueDate == null) return false; // Tasks without due dates are excluded.

              switch (_currentFilters.dateFilter!) {
                case DateFilter.today:
                  return _isSameDay(task.dueDate!, now); // Check if due date is today.
                case DateFilter.thisWeek:
                  // Check if due date is within the current week (Monday to Sunday).
                  final weekStart = now.subtract(
                    Duration(days: now.weekday - 1),
                  );
                  final weekEnd = weekStart.add(const Duration(days: 6));
                  return task.dueDate!.isAfter(
                        weekStart.subtract(const Duration(days: 1)),
                      ) &&
                      task.dueDate!.isBefore(
                        weekEnd.add(const Duration(days: 1)),
                      );
                case DateFilter.thisMonth:
                  // Check if due date is within the current month.
                  return task.dueDate!.year == now.year &&
                      task.dueDate!.month == now.month;
                case DateFilter.custom:
                  return true; // TODO: Implement custom date range filtering.
              }
            }).toList();
      }

      // Apply priority filter if set.
      if (_currentFilters.priorityFilter != null) {
        filtered =
            filtered
                .where(
                  (task) => task.priority == _currentFilters.priorityFilter,
                )
                .toList();
      }

      // Apply completion status filter if set.
      if (_currentFilters.completedFilter != null) {
        filtered =
            filtered
                .where(
                  (task) => task.isCompleted == _currentFilters.completedFilter,
                )
                .toList();
      }

      // Apply tag filters if any tags are selected.
      if (_currentFilters.tagFilters.isNotEmpty) {
        filtered =
            filtered.where((task) {
              for (final tag in _currentFilters.tagFilters) {
                if (task.tags.contains(tag)) return true; // Task must have at least one selected tag.
              }
              return false;
            }).toList();
      }

      // Apply sorting based on the selected sort option.
      switch (_currentFilters.sortBy) {
        case SortOption.dateDesc:
          // Sort by due date (or creation date if no due date) descending.
          filtered.sort(
            (a, b) =>
                (b.dueDate ?? b.createdAt).compareTo(a.dueDate ?? a.createdAt),
          );
          break;
        case SortOption.dateAsc:
          // Sort by due date (or creation date if no due date) ascending.
          filtered.sort(
            (a, b) =>
                (a.dueDate ?? a.createdAt).compareTo(b.dueDate ?? b.createdAt),
          );
          break;
        case SortOption.priorityDesc:
          // Sort by priority descending (higher priority first).
          filtered.sort((a, b) => b.priority.compareTo(a.priority));
          break;
        case SortOption.priorityAsc:
          // Sort by priority ascending (lower priority first).
          filtered.sort((a, b) => a.priority.compareTo(b.priority));
          break;
        case SortOption.alphabetical:
          // Sort by title alphabetically.
          filtered.sort((a, b) => a.title.compareTo(b.title));
          break;
      }

      setState(() {
        _filteredTasks = filtered; // Update the displayed tasks.
      });
    }
  }

  // Shows a Cupertino-style action sheet for note options (edit, duplicate, delete).
  void _showNoteOptionsMenu(TaskModel note) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: Text(note.title, style: const TextStyle(fontSize: 16)),
            message: const Text('What would you like to do with this note?'),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context); // Close the action sheet.
                  context.push('/edit-note', extra: note); // Navigate to edit note screen.
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.pencil, size: 18),
                    SizedBox(width: 8),
                    Text('Edit Note'),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context); // Close the action sheet.
                  _duplicateNote(note); // Duplicate the note.
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.doc_on_doc, size: 18),
                    SizedBox(width: 8),
                    Text('Duplicate'),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                isDestructiveAction: true, // Make this action red.
                onPressed: () {
                  Navigator.pop(context); // Close the action sheet.
                  _confirmDeleteNote(note); // Show delete confirmation.
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.trash, size: 18),
                    SizedBox(width: 8),
                    Text('Delete Note'),
                  ],
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context), // Just close the sheet.
              child: const Text('Cancel'),
            ),
          ),
    );
  }

  // Shows a confirmation dialog before deleting a note.
  void _confirmDeleteNote(TaskModel note) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Delete Note'),
            content: Text('Are you sure you want to delete "${note.title}"?'),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context), // Close dialog.
              ),
              CupertinoDialogAction(
                isDestructiveAction: true, // Make this action red.
                onPressed: () {
                  Navigator.pop(context); // Close dialog.
                  _deleteNote(note); // Proceed with deletion.
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  // Deletes a note by dispatching a DeleteTask event to the TaskBloc.
  void _deleteNote(TaskModel note) {
    context.read<TaskBloc>().add(DeleteTask(note.id));
    CustomSnackBar.success(context, 'Note deleted successfully'); // Show success message.
  }

  // Duplicates a note by creating a new TaskModel and adding it to the TaskBloc.
  void _duplicateNote(TaskModel note) {
    final duplicatedNote = TaskModel(
      title: '${note.title} (Copy)', // Add "(Copy)" to the title.
      markdownContent: note.markdownContent,
      dueDate: note.dueDate,
      color: note.color,
      tags: note.tags,
      isNote: true, // Ensure it's still marked as a note.
      priority: 1, // Default priority for duplicated notes.
    );

    context.read<TaskBloc>().add(AddTask(duplicatedNote)); // Add the new note.
    CustomSnackBar.success(context, 'Note duplicated successfully'); // Show success message.
  }

  // Shows a Cupertino-style action sheet for task options.
  void _showTaskOptionsMenu(TaskModel task) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: Text(
              task.title,
              style: const TextStyle(fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis, // Truncate long titles.
            ),
            message: Column(
              children: [
                // Display task status and priority.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Status indicator (Completed/In Progress).
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            task.isCompleted
                                ? AppColors.success.withAlpha(20)
                                : AppColors.accent.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        task.isCompleted ? 'Completed' : 'In Progress',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              task.isCompleted
                                  ? AppColors.success
                                  : AppColors.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Priority indicator (e.g., "P5").
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(task.priority).withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'P${task.priority}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _getPriorityColor(task.priority),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // Action to toggle task completion status.
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context); // Close the action sheet.
                  _toggleTaskCompletion(task); // Toggle completion.
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      task.isCompleted
                          ? CupertinoIcons.arrow_uturn_left // Icon for marking pending.
                          : CupertinoIcons.checkmark_circle, // Icon for marking completed.
                      size: 18,
                      color:
                          task.isCompleted
                              ? AppColors.warning
                              : AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      task.isCompleted
                          ? 'Mark as Pending'
                          : 'Mark as Completed',
                      style: TextStyle(
                        color:
                            task.isCompleted
                                ? AppColors.warning
                                : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),

              // Action to edit the task.
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context); // Close the action sheet.
                  context.push('/edit-task', extra: task); // Navigate to edit task screen.
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.pencil, size: 18),
                    SizedBox(width: 8),
                    Text('Edit Task'),
                  ],
                ),
              ),

              // Action to view task details.
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context); // Close the action sheet.
                  context.push('/task-details', extra: task); // Navigate to task details screen.
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.info_circle, size: 18),
                    SizedBox(width: 8),
                    Text('View Details'),
                  ],
                ),
              ),

              // Action to duplicate the task.
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context); // Close the action sheet.
                  _duplicateTask(task); // Duplicate the task.
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.doc_on_doc, size: 18),
                    SizedBox(width: 8),
                    Text('Duplicate'),
                  ],
                ),
              ),

              // Action to delete the task (destructive).
              CupertinoActionSheetAction(
                isDestructiveAction: true, // Make this action red.
                onPressed: () {
                  Navigator.pop(context); // Close the action sheet.
                  _confirmDeleteTask(task); // Show delete confirmation.
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.trash, size: 18),
                    SizedBox(width: 8),
                    Text('Delete Task'),
                  ],
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context), // Just close the sheet.
              child: const Text('Cancel'),
            ),
          ),
    );
  }

  // Helper method to get a color based on task priority.
  Color _getPriorityColor(int priority) {
    if (priority >= 4) return AppColors.error; // High priority.
    if (priority == 3) return AppColors.warning; // Medium priority.
    return AppColors.textSecondary; // Low priority.
  }

  // Toggles the completion status of a task and provides haptic feedback.
  void _toggleTaskCompletion(TaskModel task) {
    HapticFeedback.lightImpact(); // Provide a subtle vibration.
    context.read<TaskBloc>().add(ToggleTaskComplete(task.id)); // Dispatch event to update task.

    CustomSnackBar.success(
      context,
      task.isCompleted ? 'Task marked as pending' : 'Task completed! 🎉', // Show appropriate message.
    );
  }

  // Shows a confirmation dialog before deleting a task.
  void _confirmDeleteTask(TaskModel task) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Delete Task'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Are you sure you want to delete "${task.title}"?'),
                const SizedBox(height: 8),
                // Show description if it exists.
                if (task.description?.isNotEmpty == true)
                  Text(
                    task.description!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis, // Truncate long descriptions.
                  ),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context), // Close dialog.
              ),
              CupertinoDialogAction(
                isDestructiveAction: true, // Make this action red.
                onPressed: () {
                  Navigator.pop(context); // Close dialog.
                  _deleteTask(task); // Proceed with deletion.
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  // Deletes a task by dispatching a DeleteTask event to the TaskBloc.
  void _deleteTask(TaskModel task) {
    context.read<TaskBloc>().add(DeleteTask(task.id));
    CustomSnackBar.success(context, 'Task deleted successfully'); // Show success message.
  }

  // Duplicates a task by creating a new TaskModel and adding it to the TaskBloc.
  void _duplicateTask(TaskModel task) {
    final duplicatedTask = TaskModel(
      title: '${task.title} (Copy)', // Add "(Copy)" to the title.
      description: task.description,
      dueDate: task.dueDate,
      priority: task.priority,
      color: task.color,
      tags: task.tags,
      // Reset completion status for the duplicated task.
      isCompleted: false,
      completedAt: null,
    );

    context.read<TaskBloc>().add(AddTask(duplicatedTask)); // Add the new task.
    CustomSnackBar.success(context, 'Task duplicated successfully'); // Show success message.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // The header section of the home screen.
            _buildHeader(),

            // Horizontal date selector for navigating days.
            _buildDateSelector(),

            // A thin divider line.
            Container(height: 0.5, color: AppColors.divider),

            // The main timeline area where tasks are displayed by hour.
            Expanded(
              child: BlocBuilder<TaskBloc, TaskState>(
                builder: (context, state) {
                  List<TaskModel> dayTasks = [];

                  if (state is TaskLoaded) {
                    // Filter tasks to show only those due on the selected date.
                    dayTasks =
                        state.tasks.where((task) {
                          if (task.dueDate == null) return false;
                          return _isSameDay(task.dueDate!, _selectedDate);
                        }).toList();
                  }

                  return _buildTimeline(dayTasks); // Build the timeline with relevant tasks.
                },
              ),
            ),
          ],
        ),
      ),

      // Floating action button for quickly creating new tasks or notes.
      floatingActionButton: SpeedDialFab(
        onCreateTask: () => context.push('/create-task'), // Navigate to create task screen.
        onCreateNote: () => context.push('/create-note'), // Navigate to create note screen.
      ),
    );
  }

  // Builds the header section of the home screen, including date display and action buttons.
  Widget _buildHeader() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Apply a blur effect.
        child: Container(
          color: AppColors.surface.withAlpha(200), // Semi-transparent background.
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Column for displaying the selected date.
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE').format(_selectedDate), // Day of the week (e.g., "Wednesday").
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    DateFormat('d MMM').format(_selectedDate), // Day and month (e.g., "21 Aug").
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),

              // Row for action buttons (Today, Filter, Search, Settings).
              Row(
                children: [
                  // "Today" button, visible only if the selected date is not today.
                  if (!_isSameDay(_selectedDate, DateTime.now()))
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        final today = DateTime.now();
                        setState(() => _selectedDate = today); // Set selected date to today.
                        context.read<TaskBloc>().add(LoadTasksByDate(today)); // Reload tasks for today.
                        _scrollToCurrentTime(); // Scroll to current time.
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Today',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(width: 12),

                  // Filter button with an indicator if filters are active.
                  CupertinoButton(
                    padding: const EdgeInsets.all(4),
                    minSize: 28,
                    onPressed: () => _openFilterModal(), // Open the filter modal.
                    child: Stack(
                      children: [
                        const Icon(
                          CupertinoIcons.slider_horizontal_3, // Filter icon.
                          color: AppColors.textSecondary,
                          size: 24,
                        ),
                        // Small dot indicator if any filters are applied.
                        if (_hasActiveFilters())
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Search button.
                  CupertinoButton(
                    padding: const EdgeInsets.all(4),
                    minSize: 28,
                    onPressed: () => _openSearch(), // Open the search delegate.
                    child: const Icon(
                      CupertinoIcons.search, // Search icon.
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Settings button.
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      context.push('/settings'); // Navigate to settings screen.
                    },
                    child: const Icon(
                      CupertinoIcons.gear, // Settings icon.
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Builds the horizontal date selector for navigating through days of the week.
  Widget _buildDateSelector() {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        // Get the "Saturday first" setting from the SettingsBloc.
        final isSaturdayFirst =
            settingsState is SettingsLoaded
                ? settingsState.isSaturdayFirst
                : false; // Default to false if settings not loaded.

        return Container(
          height: 90,
          color: AppColors.surface, // Background color for the date selector.
          child: Column(
            children: [
              // Row displaying the current week range and navigation buttons.
              Container(
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          _getWeekRange(_selectedDate), // Display the date range of the current week.
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        // Show a "SAT" indicator if Saturday is set as the first day of the week.
                        if (isSaturdayFirst) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withAlpha(20),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'SAT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Buttons for navigating to the previous and next week.
                    Row(
                      children: [
                        CupertinoButton(
                          padding: const EdgeInsets.all(4),
                          minSize: 28,
                          onPressed: () => _navigateWeek(-1), // Go to previous week.
                          child: const Icon(
                            CupertinoIcons.chevron_left,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        CupertinoButton(
                          padding: const EdgeInsets.all(4),
                          minSize: 28,
                          onPressed: () => _navigateWeek(1), // Go to next week.
                          child: const Icon(
                            CupertinoIcons.chevron_right,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Horizontal list of days in the current week.
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(), // Prevent manual scrolling.
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: 7, // Always show 7 days.
                  itemBuilder: (context, index) {
                    final weekStart = _getWeekStart(_selectedDate); // Get the start of the week.
                    final date = weekStart.add(Duration(days: index)); // Calculate each day's date.
                    return _buildDateItem(date); // Build the widget for each day.
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper method to determine the start of the week based on settings (Monday or Saturday).
  DateTime _getWeekStart(DateTime date) {
    // Get the "Saturday first" setting from the SettingsBloc.
    final settingsState = context.read<SettingsBloc>().state;
    final isSaturdayFirst =
        settingsState is SettingsLoaded
            ? settingsState.isSaturdayFirst
            : false; // Default to Monday if not loaded.

    final weekday = date.weekday; // Get the day of the week (1 for Monday, 7 for Sunday).

    if (isSaturdayFirst) {
      // If Saturday is the first day of the week (weekday 6).
      int daysToSubtract;
      if (weekday == 6) {
        daysToSubtract = 0; // If it's Saturday, subtract 0 days.
      } else if (weekday == 7) {
        daysToSubtract = 1; // If it's Sunday, subtract 1 day to get to Saturday.
      } else {
        daysToSubtract = weekday + 1; // For Monday-Friday, calculate days to subtract to get to Saturday.
      }

      return date.subtract(Duration(days: daysToSubtract));
    } else {
      // Default behavior: Monday is the first day of the week.
      return date.subtract(Duration(days: weekday - 1));
    }
  }

  // Helper method to format the week range string (e.g., "Aug 21 - 27" or "Aug 21 - Sep 3").
  String _getWeekRange(DateTime date) {
    final weekStart = _getWeekStart(date); // Get the start date of the week.
    final weekEnd = weekStart.add(const Duration(days: 6)); // Get the end date of the week.

    if (weekStart.month == weekEnd.month) {
      // If both start and end are in the same month.
      return '${DateFormat('MMM d').format(weekStart)} - ${weekEnd.day}';
    } else {
      // If the week spans two months.
      return '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d').format(weekEnd)}';
    }
  }

  // Navigates the selected date by a full week (forward or backward).
  void _navigateWeek(int direction) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: 7 * direction)); // Add or subtract 7 days.
    });
    context.read<TaskBloc>().add(LoadTasksByDate(_selectedDate)); // Reload tasks for the new week.
  }

  // Builds an individual date item (day of the week and day number) in the date selector.
  Widget _buildDateItem(DateTime date) {
    final isSelected = _isSameDay(date, _selectedDate); // Check if this date is currently selected.
    final isToday = _isSameDay(date, DateTime.now()); // Check if this date is today.
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - 16) / 7; // Calculate width for each day item.

    // Get the "Saturday first" setting directly for this widget.
    final settingsState = context.read<SettingsBloc>().state;
    final isSaturdayFirst =
        settingsState is SettingsLoaded ? settingsState.isSaturdayFirst : false;

    // Helper function to get the correct 3-letter day name based on settings.
    String getDayName(DateTime date) {
      if (isSaturdayFirst) {
        // Custom day names if Saturday is the first day.
        switch (date.weekday) {
          case 6:
            return 'SAT';
          case 7:
            return 'SUN';
          case 1:
            return 'MON';
          case 2:
            return 'TUE';
          case 3:
            return 'WED';
          case 4:
            return 'THU';
          case 5:
            return 'FRI';
          default:
            return DateFormat('E').format(date).substring(0, 3).toUpperCase();
        }
      } else {
        // Standard 3-letter day names.
        return DateFormat('E').format(date).substring(0, 3).toUpperCase();
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() => _selectedDate = date); // Update selected date on tap.
        context.read<TaskBloc>().add(LoadTasksByDate(date)); // Reload tasks for the new day.
      },
      child: Container(
        width: itemWidth,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Container(
          decoration: BoxDecoration(
            color:
                isSelected
                    ? AppColors.accent // Highlight color if selected.
                    : isToday
                    ? AppColors.accent.withAlpha(30) // Subtle highlight if today.
                    : Colors.transparent, // No background if neither.
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Display the day name (e.g., "MON", "TUE").
              Text(
                getDayName(date),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color:
                      isSelected
                          ? Colors.white // White text if selected.
                          : isToday
                          ? AppColors.accent // Accent color if today.
                          : AppColors.textSecondary, // Secondary text color otherwise.
                ),
              ),
              const SizedBox(height: 2),
              // Display the day number (e.g., "21").
              Text(
                date.day.toString(),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color:
                      isSelected
                          ? Colors.white // White text if selected.
                          : isToday
                          ? AppColors.accent // Accent color if today.
                          : AppColors.textPrimary, // Primary text color otherwise.
                ),
              ),

              // Small dot indicator for "Today" if not selected.
              if (isToday && !isSelected) ...[
                const SizedBox(height: 2),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ] else
                const SizedBox(height: 6), // Spacer if no dot.
            ],
          ),
        ),
      ),
    );
  }

  // Builds the main timeline view, displaying tasks by hour.
  Widget _buildTimeline(List<TaskModel> tasks) {
    // Use filtered tasks if filters are active, otherwise use all tasks for the day.
    final displayTasks = _hasActiveFilters() ? _filteredTasks : tasks;
    final now = DateTime.now();
    final isToday = _isSameDay(_selectedDate, now); // Check if the selected date is today.

    return Stack(
      children: [
        // The main scrollable list of hourly slots.
        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(top: 16, bottom: 100), // Padding for content.
          itemCount: 24, // 24 hours in a day.
          itemBuilder: (context, index) {
            final hour = index;
            // Filter tasks that are due in the current hour.
            final hourTasks =
                displayTasks.where((task) {
                  return task.dueDate?.hour == hour;
                }).toList();

            // Build each hourly time slot.
            return _buildTimeSlot(hour, hourTasks, isToday && now.hour == hour);
          },
        ),

        // Current time indicator line, only visible for today's date.
        if (isToday)
          StreamBuilder(
            stream: Stream.periodic(const Duration(minutes: 1)), // Update every minute.
            builder: (context, snapshot) {
              final currentTime = DateTime.now();
              final currentMinute = currentTime.minute;
              final hourProgress = currentMinute / 60.0; // Progress within the current hour.

              double position = 16; // Initial offset.
              // Calculate vertical position based on previous hour slots and tasks.
              for (int i = 0; i < currentTime.hour; i++) {
                final hourTaskCount =
                    displayTasks.where((t) => t.dueDate?.hour == i).length;
                position += hourTaskCount == 0 ? 80 : 80 + (hourTaskCount * 58); // Adjust height based on tasks.
              }
              position += hourProgress * 80; // Add progress within current hour.

              return Positioned(
                top: position,
                left: 60, // Aligned with the timeline.
                right: 0,
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.currentTimeIndicator,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.currentTimeIndicator.withAlpha(
                              100,
                            ),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1.5,
                        color: AppColors.currentTimeIndicator.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // Builds a single hourly time slot in the timeline.
  Widget _buildTimeSlot(int hour, List<TaskModel> tasks, bool isCurrentHour) {
    return IntrinsicHeight(
      child: Container(
        constraints: const BoxConstraints(minHeight: 90), // Minimum height for each slot.
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time label on the left side of the timeline.
            GestureDetector(
              onTap: () => _showQuickAddMenu(hour), // Tap to quickly add task/note.
              behavior: HitTestBehavior.opaque, // Ensure the whole area is tappable.
              child: Container(
                width: 70,
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color:
                          isCurrentHour
                              ? AppColors.currentTimeIndicator.withAlpha(100) // Highlight if current hour.
                              : AppColors.timelineLineColor, // Regular timeline line.
                      width: isCurrentHour ? 2 : 1, // Thicker line for current hour.
                    ),
                  ),
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${hour.toString().padLeft(2, '0')}:00', // Format hour (e.g., "09:00").
                      style: TextStyle(
                        fontSize: isCurrentHour ? 17 : 15, // Larger font for current hour.
                        fontWeight:
                            isCurrentHour ? FontWeight.w700 : FontWeight.w500, // Bolder for current hour.
                        color:
                            isCurrentHour
                                ? AppColors.accent // Accent color for current hour.
                                : AppColors.hourTextColor, // Regular color otherwise.
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Area where tasks for this hour are displayed.
            Expanded(
              child: GestureDetector(
                onTap: tasks.isEmpty ? () => _showQuickAddMenu(hour) : null, // Tap empty space to add.
                behavior: HitTestBehavior.translucent, // Allow taps to pass through transparent areas.
                child: Container(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: 12,
                  ),
                  child:
                      tasks.isEmpty
                          ? _buildEmptySlot() // Show empty slot indicator if no tasks.
                          : Column(
                            mainAxisAlignment:
                                MainAxisAlignment.start, // Align tasks to the top.
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Iterate through tasks and build their compact blocks.
                              for (int i = 0; i < tasks.length; i++) ...[
                                if (tasks[i].isNote)
                                  _buildCompactNoteBlock(tasks[i]) // Build note block if it's a note.
                                else
                                  _buildCompactTaskBlock(tasks[i]), // Build task block otherwise.
                                if (i < tasks.length - 1)
                                  const SizedBox(height: 10), // Spacer between tasks.
                              ],
                            ],
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds a simplified empty slot indicator with a plus icon.
  Widget _buildEmptySlot() {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), // Smooth animation.
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.divider.withAlpha(20), // Subtle background.
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.divider.withAlpha(40), width: 1), // Light border.
        ),
        child: Icon(
          CupertinoIcons.plus, // Plus icon.
          color: AppColors.textTertiary.withAlpha(100), // Faded color.
          size: 18,
        ),
      ),
    );
  }

  // Shows a quick add menu (action sheet) to create a new task or note at a specific hour.
  void _showQuickAddMenu(int hour) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: Text(
              'Add at ${hour.toString().padLeft(2, '0')}:00', // Display the selected hour.
              style: const TextStyle(fontSize: 16),
            ),
            message: Text(
              DateFormat('EEEE, MMM d').format(_selectedDate), // Display the selected date.
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context); // Close the action sheet.
                  _createTaskAtHour(hour); // Create a new task at this hour.
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_square_fill, // Task icon.
                      size: 20,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    const Text('New Task'),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context); // Close the action sheet.
                  _createNoteAtHour(hour); // Create a new note at this hour.
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.doc_text_fill, // Note icon.
                      size: 20,
                      color: AppColors.warning,
                    ),
                    SizedBox(width: 8),
                    Text('New Note'),
                  ],
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context), // Just close the sheet.
              child: const Text('Cancel'),
            ),
          ),
    );
  }

  // Builds a compact display block for a task in the timeline.
  Widget _buildCompactTaskBlock(TaskModel task) {
    // Determine if the task uses a default color or a custom one.
    final isDefaultColor = task.color == '#2C2C2E' || task.color == '#8E8E93';
    final taskColor =
        isDefaultColor
            ? AppColors.textSecondary // Use secondary text color for default.
            : AppColors.fromHex(task.color); // Convert hex to Color object.

    // If the task is actually a note, delegate to the note block builder.
    if (task.isNote) {
      return _buildCompactNoteBlock(task);
    }

    return GestureDetector(
      onLongPress: () => _showTaskOptionsMenu(task), // Show options menu on long press.
      onTap: () {
        context.push('/task-details', extra: task); // Navigate to task details on tap.
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), // Smooth animation for state changes.
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:
              task.isCompleted
                  ? AppColors.surface.withAlpha(150) // Faded background if completed.
                  : isDefaultColor
                  ? AppColors.surfaceLight // Light surface for default color.
                  : taskColor.withAlpha(40), // Semi-transparent custom color.
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                task.isCompleted
                    ? AppColors.divider // Divider color if completed.
                    : isDefaultColor
                    ? AppColors.divider // Divider color for default.
                    : taskColor.withAlpha(150), // More opaque custom color for border.
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Vertical bar indicating task priority.
            Container(
              width: 4,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.getPriorityColor(task.priority), // Color based on priority.
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            // Task title and metadata.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Task title.
                  Text(
                    task.title,
                    style: TextStyle(
                      color:
                          task.isCompleted
                              ? AppColors.textSecondary // Faded text if completed.
                              : AppColors.textPrimary, // Primary text otherwise.
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration:
                          task.isCompleted ? TextDecoration.lineThrough : null, // Strikethrough if completed.
                      decorationColor: AppColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis, // Truncate long titles.
                  ),

                  // Row for time and tags, only shown if they exist.
                  if (task.dueDate != null || task.tags.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Display task time if due date is set.
                        if (task.dueDate != null) ...[
                          const Icon(
                            CupertinoIcons.clock,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('HH:mm').format(task.dueDate!), // Format time (e.g., "14:30").
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        // Display the first tag if tags exist.
                        if (task.tags.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.divider.withAlpha(50), // Subtle background for tag.
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              task.tags.first, // Display only the first tag.
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Checkbox for marking task as complete/incomplete.
            const SizedBox(width: 12),
            CupertinoButton(
              padding: const EdgeInsets.all(4), // Padding for better touch area.
              minSize: 32, // Larger touch area.
              onPressed: () {
                context.read<TaskBloc>().add(ToggleTaskComplete(task.id)); // Dispatch event to toggle completion.
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200), // Smooth animation.
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color:
                      task.isCompleted ? AppColors.accent : Colors.transparent, // Accent color if completed.
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        task.isCompleted ? AppColors.accent : AppColors.divider, // Accent border if completed.
                    width: task.isCompleted ? 0 : 2, // Thicker border if not completed.
                  ),
                ),
                child:
                    task.isCompleted
                        ? const Icon(
                          CupertinoIcons.checkmark, // Checkmark icon if completed.
                          size: 16,
                          color: Colors.white,
                        )
                        : null, // No child if not completed.
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds a compact display block for a note in the timeline.
  Widget _buildCompactNoteBlock(TaskModel note) {
    final noteColor = AppColors.fromHex(note.color); // Get the color from the note's hex string.

    return GestureDetector(
      onLongPress: () => _showNoteOptionsMenu(note), // Show options menu on long press.
      onTap: () => context.push('/edit-note', extra: note), // Navigate to edit note screen on tap.
      child: Container(
        margin: const EdgeInsets.only(bottom: 10), // Space below each note block.
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: noteColor.withAlpha(40), // Semi-transparent background with note's color.
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: noteColor.withAlpha(150), width: 1), // Border with note's color.
        ),
        child: Row(
          children: [
            // Note icon.
            Icon(CupertinoIcons.doc_text_fill, size: 20, color: noteColor),
            const SizedBox(width: 12),

            // Note title and content preview.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis, // Truncate long titles.
                  ),
                  // Show a preview of the markdown content if it exists.
                  if (note.markdownContent?.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      note.markdownContent!.replaceAll('\n', ' '), // Replace newlines for single-line preview.
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis, // Truncate long content.
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Navigates to the create task screen with the selected date and hour pre-filled.
  void _createTaskAtHour(int hour) {
    final dateString = _selectedDate.toIso8601String(); // Convert date to string for URL parameter.
    context.push('/create-task?hour=$hour&date=$dateString');
  }

  // Navigates to the create note screen with the selected date and hour pre-filled.
  void _createNoteAtHour(int hour) {
    final dateString = _selectedDate.toIso8601String(); // Convert date to string for URL parameter.
    context.push('/create-note?hour=$hour&date=$dateString');
  }

  // Helper method to check if two DateTime objects represent the same day (ignoring time).
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
