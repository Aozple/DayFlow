import 'package:dayflow/presentation/blocs/settings/settings_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
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

/// Main home screen showing tasks and notes organized by date
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Currently selected date
  DateTime _selectedDate = DateTime.now();

  /// Timeline scroll controller
  final ScrollController _scrollController = ScrollController();

  /// Current filter settings
  TaskFilterOptions _currentFilters = TaskFilterOptions();

  /// Tasks after applying filters
  List<TaskModel> _filteredTasks = [];

  @override
  void initState() {
    super.initState();
    // Scroll to current time after first render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Scrolls timeline to current hour
  void _scrollToCurrentTime() {
    if (!_scrollController.hasClients) {
      return;
    }

    final now = DateTime.now();
    // Each hour is approximately 80 pixels
    final scrollPosition = (now.hour * 80.0) - 200;

    _scrollController.animateTo(
      scrollPosition.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
    );
  }

  /// Opens task search interface
  void _openSearch() async {
    final selectedTask = await showSearch<TaskModel?>(
      context: context,
      delegate: TaskSearchDelegate(),
    );

    if (selectedTask != null && mounted) {
      context.push('/task-details', extra: selectedTask);
    }
  }

  /// Checks if any filters are active
  bool _hasActiveFilters() {
    return _currentFilters.dateFilter != null ||
        _currentFilters.priorityFilter != null ||
        _currentFilters.completedFilter != null ||
        _currentFilters.tagFilters.isNotEmpty;
  }

  /// Opens filter modal
  void _openFilterModal() async {
    // Collect all unique tags
    final allTags = <String>{};
    final state = context.read<TaskBloc>().state;
    if (state is TaskLoaded) {
      for (final task in state.tasks) {
        allTags.addAll(task.tags);
      }
    }

    // Show filter modal
    final result = await showModalBottomSheet<TaskFilterOptions>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => TaskFilterModal(
            initialFilters: _currentFilters,
            availableTags: allTags.toList()..sort(),
          ),
    );

    // Apply new filters if selected
    if (result != null) {
      setState(() {
        _currentFilters = result;
        _applyFilters();
      });
    }
  }

  /// Applies selected filters to task list
  void _applyFilters() {
    final state = context.read<TaskBloc>().state;
    if (state is TaskLoaded) {
      // Start with non-deleted tasks
      var filtered = state.tasks.where((task) => !task.isDeleted).toList();

      // Apply date filter
      if (_currentFilters.dateFilter != null) {
        final now = DateTime.now();
        filtered =
            filtered.where((task) {
              if (task.dueDate == null) {
                return false;
              }
              switch (_currentFilters.dateFilter!) {
                case DateFilter.today:
                  return _isSameDay(task.dueDate!, now);
                case DateFilter.thisWeek:
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
                  return task.dueDate!.year == now.year &&
                      task.dueDate!.month == now.month;
                case DateFilter.custom:
                  return true; // TODO: Implement custom date range filtering
              }
            }).toList();
      }

      // Apply priority filter
      if (_currentFilters.priorityFilter != null) {
        filtered =
            filtered
                .where(
                  (task) => task.priority == _currentFilters.priorityFilter,
                )
                .toList();
      }

      // Apply completion status filter
      if (_currentFilters.completedFilter != null) {
        filtered =
            filtered
                .where(
                  (task) => task.isCompleted == _currentFilters.completedFilter,
                )
                .toList();
      }

      // Apply tag filters
      if (_currentFilters.tagFilters.isNotEmpty) {
        filtered =
            filtered.where((task) {
              for (final tag in _currentFilters.tagFilters) {
                if (task.tags.contains(tag)) {
                  return true;
                }
              }
              return false;
            }).toList();
      }

      // Apply sorting
      switch (_currentFilters.sortBy) {
        case SortOption.dateDesc:
          filtered.sort(
            (a, b) =>
                (b.dueDate ?? b.createdAt).compareTo(a.dueDate ?? a.createdAt),
          );
          break;
        case SortOption.dateAsc:
          filtered.sort(
            (a, b) =>
                (a.dueDate ?? a.createdAt).compareTo(b.dueDate ?? b.createdAt),
          );
          break;
        case SortOption.priorityDesc:
          filtered.sort((a, b) => b.priority.compareTo(a.priority));
          break;
        case SortOption.priorityAsc:
          filtered.sort((a, b) => a.priority.compareTo(b.priority));
          break;
        case SortOption.alphabetical:
          filtered.sort((a, b) => a.title.compareTo(b.title));
          break;
      }

      setState(() {
        _filteredTasks = filtered;
      });
    }
  }

  /// Shows delete note confirmation
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

  /// Deletes a note
  void _deleteNote(TaskModel note) {
    context.read<TaskBloc>().add(DeleteTask(note.id));
    CustomSnackBar.success(context, 'Note deleted successfully');
  }

  /// Duplicates a note
  void _duplicateNote(TaskModel note) {
    final duplicatedNote = TaskModel(
      title: '${note.title} (Copy)',
      markdownContent: note.markdownContent,
      dueDate: note.dueDate,
      color: note.color,
      tags: note.tags,
      isNote: true,
      priority: 1,
    );
    context.read<TaskBloc>().add(AddTask(duplicatedNote));
    CustomSnackBar.success(context, 'Note duplicated successfully');
  }

  /// Toggles task completion status
  void _toggleTaskCompletion(TaskModel task) {
    HapticFeedback.lightImpact();
    context.read<TaskBloc>().add(ToggleTaskComplete(task.id));
    CustomSnackBar.success(
      context,
      task.isCompleted ? 'Task marked as pending' : 'Task completed! 🎉',
    );
  }

  /// Shows delete task confirmation
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

  /// Deletes a task
  void _deleteTask(TaskModel task) {
    context.read<TaskBloc>().add(DeleteTask(task.id));
    CustomSnackBar.success(context, 'Task deleted successfully');
  }

  /// Duplicates a task
  void _duplicateTask(TaskModel task) {
    final duplicatedTask = TaskModel(
      title: '${task.title} (Copy)',
      description: task.description,
      dueDate: task.dueDate,
      priority: task.priority,
      color: task.color,
      tags: task.tags,
      isCompleted: false,
      completedAt: null,
    );
    context.read<TaskBloc>().add(AddTask(duplicatedTask));
    CustomSnackBar.success(context, 'Task duplicated successfully');
  }

  /// Shows quick add menu for specific hour
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

  /// Navigates to create task screen with prefilled time
  void _createTaskAtHour(int hour) {
    final dateString = _selectedDate.toIso8601String();
    context.push('/create-task?hour=$hour&date=$dateString');
  }

  /// Navigates to create note screen with prefilled time
  void _createNoteAtHour(int hour) {
    final dateString = _selectedDate.toIso8601String();
    context.push('/create-note?hour=$hour&date=$dateString');
  }

  /// Checks if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                ),
                color: AppColors.surface.withAlpha(200),
              ),
              // Header with title and actions
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

              // Date selector for navigation
              HomeDateSelector(
                selectedDate: _selectedDate,
                onDateSelected: (date) {
                  setState(() => _selectedDate = date);
                  context.read<TaskBloc>().add(LoadTasksByDate(date));
                },
              ),

              Container(height: 0.5, color: AppColors.divider),

              // Timeline with tasks
              Expanded(
                child: BlocBuilder<TaskBloc, TaskState>(
                  builder: (context, taskState) {
                    List<TaskModel> dayTasks = [];
                    if (taskState is TaskLoaded) {
                      dayTasks =
                          taskState.tasks.where((task) {
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
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: SpeedDialFab(
            onCreateTask: () => context.push('/create-task'),
            onCreateNote: () => context.push('/create-note'),
          ),
        );
      },
    );
  }

  /// Shows note options menu
  void _showNoteOptionsMenu(TaskModel note) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => HomeNoteOptionsSheet(
            note: note,
            onEdit: () {
              Navigator.pop(context);
              context.push('/edit-note', extra: note);
            },
            onDuplicate: () {
              Navigator.pop(context);
              _duplicateNote(note);
            },
            onDelete: () {
              Navigator.pop(context);
              _confirmDeleteNote(note);
            },
          ),
    );
  }

  /// Shows task options menu
  void _showTaskOptionsMenu(TaskModel task) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => HomeTaskOptionsSheet(
            task: task,
            onToggleComplete: () {
              Navigator.pop(context);
              _toggleTaskCompletion(task);
            },
            onEdit: () {
              Navigator.pop(context);
              context.push('/edit-task', extra: task);
            },
            onViewDetails: () {
              Navigator.pop(context);
              context.push('/task-details', extra: task);
            },
            onDuplicate: () {
              Navigator.pop(context);
              _duplicateTask(task);
            },
            onDelete: () {
              Navigator.pop(context);
              _confirmDeleteTask(task);
            },
          ),
    );
  }
}
