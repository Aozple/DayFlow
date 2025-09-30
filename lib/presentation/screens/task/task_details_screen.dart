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

class TaskDetailsScreen extends StatefulWidget {
  final TaskModel task;

  const TaskDetailsScreen({super.key, required this.task});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  late TaskModel _currentTask;

  bool _isTaskDeleted = false;

  @override
  void initState() {
    super.initState();
    _initializeTask();
  }

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

            TaskDetailsHeader(
              task: _currentTask,
              onBackPressed: _handleBackNavigation,
              onMoreOptions: _showMoreOptions,
            ),

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

  void _handleTaskStateChanges(BuildContext context, TaskState state) {
    if (state is TaskLoaded && !_isTaskDeleted) {
      _updateTaskFromState(state);
    }
  }

  void _updateTaskFromState(TaskLoaded state) {
    try {
      final updatedTask = state.tasks.firstWhere(
        (task) => task.id == _currentTask.id,
      );

      if (updatedTask != _currentTask) {
        setState(() => _currentTask = updatedTask);
      }
    } catch (e) {
      _handleTaskNotFound();
    }
  }

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

  void _handleBackNavigation() {
    context.pop();
  }

  Widget _buildTaskContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPrimaryActionsSection(),

          const SizedBox(height: 20),

          _buildTaskInfoSection(),

          _buildDescriptionSection(),

          _buildTagsSection(),

          const SizedBox(height: 16),

          _buildMetadataSection(),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPrimaryActionsSection() {
    return TaskDetailsPrimaryActions(
      task: _currentTask,
      onToggleComplete: _handleToggleComplete,
      onEdit: _handleEditTask,
      onDelete: _handleDeleteTask,
    );
  }

  Widget _buildTaskInfoSection() {
    return TaskDetailsInfoSection(
      task: _currentTask,
      onReschedule: _handleQuickReschedule,
      onChangePriority: _handleQuickChangePriority,
      onChangeColor: _handleQuickChangeColor,
    );
  }

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

  Widget _buildMetadataSection() {
    return TaskDetailsMetadata(task: _currentTask);
  }

  void _handleToggleComplete() {
    final wasCompleted = _currentTask.isCompleted;
    final newCompletionStatus = !wasCompleted;

    setState(() {
      _currentTask = _currentTask.copyWith(
        isCompleted: newCompletionStatus,
        completedAt: newCompletionStatus ? DateTime.now() : null,
      );
    });

    context.read<TaskBloc>().add(ToggleTaskComplete(_currentTask.id));

    _showCompletionFeedback(newCompletionStatus);
  }

  void _showCompletionFeedback(bool isCompleted) {
    final message = isCompleted ? 'Task completed!' : 'Task marked as pending';
    CustomSnackBar.success(context, message);
  }

  void _handleEditTask() {
    context.push('/edit-task', extra: _currentTask);
  }

  Future<void> _handleDeleteTask() async {
    final confirmed = await _showDeleteConfirmation();

    if (confirmed == true && mounted && !_isTaskDeleted) {
      _executeTaskDeletion();
    }
  }

  Future<bool?> _showDeleteConfirmation() {
    return showCupertinoDialog<bool>(
      context: context,
      builder:
          (context) => TaskDetailsDeleteDialog(taskTitle: _currentTask.title),
    );
  }

  void _executeTaskDeletion() {
    _isTaskDeleted = true;
    context.read<TaskBloc>().add(DeleteTask(_currentTask.id));
    CustomSnackBar.success(context, 'Task deleted');
    context.pop();
  }

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

  void _updateTaskDate(DateTime date) {
    setState(() {
      _currentTask = _currentTask.copyWith(dueDate: date);
    });
  }

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

  void _updateTaskPriority(int priority) {
    setState(() {
      _currentTask = _currentTask.copyWith(priority: priority);
    });
    _saveTaskUpdate('Priority updated');
  }

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

  void _updateTaskColor(String color) {
    setState(() {
      _currentTask = _currentTask.copyWith(color: color);
    });
    _saveTaskUpdate('Color updated');
  }

  void _saveTaskUpdate(String successMessage) {
    if (mounted && !_isTaskDeleted) {
      context.read<TaskBloc>().add(UpdateTask(_currentTask));
      CustomSnackBar.success(context, successMessage);
    }
  }

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

  void _handleDuplicateTask() {
    final duplicatedTask = _createDuplicateTask();

    if (mounted) {
      context.read<TaskBloc>().add(AddTask(duplicatedTask));
      CustomSnackBar.success(context, 'Task duplicated!');
      context.pop();
    }
  }

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

  void _handleShareTask() {
    CustomSnackBar.info(context, 'Share feature coming soon!');
  }
}
