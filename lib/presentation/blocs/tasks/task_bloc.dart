import 'package:dayflow/core/services/notification_service.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:dayflow/data/repositories/settings_repository.dart';
import 'package:dayflow/data/repositories/task_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'task_event.dart';
part 'task_state.dart';

// Main BLoC for task management
class TaskBloc extends Bloc<TaskEvent, TaskState> {
  // Repository for data operations
  final TaskRepository _repository;

  // Initialize and register event handlers
  TaskBloc({required TaskRepository repository})
    : _repository = repository,
      super(const TaskInitial()) {
    on<LoadTasks>(_onLoadTasks);
    on<LoadTasksByDate>(_onLoadTasksByDate);
    on<AddTask>(_onAddTask);
    on<UpdateTask>(_onUpdateTask);
    on<ToggleTaskComplete>(_onToggleTaskComplete);
    on<DeleteTask>(_onDeleteTask);
  }

  // Load all tasks
  Future<void> _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    try {
      final tasks = _repository.getAllTasks();
      emit(TaskLoaded(tasks: tasks));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  // Load tasks for a specific date
  Future<void> _onLoadTasksByDate(
    LoadTasksByDate event,
    Emitter<TaskState> emit,
  ) async {
    emit(const TaskLoading());

    try {
      final tasks = _repository.getTasksByDate(event.date);
      emit(TaskLoaded(tasks: tasks, selectedDate: event.date));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  // Add a new task with optional notification
  Future<void> _onAddTask(AddTask event, Emitter<TaskState> emit) async {
    try {
      debugPrint('\n➕ === ADDING NEW TASK ===');
      debugPrint('Title: ${event.task.title}');
      debugPrint('Has notification: ${event.task.hasNotification}');
      debugPrint('Due date: ${event.task.dueDate}');
      debugPrint('Minutes before: ${event.task.notificationMinutesBefore}');

      // Save task to repository
      await _repository.addTask(event.task);

      // Handle notification scheduling
      if (event.task.hasNotification && event.task.dueDate != null) {
        debugPrint('🔔 Scheduling notification for task...');

        // Get app settings
        final settingsRepo = SettingsRepository();
        await settingsRepo.init();
        final settings = settingsRepo.getSettings();
        debugPrint(
          'Settings loaded - default minutes: ${settings.defaultNotificationMinutesBefore}',
        );

        // Initialize notification service if needed
        final notificationService = NotificationService();
        if (!notificationService.isInitialized) {
          await notificationService.initialize();
        }

        // Schedule the notification
        final success = await notificationService.scheduleTaskNotification(
          task: event.task,
          settings: settings,
        );

        if (success) {
          debugPrint('✅ Notification scheduled successfully');
        } else {
          debugPrint('❌ Failed to schedule notification');
        }
      } else {
        debugPrint('🔕 No notification needed for this task');
      }

      // Refresh task list
      add(const LoadTasks());
    } catch (e) {
      debugPrint('❌ Error in _onAddTask: $e');
      emit(TaskError(e.toString()));
    }
  }

  // Update an existing task
  Future<void> _onUpdateTask(UpdateTask event, Emitter<TaskState> emit) async {
    try {
      debugPrint('✏️ Updating task: ${event.task.title}');

      // Update task in repository
      await _repository.updateTask(event.task);

      // Get app settings
      final settingsRepo = SettingsRepository();
      await settingsRepo.init();
      final settings = settingsRepo.getSettings();

      // Initialize notification service if needed
      final notificationService = NotificationService();
      if (!notificationService.isInitialized) {
        await notificationService.initialize();
      }

      // Update or cancel notification based on task settings
      if (event.task.hasNotification && event.task.dueDate != null) {
        debugPrint('🔔 Updating notification for task');
        final success = await notificationService.scheduleTaskNotification(
          task: event.task,
          settings: settings,
        );

        if (!success) {
          debugPrint('❌ Failed to update notification');
        }
      } else {
        debugPrint('🔕 Canceling notifications for task');
        await notificationService.cancelTaskNotifications(event.task.id);
      }

      // Refresh task list
      add(const LoadTasks());
    } catch (e) {
      debugPrint('❌ Error in _onUpdateTask: $e');
      emit(TaskError(e.toString()));
    }
  }

  // Toggle task completion status
  Future<void> _onToggleTaskComplete(
    ToggleTaskComplete event,
    Emitter<TaskState> emit,
  ) async {
    try {
      await _repository.toggleTaskComplete(event.taskId);

      // Update state efficiently if already loaded
      if (state is TaskLoaded) {
        final currentState = state as TaskLoaded;
        final tasks = _repository.getAllTasks();
        emit(TaskLoaded(tasks: tasks, selectedDate: currentState.selectedDate));
      } else {
        add(const LoadTasks());
      }
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  // Delete a task
  Future<void> _onDeleteTask(DeleteTask event, Emitter<TaskState> emit) async {
    try {
      await _repository.deleteTask(event.taskId);

      // Update state efficiently if already loaded
      if (state is TaskLoaded) {
        final currentState = state as TaskLoaded;
        final tasks = _repository.getAllTasks();
        emit(TaskLoaded(tasks: tasks, selectedDate: currentState.selectedDate));
      } else {
        add(const LoadTasks());
      }
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }
}
