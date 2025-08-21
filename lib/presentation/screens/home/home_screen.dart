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
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/custom_snackbar.dart';
import '../../../data/models/task_model.dart';
import 'widgets/date_selector/home_date_selector.dart';
import 'widgets/home_header.dart';
import 'widgets/sheets/home_confirm_delete_dialog.dart';
import 'widgets/sheets/home_note_options_sheet.dart';
import 'widgets/sheets/home_quick_add_sheet.dart';
import 'widgets/sheets/home_task_options_sheet.dart';
import 'widgets/timeline/home_timeline.dart';

/// The main home screen of our app, showing tasks and notes organized by date.
///
/// This screen serves as the primary dashboard where users can view their daily tasks,
/// navigate between dates, filter tasks, and manage their schedule.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// The state for our HomeScreen, managing selected date, filters, and task list.
///
/// This class handles the core functionality of the home screen including:
/// - Date selection and navigation
/// - Task filtering and sorting
/// - Task and note management operations
/// - UI state management
class _HomeScreenState extends State<HomeScreen> {
  /// The date currently selected in the date selector.
  DateTime _selectedDate = DateTime.now();

  /// Controller for the timeline's scroll position.
  final ScrollController _scrollController = ScrollController();

  /// Current filter options applied to tasks.
  TaskFilterOptions _currentFilters = TaskFilterOptions();

  /// The list of tasks after applying filters.
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

  /// Scrolls the timeline to approximately the current hour.
  ///
  /// This method calculates the appropriate scroll position based on the current hour
  /// and animates the timeline to that position with a smooth transition.
  void _scrollToCurrentTime() {
    if (!_scrollController.hasClients) {
      return; // Don't scroll if controller isn't attached.
    }

    final now = DateTime.now();
    // Calculate scroll position: each hour slot is about 80 pixels.
    final scrollPosition =
        (now.hour * 80.0) - 200; // Offset to show some hours before current.

    _scrollController.animateTo(
      scrollPosition.clamp(
        0,
        _scrollController.position.maxScrollExtent,
      ), // Keep scroll within bounds.
      duration: const Duration(milliseconds: 800), // Smooth animation duration.
      curve: Curves.easeInOutCubic, // Animation curve.
    );
  }

  /// Opens the search delegate to allow users to search for tasks.
  ///
  /// This method presents a search interface and navigates to the task details
  /// if a task is selected from the search results.
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

  /// Checks if any filters are currently active.
  ///
  /// Returns true if any of the filter options (date, priority, completion, tags)
  /// have been set by the user.
  bool _hasActiveFilters() {
    return _currentFilters.dateFilter != null ||
        _currentFilters.priorityFilter != null ||
        _currentFilters.completedFilter != null ||
        _currentFilters.tagFilters.isNotEmpty;
  }

  /// Opens the modal bottom sheet for task filtering options.
  ///
  /// This method collects all available tags from the loaded tasks and presents
  /// a filter modal sheet. If new filters are selected, it updates the state
  /// and reapplies the filters to the task list.
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
      backgroundColor:
          Colors.transparent, // Transparent background for custom styling.
      builder:
          (context) => TaskFilterModal(
            initialFilters:
                _currentFilters, // Pass current filters to pre-select.
            availableTags:
                allTags.toList()..sort(), // Pass available tags, sorted.
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

  /// Applies the currently selected filters to the list of tasks.
  ///
  /// This method processes the task list based on the current filter options,
  /// including date filters, priority filters, completion status, and tag filters.
  /// It also applies sorting based on the selected sort option.
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
              if (task.dueDate == null) {
                return false; // Tasks without due dates are excluded.
              }
              switch (_currentFilters.dateFilter!) {
                case DateFilter.today:
                  return _isSameDay(
                    task.dueDate!,
                    now,
                  ); // Check if due date is today.
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
                if (task.tags.contains(tag)) {
                  return true; // Task must have at least one selected tag.
                }
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

  /// Shows a confirmation dialog before deleting a note.
  void _confirmDeleteNote(TaskModel note) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => HomeConfirmDeleteDialog(
            title: 'Delete Note',
            content: 'Are you sure you want to delete "${note.title}"?',
            onDelete: () => _deleteNote(note),
          ),
    );
  }

  /// Deletes a note by dispatching a DeleteTask event to the TaskBloc.
  void _deleteNote(TaskModel note) {
    context.read<TaskBloc>().add(DeleteTask(note.id));
    CustomSnackBar.success(
      context,
      'Note deleted successfully',
    ); // Show success message.
  }

  /// Duplicates a note by creating a new TaskModel and adding it to the TaskBloc.
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
    CustomSnackBar.success(
      context,
      'Note duplicated successfully',
    ); // Show success message.
  }

  /// Toggles the completion status of a task and provides haptic feedback.
  void _toggleTaskCompletion(TaskModel task) {
    HapticFeedback.lightImpact(); // Provide a subtle vibration.
    context.read<TaskBloc>().add(
      ToggleTaskComplete(task.id),
    ); // Dispatch event to update task.
    CustomSnackBar.success(
      context,
      task.isCompleted
          ? 'Task marked as pending'
          : 'Task completed! 🎉', // Show appropriate message.
    );
  }

  /// Shows a confirmation dialog before deleting a task.
  void _confirmDeleteTask(TaskModel task) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => HomeConfirmDeleteDialog(
            title: 'Delete Task',
            content: 'Are you sure you want to delete "${task.title}"?',
            subtitle:
                task.description?.isNotEmpty == true ? task.description : null,
            onDelete: () => _deleteTask(task),
          ),
    );
  }

  /// Deletes a task by dispatching a DeleteTask event to the TaskBloc.
  void _deleteTask(TaskModel task) {
    context.read<TaskBloc>().add(DeleteTask(task.id));
    CustomSnackBar.success(
      context,
      'Task deleted successfully',
    ); // Show success message.
  }

  /// Duplicates a task by creating a new TaskModel and adding it to the TaskBloc.
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
    CustomSnackBar.success(
      context,
      'Task duplicated successfully',
    ); // Show success message.
  }

  /// Shows a quick add menu (action sheet) to create a new task or note at a specific hour.
  void _showQuickAddMenu(int hour) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => HomeQuickAddSheet(
            hour: hour,
            selectedDate: _selectedDate,
            onCreateTask: _createTaskAtHour,
            onCreateNote: _createNoteAtHour,
          ),
    );
  }

  /// Navigates to the create task screen with the selected date and hour pre-filled.
  void _createTaskAtHour(int hour) {
    final dateString =
        _selectedDate
            .toIso8601String(); // Convert date to string for URL parameter.
    context.push('/create-task?hour=$hour&date=$dateString');
  }

  /// Navigates to the create note screen with the selected date and hour pre-filled.
  void _createNoteAtHour(int hour) {
    final dateString =
        _selectedDate
            .toIso8601String(); // Convert date to string for URL parameter.
    context.push('/create-note?hour=$hour&date=$dateString');
  }

  /// Helper method to check if two DateTime objects represent the same day (ignoring time).
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // The header section of the home screen.
            HomeHeader(
              selectedDate: _selectedDate,
              onDateSelected: (date) {
                setState(() => _selectedDate = date);
                context.read<TaskBloc>().add(LoadTasksByDate(date));
                _scrollToCurrentTime();
              },
              hasActiveFilters: _hasActiveFilters(),
              onFilterPressed: _openFilterModal,
              onSearchPressed: _openSearch,
            ),

            // Horizontal date selector for navigating days.
            HomeDateSelector(
              selectedDate: _selectedDate,
              onDateSelected: (date) {
                setState(() => _selectedDate = date);
                context.read<TaskBloc>().add(LoadTasksByDate(date));
              },
            ),

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

                  return HomeTimeline(
                    scrollController: _scrollController,
                    selectedDate: _selectedDate,
                    tasks: dayTasks,
                    filteredTasks:
                        _hasActiveFilters() ? _filteredTasks : dayTasks,
                    hasActiveFilters: _hasActiveFilters(),
                    onQuickAddMenu: _showQuickAddMenu,
                    onTaskToggled: _toggleTaskCompletion,
                    onTaskOptions: _showTaskOptionsMenu,
                    onNoteOptions: _showNoteOptionsMenu,
                  ); // Build the timeline with relevant tasks.
                },
              ),
            ),
          ],
        ),
      ),
      // Floating action button for quickly creating new tasks or notes.
      floatingActionButton: SpeedDialFab(
        onCreateTask:
            () =>
                context.push('/create-task'), // Navigate to create task screen.
        onCreateNote:
            () =>
                context.push('/create-note'), // Navigate to create note screen.
      ),
    );
  }

  /// Shows a Cupertino-style action sheet for note options (edit, duplicate, delete).
  void _showNoteOptionsMenu(TaskModel note) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => HomeNoteOptionsSheet(
            note: note,
            onEdit: () {
              Navigator.pop(context); // Close the action sheet.
              context.push('/edit-note', extra: note);
            },
            onDuplicate: () {
              Navigator.pop(context); // Close the action sheet.
              _duplicateNote(note);
            },
            onDelete: () {
              Navigator.pop(context); // Close the action sheet.
              _confirmDeleteNote(note);
            },
          ),
    );
  }

  /// Shows a Cupertino-style action sheet for task options.
  void _showTaskOptionsMenu(TaskModel task) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => HomeTaskOptionsSheet(
            task: task,
            onToggleComplete: () {
              Navigator.pop(context); // Close the action sheet.
              _toggleTaskCompletion(task);
            },
            onEdit: () {
              Navigator.pop(context); // Close the action sheet.
              context.push('/edit-task', extra: task);
            },
            onViewDetails: () {
              Navigator.pop(context); // Close the action sheet.
              context.push('/task-details', extra: task);
            },
            onDuplicate: () {
              Navigator.pop(context); // Close the action sheet.
              _duplicateTask(task);
            },
            onDelete: () {
              Navigator.pop(context); // Close the action sheet.
              _confirmDeleteTask(task);
            },
          ),
    );
  }
}
