import 'package:dayflow/presentation/screens/task/widgets/task_details_color_modal.dart';
import 'package:dayflow/presentation/screens/task/widgets/task_details_delete_dialog.dart';
import 'package:dayflow/presentation/screens/task/widgets/task_details_options_modal.dart';
import 'package:dayflow/presentation/screens/task/widgets/task_details_priority_modal.dart';
import 'package:dayflow/presentation/screens/task/widgets/task_details_reschedule_modal.dart';
import 'package:dayflow/presentation/widgets/status_bar_padding.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/core/utils/custom_snackbar.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'widgets/task_details_header.dart';
import 'widgets/task_details_primary_actions.dart';
import 'widgets/task_details_info_section.dart';
import 'widgets/task_details_description.dart';
import 'widgets/task_details_tags.dart';
import 'widgets/task_details_metadata.dart';

/// Screen for displaying detailed information of a single task.
///
/// Provides a comprehensive view of task details including title, description,
/// schedule, priority, color, and tags. Offers actions for completing, editing,
/// rescheduling, and deleting tasks with real-time updates via BLoC.
class TaskDetailsScreen extends StatefulWidget {
  /// The task object whose details are to be displayed.
  final TaskModel task;

  const TaskDetailsScreen({super.key, required this.task});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

/// State management for TaskDetailsScreen.
///
/// Handles task state synchronization with BLoC, user interactions,
/// and provides real-time updates for task modifications.
class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  /// Current task data that may be updated through BLoC operations.
  late TaskModel _currentTask;

  /// Tracks if the task was deleted to prevent unnecessary operations.
  bool _isTaskDeleted = false;

  @override
  void initState() {
    super.initState();
    _initializeTask();
  }

  /// Initialize the current task from widget parameter.
  void _initializeTask() {
    _currentTask = widget.task;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TaskBloc, TaskState>(
      listener: _handleTaskStateChanges,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            const StatusBarPadding(),
            // Header with navigation and options
            TaskDetailsHeader(
              task: _currentTask,
              onBackPressed: _handleBackNavigation,
              onMoreOptions: _showMoreOptions,
            ),
            // Scrollable content area
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _buildTaskContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle BLoC state changes and update local task state.
  void _handleTaskStateChanges(BuildContext context, TaskState state) {
    if (state is TaskLoaded && !_isTaskDeleted) {
      _updateTaskFromState(state);
    }
  }

  /// Update local task state from BLoC state if task exists.
  void _updateTaskFromState(TaskLoaded state) {
    try {
      final updatedTask = state.tasks.firstWhere(
        (task) => task.id == _currentTask.id,
      );

      if (updatedTask != _currentTask) {
        setState(() => _currentTask = updatedTask);
      }
    } catch (e) {
      // Task not found - likely deleted, handle gracefully
      _handleTaskNotFound();
    }
  }

  /// Handle case where task is not found in the state.
  void _handleTaskNotFound() {
    if (!_isTaskDeleted && mounted) {
      _isTaskDeleted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          CustomSnackBar.info(context, 'Task was deleted');
          context.pop();
        }
      });
    }
  }

  /// Handle back navigation with potential unsaved changes check.
  void _handleBackNavigation() {
    context.pop();
  }

  /// Build the main task content sections.
  Widget _buildTaskContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primary action buttons section
          _buildPrimaryActionsSection(),

          const SizedBox(height: 20),

          // Task information section
          _buildTaskInfoSection(),

          // Optional description section
          _buildDescriptionSection(),

          // Optional tags section
          _buildTagsSection(),

          const SizedBox(height: 16),

          // Task metadata section
          _buildMetadataSection(),

          const SizedBox(
            height: 100,
          ), // Bottom padding for comfortable scrolling
        ],
      ),
    );
  }

  /// Build primary actions section (complete, edit, delete).
  Widget _buildPrimaryActionsSection() {
    return TaskDetailsPrimaryActions(
      task: _currentTask,
      onToggleComplete: _handleToggleComplete,
      onEdit: _handleEditTask,
      onDelete: _handleDeleteTask,
    );
  }

  /// Build task information section (date, priority, color).
  Widget _buildTaskInfoSection() {
    return TaskDetailsInfoSection(
      task: _currentTask,
      onReschedule: _handleQuickReschedule,
      onChangePriority: _handleQuickChangePriority,
      onChangeColor: _handleQuickChangeColor,
    );
  }

  /// Build description section if description exists.
  Widget _buildDescriptionSection() {
    if (_currentTask.description?.isNotEmpty != true) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        TaskDetailsDescription(description: _currentTask.description!),
      ],
    );
  }

  /// Build tags section if tags exist.
  Widget _buildTagsSection() {
    if (_currentTask.tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        TaskDetailsTags(tags: _currentTask.tags),
      ],
    );
  }

  /// Build metadata section (created at, completed at).
  Widget _buildMetadataSection() {
    return TaskDetailsMetadata(task: _currentTask);
  }

  /// Toggle task completion status with optimistic UI updates.
  void _handleToggleComplete() {
    final wasCompleted = _currentTask.isCompleted;
    final newCompletionStatus = !wasCompleted;

    // Optimistic UI update
    setState(() {
      _currentTask = _currentTask.copyWith(
        isCompleted: newCompletionStatus,
        completedAt: newCompletionStatus ? DateTime.now() : null,
      );
    });

    // Dispatch BLoC event
    context.read<TaskBloc>().add(ToggleTaskComplete(_currentTask.id));

    // Show success feedback
    _showCompletionFeedback(newCompletionStatus);
  }

  /// Show appropriate feedback message for completion toggle.
  void _showCompletionFeedback(bool isCompleted) {
    final message = isCompleted ? 'Task completed!' : 'Task marked as pending';
    CustomSnackBar.success(context, message);
  }

  /// Navigate to edit task screen with current task data.
  void _handleEditTask() {
    context.push('/edit-task', extra: _currentTask);
  }

  /// Show confirmation dialog and handle task deletion.
  Future<void> _handleDeleteTask() async {
    final confirmed = await _showDeleteConfirmation();

    if (confirmed == true && mounted && !_isTaskDeleted) {
      _executeTaskDeletion();
    }
  }

  /// Show delete confirmation dialog.
  Future<bool?> _showDeleteConfirmation() {
    return showCupertinoDialog<bool>(
      context: context,
      builder:
          (context) => TaskDetailsDeleteDialog(taskTitle: _currentTask.title),
    );
  }

  /// Execute task deletion and provide feedback.
  void _executeTaskDeletion() {
    _isTaskDeleted = true;
    context.read<TaskBloc>().add(DeleteTask(_currentTask.id));
    CustomSnackBar.success(context, 'Task deleted');
    context.pop();
  }

  /// Show modal for quick task rescheduling.
  Future<void> _handleQuickReschedule() async {
    final selectedDate = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder:
          (context) => TaskDetailsRescheduleModal(
            currentTask: _currentTask,
            onDateChanged: _updateTaskDate,
          ),
    );

    if (selectedDate != null && mounted) {
      _saveTaskUpdate('Date updated');
    }
  }

  /// Update task date and refresh UI.
  void _updateTaskDate(DateTime date) {
    setState(() {
      _currentTask = _currentTask.copyWith(dueDate: date);
    });
  }

  /// Show modal for quick priority change.
  void _handleQuickChangePriority() {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => TaskDetailsPriorityModal(
            currentTask: _currentTask,
            onPriorityChanged: _updateTaskPriority,
          ),
    );
  }

  /// Update task priority and save changes.
  void _updateTaskPriority(int priority) {
    setState(() {
      _currentTask = _currentTask.copyWith(priority: priority);
    });
    _saveTaskUpdate('Priority updated');
  }

  /// Show modal for quick color change.
  void _handleQuickChangeColor() {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => TaskDetailsColorModal(
            currentTask: _currentTask,
            onColorChanged: _updateTaskColor,
          ),
    );
  }

  /// Update task color and save changes.
  void _updateTaskColor(String color) {
    setState(() {
      _currentTask = _currentTask.copyWith(color: color);
    });
    _saveTaskUpdate('Color updated');
  }

  /// Save task updates to BLoC and show feedback.
  void _saveTaskUpdate(String successMessage) {
    if (mounted && !_isTaskDeleted) {
      context.read<TaskBloc>().add(UpdateTask(_currentTask));
      CustomSnackBar.success(context, successMessage);
    }
  }

  /// Show options modal with additional task actions.
  void _showMoreOptions() {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => TaskDetailsOptionsModal(
            onDuplicate: _handleDuplicateTask,
            onShare: _handleShareTask,
          ),
    );
  }

  /// Create a duplicate of the current task.
  void _handleDuplicateTask() {
    final duplicatedTask = _createDuplicateTask();

    if (mounted) {
      context.read<TaskBloc>().add(AddTask(duplicatedTask));
      CustomSnackBar.success(context, 'Task duplicated!');
      context.pop(); // Close details screen to show new task
    }
  }

  /// Create a new task based on current task with modified title.
  TaskModel _createDuplicateTask() {
    return TaskModel(
      title: '${_currentTask.title} (Copy)',
      description: _currentTask.description,
      dueDate: _currentTask.dueDate,
      priority: _currentTask.priority,
      color: _currentTask.color,
      tags: _currentTask.tags,
      hasNotification: _currentTask.hasNotification,
      notificationMinutesBefore: _currentTask.notificationMinutesBefore,
    );
  }

  /// Handle task sharing (placeholder for future implementation).
  void _handleShareTask() {
    CustomSnackBar.info(context, 'Share feature coming soon!');
  }
}
