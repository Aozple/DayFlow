import 'package:dayflow/presentation/screens/task/widgets/task_details_color_modal.dart';
import 'package:dayflow/presentation/screens/task/widgets/task_details_delete_dialog.dart';
import 'package:dayflow/presentation/screens/task/widgets/task_details_options_modal.dart';
import 'package:dayflow/presentation/screens/task/widgets/task_details_priority_modal.dart';
import 'package:dayflow/presentation/screens/task/widgets/task_details_reschedule_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/core/utils/custom_snackbar.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'widgets/task_details_app_bar.dart';
import 'widgets/task_details_primary_actions.dart';
import 'widgets/task_details_info_section.dart';
import 'widgets/task_details_description.dart';
import 'widgets/task_details_tags.dart';
import 'widgets/task_details_metadata.dart';

/// Screen for displaying the detailed information of a single task.
///
/// This screen provides a comprehensive view of a task's details, including
/// its title, description, schedule, priority, color, and tags. It also
/// provides actions for completing, editing, or deleting the task.
class TaskDetailsScreen extends StatefulWidget {
  /// The task object whose details are to be displayed.
  final TaskModel task;

  const TaskDetailsScreen({super.key, required this.task});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

/// State class for TaskDetailsScreen.
///
/// This class manages the UI state and interactions for the task details screen,
/// including handling task updates and user actions.
class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  /// Holds the current task data, which might be updated by the BLoC.
  late TaskModel _currentTask;

  @override
  void initState() {
    super.initState();
    _currentTask =
        widget.task; // Initialize with the task passed to the widget.
  }

  @override
  Widget build(BuildContext context) {
    // BlocListener listens for changes in the TaskBloc state.
    // If the task is updated (e.g., marked complete), we update our local state.
    return BlocListener<TaskBloc, TaskState>(
      listener: (context, state) {
        if (state is TaskLoaded) {
          // Find the updated version of our task from the loaded tasks.
          final updatedTask = state.tasks.firstWhere(
            (t) => t.id == _currentTask.id,
            orElse:
                () => _currentTask, // Fallback to current task if not found.
          );
          // If the task has actually changed, update the UI.
          if (updatedTask != _currentTask) {
            setState(() {
              _currentTask = updatedTask;
            });
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(), // iOS-style scroll physics.
          slivers: [
            // A custom app bar that expands and collapses.
            TaskDetailsAppBar(
              task: _currentTask,
              onBackPressed: () => context.pop(),
              onMoreOptions: _showMoreOptions,
            ),
            // The main content of the task details screen.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section for primary actions (complete, edit, delete).
                    TaskDetailsPrimaryActions(
                      task: _currentTask,
                      onToggleComplete: _toggleComplete,
                      onEdit: _editTask,
                      onDelete: _deleteTask,
                    ),
                    const SizedBox(height: 20),
                    // Section displaying task information (date, priority, color).
                    TaskDetailsInfoSection(
                      task: _currentTask,
                      onReschedule: _quickReschedule,
                      onChangePriority: _quickChangePriority,
                      onChangeColor: _quickChangeColor,
                    ),
                    // Description section, only shown if a description exists.
                    if (_currentTask.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 16),
                      TaskDetailsDescription(
                        description: _currentTask.description!,
                      ),
                    ],
                    // Tags section, only shown if tags exist.
                    if (_currentTask.tags.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      TaskDetailsTags(tags: _currentTask.tags),
                    ],
                    const SizedBox(height: 16),
                    // Metadata section (created at, completed at).
                    TaskDetailsMetadata(task: _currentTask),
                    const SizedBox(height: 80), // Extra space at the bottom.
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Toggles the completion status of the current task.
  void _toggleComplete() {
    context.read<TaskBloc>().add(
      ToggleTaskComplete(_currentTask.id),
    ); // Dispatch event to BLoC.
    setState(() {
      _currentTask = _currentTask.copyWith(
        isCompleted: !_currentTask.isCompleted, // Flip completion status.
        completedAt:
            !_currentTask.isCompleted
                ? DateTime.now()
                : null, // Set/clear completion timestamp.
      );
    });
    CustomSnackBar.success(
      context,
      _currentTask.isCompleted
          ? 'Task completed!'
          : 'Task marked as pending', // Show appropriate message.
    );
  }

  /// Navigates to the edit task screen with the current task data.
  void _editTask() {
    context.push('/edit-task', extra: _currentTask);
  }

  /// Shows a confirmation dialog before deleting the task.
  void _deleteTask() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder:
          (context) => TaskDetailsDeleteDialog(taskTitle: _currentTask.title),
    );

    // If deletion is confirmed and widget is still mounted, delete the task.
    if (confirmed == true && mounted) {
      context.read<TaskBloc>().add(
        DeleteTask(_currentTask.id),
      ); // Dispatch delete event.
      CustomSnackBar.success(context, 'Task deleted'); // Show success message.
      context.pop(); // Pop the details screen.
    }
  }

  /// Shows a Cupertino modal for quickly rescheduling a task.
  void _quickReschedule() async {
    final DateTime? picked = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder:
          (context) => TaskDetailsRescheduleModal(
            currentTask: _currentTask,
            onDateChanged: (date) {
              setState(() {
                _currentTask = _currentTask.copyWith(dueDate: date);
              });
            },
          ),
    );

    // If a date was picked and the widget is still mounted, update the task.
    if (picked != null && mounted) {
      context.read<TaskBloc>().add(
        UpdateTask(_currentTask),
      ); // Dispatch update event.
      CustomSnackBar.success(context, 'Date updated'); // Show success message.
    }
  }

  /// Shows a Cupertino action sheet for quickly changing task priority.
  void _quickChangePriority() {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => TaskDetailsPriorityModal(
            currentTask: _currentTask,
            onPriorityChanged: (priority) {
              setState(() {
                _currentTask = _currentTask.copyWith(priority: priority);
              });
              context.read<TaskBloc>().add(UpdateTask(_currentTask));
              CustomSnackBar.success(context, 'Priority updated');
            },
          ),
    );
  }

  /// Shows a Cupertino modal for quickly changing task color.
  void _quickChangeColor() {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => TaskDetailsColorModal(
            currentTask: _currentTask,
            onColorChanged: (color) {
              setState(() {
                _currentTask = _currentTask.copyWith(color: color);
              });
              context.read<TaskBloc>().add(UpdateTask(_currentTask));
              CustomSnackBar.success(context, 'Color updated');
            },
          ),
    );
  }

  /// Shows an action sheet with more options for the task (duplicate, share).
  void _showMoreOptions() {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => TaskDetailsOptionsModal(
            onDuplicate: _duplicateTask,
            onShare: () {
              CustomSnackBar.info(context, 'Share coming soon!');
            },
          ),
    );
  }

  /// Duplicates the current task and adds it as a new task.
  void _duplicateTask() {
    final newTask = TaskModel(
      title: '${_currentTask.title} (Copy)', // Add "(Copy)" to the title.
      description: _currentTask.description,
      dueDate: _currentTask.dueDate,
      priority: _currentTask.priority,
      color: _currentTask.color,
      tags: _currentTask.tags,
    );
    context.read<TaskBloc>().add(AddTask(newTask)); // Dispatch add event.
    CustomSnackBar.success(
      context,
      'Task duplicated!',
    ); // Show success message.
    context.pop(); // Pop the details screen.
  }
}
