import 'package:dayflow/data/models/habit_instance_model.dart';
import 'package:dayflow/data/models/habit_model.dart';
import 'package:dayflow/presentation/blocs/habits/habit_bloc.dart';
import 'package:dayflow/presentation/blocs/settings/settings_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
import 'package:dayflow/presentation/screens/search/app_search_delegate.dart';
import 'package:dayflow/presentation/widgets/speed_dial_fab.dart';
import 'package:dayflow/presentation/widgets/status_bar_padding.dart';
import 'package:dayflow/presentation/widgets/universal_filter_modal.dart';
import 'package:flutter/material.dart' hide SearchDelegate;
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
import 'widgets/sheets/home_habit_options_sheet.dart';
import 'widgets/sheets/home_note_options_sheet.dart';
import 'widgets/sheets/home_quick_add_sheet.dart';
import 'widgets/sheets/home_task_options_sheet.dart';
import 'widgets/timeline/home_timeline.dart';
import 'widgets/timeline/home_time_slot.dart';

extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _selectedDate;
  late final ScrollController _scrollController;
  late UniversalFilterOptions _currentFilters;
  List<TaskModel> _filteredTasks = [];
  List<HabitWithInstance> _filteredHabits = [];

  static const double _hourHeight = 80.0;
  static const double _scrollOffset = 200.0;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _scrollController = ScrollController();
    _currentFilters = const UniversalFilterOptions();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
      context.read<HabitBloc>().add(LoadHabitInstances(_selectedDate));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentTime() {
    if (!_scrollController.hasClients) return;

    final scrollPosition = (DateTime.now().hour * _hourHeight) - _scrollOffset;
    _scrollController.animateTo(
      scrollPosition.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _openSearch() async {
    await showSearch<void>(context: context, delegate: AppSearchDelegate());
  }

  Future<void> _openFilterModal() async {
    final taskState = context.read<TaskBloc>().state;
    final habitState = context.read<HabitBloc>().state;

    final allTags = <String>{};

    if (taskState is TaskLoaded) {
      for (final task in taskState.tasks) {
        allTags.addAll(task.tags);
      }
    }

    if (habitState is HabitLoaded) {
      for (final habit in habitState.habits) {
        allTags.addAll(habit.tags);
      }
    }

    final result = await showModalBottomSheet<UniversalFilterOptions>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => UniversalFilterModal(
            initialFilters: _currentFilters,
            availableTags: allTags.toList()..sort(),
          ),
    );

    if (result != null) {
      setState(() {
        _currentFilters = result;
        _applyFilters();
      });
    }
  }

  void _applyFilters() {
    final taskState = context.read<TaskBloc>().state;
    final habitState = context.read<HabitBloc>().state;

    if (taskState is TaskLoaded) {
      var filteredTasks =
          taskState.tasks.where((task) => !task.isDeleted).toList();

      if (!_currentFilters.showTasks && !_currentFilters.showNotes) {
        filteredTasks = [];
      } else {
        if (!_currentFilters.showTasks) {
          filteredTasks = filteredTasks.where((task) => task.isNote).toList();
        }
        if (!_currentFilters.showNotes) {
          filteredTasks = filteredTasks.where((task) => !task.isNote).toList();
        }
      }

      if (_currentFilters.priorities.isNotEmpty) {
        filteredTasks =
            filteredTasks
                .where(
                  (task) => _currentFilters.priorities.contains(task.priority),
                )
                .toList();
      }

      if (_currentFilters.isCompleted != null) {
        filteredTasks =
            filteredTasks
                .where(
                  (task) => task.isCompleted == _currentFilters.isCompleted,
                )
                .toList();
      }

      if (_currentFilters.tagFilters.isNotEmpty) {
        filteredTasks =
            filteredTasks.where((task) {
              return task.tags.any(
                (tag) => _currentFilters.tagFilters.contains(tag),
              );
            }).toList();
      }

      if (_currentFilters.timeRange != null) {
        filteredTasks = _filterTasksByTimeRange(filteredTasks);
      }

      _sortTasks(filteredTasks);

      setState(() {
        _filteredTasks = filteredTasks;
      });
    }

    if (habitState is HabitLoaded) {
      var filteredHabits = _getHabitsForDate(habitState);

      if (!_currentFilters.showHabits) {
        filteredHabits = [];
      } else {
        if (_currentFilters.frequencies.isNotEmpty) {
          filteredHabits =
              filteredHabits.where((habitWithInstance) {
                return _currentFilters.frequencies.contains(
                  habitWithInstance.habit.frequency,
                );
              }).toList();
        }

        if (_currentFilters.isActive != null) {
          filteredHabits =
              filteredHabits.where((habitWithInstance) {
                return habitWithInstance.habit.isActive ==
                    _currentFilters.isActive;
              }).toList();
        }

        if (_currentFilters.minStreak != null) {
          filteredHabits =
              filteredHabits.where((habitWithInstance) {
                return habitWithInstance.habit.currentStreak >=
                    _currentFilters.minStreak!;
              }).toList();
        }

        if (_currentFilters.tagFilters.isNotEmpty) {
          filteredHabits =
              filteredHabits.where((habitWithInstance) {
                return habitWithInstance.habit.tags.any(
                  (tag) => _currentFilters.tagFilters.contains(tag),
                );
              }).toList();
        }

        _sortHabits(filteredHabits);
      }

      setState(() {
        _filteredHabits = filteredHabits;
      });
    }
  }

  List<TaskModel> _filterTasksByTimeRange(List<TaskModel> tasks) {
    final now = DateTime.now();
    return tasks.where((task) {
      if (task.dueDate == null) return false;

      switch (_currentFilters.timeRange!) {
        case TimeRangeFilter.thisWeek:
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          final weekEnd = weekStart.add(const Duration(days: 6));
          return task.dueDate!.isAfter(
                weekStart.subtract(const Duration(days: 1)),
              ) &&
              task.dueDate!.isBefore(weekEnd.add(const Duration(days: 1)));
        case TimeRangeFilter.nextWeek:
          final nextWeekStart = now.add(Duration(days: 7 - now.weekday + 1));
          final nextWeekEnd = nextWeekStart.add(const Duration(days: 6));
          return task.dueDate!.isAfter(
                nextWeekStart.subtract(const Duration(days: 1)),
              ) &&
              task.dueDate!.isBefore(nextWeekEnd.add(const Duration(days: 1)));
        case TimeRangeFilter.lastWeek:
          final lastWeekStart = now.subtract(Duration(days: now.weekday + 6));
          final lastWeekEnd = lastWeekStart.add(const Duration(days: 6));
          return task.dueDate!.isAfter(
                lastWeekStart.subtract(const Duration(days: 1)),
              ) &&
              task.dueDate!.isBefore(lastWeekEnd.add(const Duration(days: 1)));
        case TimeRangeFilter.thisMonth:
          return task.dueDate!.year == now.year &&
              task.dueDate!.month == now.month;
        case TimeRangeFilter.nextMonth:
          final nextMonth = DateTime(now.year, now.month + 1);
          return task.dueDate!.year == nextMonth.year &&
              task.dueDate!.month == nextMonth.month;
        case TimeRangeFilter.lastMonth:
          final lastMonth = DateTime(now.year, now.month - 1);
          return task.dueDate!.year == lastMonth.year &&
              task.dueDate!.month == lastMonth.month;
      }
    }).toList();
  }

  void _sortTasks(List<TaskModel> tasks) {
    switch (_currentFilters.sortBy) {
      case SortBy.date:
        if (_currentFilters.sortAscending) {
          tasks.sort(
            (a, b) =>
                (a.dueDate ?? a.createdAt).compareTo(b.dueDate ?? b.createdAt),
          );
        } else {
          tasks.sort(
            (a, b) =>
                (b.dueDate ?? b.createdAt).compareTo(a.dueDate ?? a.createdAt),
          );
        }
        break;
      case SortBy.alphabetical:
        if (_currentFilters.sortAscending) {
          tasks.sort((a, b) => a.title.compareTo(b.title));
        } else {
          tasks.sort((a, b) => b.title.compareTo(a.title));
        }
        break;
      case SortBy.priority:
        if (_currentFilters.sortAscending) {
          tasks.sort((a, b) => a.priority.compareTo(b.priority));
        } else {
          tasks.sort((a, b) => b.priority.compareTo(a.priority));
        }
        break;
      case SortBy.streak:
        break;
    }
  }

  void _sortHabits(List<HabitWithInstance> habits) {
    switch (_currentFilters.sortBy) {
      case SortBy.date:
        if (_currentFilters.sortAscending) {
          habits.sort((a, b) => a.habit.createdAt.compareTo(b.habit.createdAt));
        } else {
          habits.sort((a, b) => b.habit.createdAt.compareTo(a.habit.createdAt));
        }
        break;
      case SortBy.alphabetical:
        if (_currentFilters.sortAscending) {
          habits.sort((a, b) => a.habit.title.compareTo(b.habit.title));
        } else {
          habits.sort((a, b) => b.habit.title.compareTo(a.habit.title));
        }
        break;
      case SortBy.priority:
      case SortBy.streak:
        if (_currentFilters.sortAscending) {
          habits.sort(
            (a, b) => a.habit.currentStreak.compareTo(b.habit.currentStreak),
          );
        } else {
          habits.sort(
            (a, b) => b.habit.currentStreak.compareTo(a.habit.currentStreak),
          );
        }
        break;
    }
  }

  bool _hasActiveFilters() {
    return _currentFilters.hasActiveFilters;
  }

  void _completeHabitInstance(HabitInstanceModel instance) {
    HapticFeedback.lightImpact();
    context.read<HabitBloc>().add(CompleteHabitInstance(instance.id));
    CustomSnackBar.success(context, 'Habit completed! 🎉');
  }

  void _uncompleteHabitInstance(HabitInstanceModel instance) {
    HapticFeedback.lightImpact();
    context.read<HabitBloc>().add(UncompleteHabitInstance(instance.id));
    CustomSnackBar.info(context, 'Habit marked as pending');
  }

  void _updateHabitInstance(HabitInstanceModel instance) {
    HapticFeedback.lightImpact();
    context.read<HabitBloc>().add(UpdateHabitInstance(instance));
  }

  void _showHabitOptionsMenu(HabitModel habit) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => HomeHabitOptionsSheet(
            habit: habit,
            onEdit: () {
              Navigator.pop(context);
              context.push('/edit-habit', extra: habit);
            },
            onViewStats: () {
              Navigator.pop(context);
              context.push('/habit-stats', extra: habit);
            },
            onPause: () {
              Navigator.pop(context);
              CustomSnackBar.info(context, 'Habit paused');
            },
            onDelete: () {
              Navigator.pop(context);
              _confirmDeleteHabit(habit);
            },
          ),
    );
  }

  void _confirmDeleteHabit(HabitModel habit) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => HomeConfirmDeleteDialog(
            title: 'Delete Habit',
            content: 'Are you sure you want to delete "${habit.title}"?',
            subtitle: 'This will delete all associated records',
            onDelete: () => _deleteHabit(habit),
          ),
    );
  }

  void _deleteHabit(HabitModel habit) {
    context.read<HabitBloc>().add(DeleteHabit(habit.id));
    CustomSnackBar.success(context, 'Habit deleted successfully');
  }

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

  void _deleteNote(TaskModel note) {
    context.read<TaskBloc>().add(DeleteTask(note.id));
    CustomSnackBar.success(context, 'Note deleted successfully');
  }

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

  void _toggleTaskCompletion(TaskModel task) {
    HapticFeedback.lightImpact();
    context.read<TaskBloc>().add(ToggleTaskComplete(task.id));
    CustomSnackBar.success(
      context,
      task.isCompleted ? 'Task marked as pending' : 'Task completed! 🎉',
    );
  }

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

  void _deleteTask(TaskModel task) {
    context.read<TaskBloc>().add(DeleteTask(task.id));
    CustomSnackBar.success(context, 'Task deleted successfully');
  }

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

  void _showQuickAddMenu(int hour) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => HomeQuickAddSheet(
            hour: hour,
            selectedDate: _selectedDate,
            onCreateTask: _createTaskAtHour,
            onCreateNote: _createNoteAtHour,
            onCreateHabit: _createHabitAtHour,
          ),
    );
  }

  void _createTaskAtHour(int hour) {
    final dateString = _selectedDate.toIso8601String();
    context.push('/create-task?hour=$hour&date=$dateString');
  }

  void _createNoteAtHour(int hour) {
    final dateString = _selectedDate.toIso8601String();
    context.push('/create-note?hour=$hour&date=$dateString');
  }

  void _createHabitAtHour(int hour) {
    context.push('/create-habit?hour=$hour');
  }

  void _handleTaskTimeChanged(TaskModel task, int newHour) {
    context.read<TaskBloc>().add(UpdateTask(task));
    CustomSnackBar.success(
      context,
      'Task moved to ${newHour.toString().padLeft(2, '0')}:00',
    );
  }

  void _handleHabitTimeChanged(HabitModel habit, int newHour) {
    context.read<HabitBloc>().add(UpdateHabit(habit));
    CustomSnackBar.success(
      context,
      'Habit moved to ${newHour.toString().padLeft(2, '0')}:00',
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<HabitWithInstance> _getHabitsForDate(HabitLoaded habitState) {
    final dayHabits = <HabitWithInstance>[];
    final selectedDateOnly = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    for (final habit in habitState.activeHabits) {
      if (_hasHabitEnded(habit, selectedDateOnly)) continue;

      if (!_shouldShowHabitOnDate(habit, _selectedDate)) continue;

      final instance =
          habitState.todayInstances
              .where(
                (inst) =>
                    inst.habitId == habit.id &&
                    _isSameDay(inst.date, _selectedDate),
              )
              .firstOrNull;

      final finalInstance =
          instance ??
          HabitInstanceModel(
            habitId: habit.id,
            date: _selectedDate,
            status: HabitInstanceStatus.pending,
          );

      dayHabits.add(HabitWithInstance(habit: habit, instance: finalInstance));
    }

    return dayHabits;
  }

  bool _hasHabitEnded(HabitModel habit, DateTime selectedDate) {
    switch (habit.endCondition) {
      case HabitEndCondition.onDate:
        if (habit.endDate != null) {
          final endDateOnly = DateTime(
            habit.endDate!.year,
            habit.endDate!.month,
            habit.endDate!.day,
          );
          return selectedDate.isAfter(endDateOnly);
        }
        break;
      case HabitEndCondition.afterCount:
        if (habit.targetCount != null) {
          return habit.totalCompletions >= habit.targetCount!;
        }
        break;
      case HabitEndCondition.never:
      case HabitEndCondition.manual:
        return false;
    }
    return false;
  }

  bool _shouldShowHabitOnDate(HabitModel habit, DateTime date) {
    final startDateOnly = DateTime(
      habit.startDate.year,
      habit.startDate.month,
      habit.startDate.day,
    );
    final selectedDateOnly = DateTime(date.year, date.month, date.day);

    if (selectedDateOnly.isBefore(startDateOnly)) {
      return false;
    }

    switch (habit.frequency) {
      case HabitFrequency.daily:
        return true;
      case HabitFrequency.weekly:
        return habit.weekdays?.contains(date.weekday) ?? false;
      case HabitFrequency.monthly:
        final targetDay = habit.monthDay ?? 1;
        final lastDayOfMonth = DateTime(date.year, date.month + 1, 0).day;
        final adjustedTargetDay =
            targetDay > lastDayOfMonth ? lastDayOfMonth : targetDay;
        return date.day == adjustedTargetDay;
      case HabitFrequency.custom:
        if (habit.customInterval == null) return false;
        final referenceDate = startDateOnly;
        final daysDifference =
            selectedDateOnly.difference(referenceDate).inDays;
        return daysDifference >= 0 &&
            daysDifference % habit.customInterval! == 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              const StatusBarPadding(),
              HomeHeader(
                selectedDate: _selectedDate,
                onDateSelected: (date) {
                  setState(() => _selectedDate = date);
                  context.read<TaskBloc>().add(LoadTasksByDate(date));
                  context.read<HabitBloc>().add(LoadHabitInstances(date));
                  _scrollToCurrentTime();
                },
                hasActiveFilters: _hasActiveFilters(),
                onFilterPressed: _openFilterModal,
                onSearchPressed: _openSearch,
              ),
              HomeDateSelector(
                selectedDate: _selectedDate,
                onDateSelected: (date) {
                  setState(() => _selectedDate = date);
                  context.read<TaskBloc>().add(LoadTasksByDate(date));
                  context.read<HabitBloc>().add(LoadHabitInstances(date));
                },
              ),
              Container(height: 0.5, color: AppColors.divider),
              Expanded(
                child: BlocBuilder<TaskBloc, TaskState>(
                  builder: (context, taskState) {
                    return BlocBuilder<HabitBloc, HabitState>(
                      builder: (context, habitState) {
                        final dayTasks =
                            taskState is TaskLoaded
                                ? taskState.tasks
                                    .where(
                                      (task) =>
                                          task.dueDate != null &&
                                          _isSameDay(
                                            task.dueDate!,
                                            _selectedDate,
                                          ),
                                    )
                                    .toList()
                                : <TaskModel>[];

                        final dayHabits =
                            habitState is HabitLoaded
                                ? _getHabitsForDate(habitState)
                                : <HabitWithInstance>[];

                        return HomeTimeline(
                          scrollController: _scrollController,
                          selectedDate: _selectedDate,
                          tasks: dayTasks,
                          habits: dayHabits,
                          filteredTasks:
                              _hasActiveFilters() ? _filteredTasks : dayTasks,
                          filteredHabits:
                              _hasActiveFilters() ? _filteredHabits : dayHabits,
                          hasActiveFilters: _hasActiveFilters(),
                          onQuickAddMenu: _showQuickAddMenu,
                          onTaskToggled: _toggleTaskCompletion,
                          onTaskOptions: _showTaskOptionsMenu,
                          onNoteOptions: _showNoteOptionsMenu,
                          onHabitComplete: _completeHabitInstance,
                          onHabitUncomplete: _uncompleteHabitInstance,
                          onHabitUpdateInstance: _updateHabitInstance,
                          onHabitOptions: _showHabitOptionsMenu,
                          onDateChanged: (newDate) {
                            setState(() => _selectedDate = newDate);
                            context.read<HabitBloc>().add(
                              LoadHabitInstances(newDate),
                            );
                          },
                          onTaskTimeChanged: _handleTaskTimeChanged,
                          onHabitTimeChanged: _handleHabitTimeChanged,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: SpeedDialFab(
            onCreateTask: () => context.push('/create-task'),
            onCreateNote: () => context.push('/create-note'),
            onCreateHabit: () => context.push('/create-habit'),
          ),
        );
      },
    );
  }
}
