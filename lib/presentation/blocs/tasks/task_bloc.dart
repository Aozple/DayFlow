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
    on<ClearError>(_onClearError);
  }

  // Load all tasks
  Future<void> _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    debugPrint('\n📋 === LOADING ALL TASKS ===');
    debugPrint('Current state: ${state.runtimeType}');

    try {
      final tasks = _repository.getAllTasks();
      debugPrint('✅ Loaded ${tasks.length} tasks successfully');
      emit(TaskLoaded(tasks: tasks));
    } catch (e) {
      debugPrint('❌ Error loading tasks: $e');
      emit(TaskError(e.toString()));

      // Recover from error state
      await Future.delayed(const Duration(milliseconds: 100));
      emit(const TaskLoaded(tasks: []));
    }
  }

  // Load tasks for a specific date
  Future<void> _onLoadTasksByDate(
    LoadTasksByDate event,
    Emitter<TaskState> emit,
  ) async {
    debugPrint('\n📅 === LOADING TASKS BY DATE ===');
    debugPrint('Date: ${event.date.toString().split(' ')[0]}');
    debugPrint('Current state: ${state.runtimeType}');

    // Don't emit loading state if we already have data
    if (state is! TaskLoaded) {
      emit(const TaskLoading());
    }

    try {
      final allTasks = _repository.getAllTasks();
      debugPrint('Total tasks in repository: ${allTasks.length}');

      final tasksForDate = _repository.getTasksByDate(event.date);
      debugPrint('✅ Found ${tasksForDate.length} tasks for selected date');

      // Always use all tasks but track selected date
      emit(TaskLoaded(tasks: allTasks, selectedDate: event.date));
    } catch (e) {
      debugPrint('❌ Error loading tasks by date: $e');

      // Try to maintain existing data if possible
      if (state is TaskLoaded) {
        final currentState = state as TaskLoaded;
        emit(TaskLoaded(tasks: currentState.tasks, selectedDate: event.date));
      } else {
        emit(TaskError(e.toString()));
        // Auto-recover after showing error
        await Future.delayed(const Duration(seconds: 1));
        emit(TaskLoaded(tasks: const [], selectedDate: event.date));
      }
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

  Future<void> _onClearError(ClearError event, Emitter<TaskState> emit) async {
    debugPrint('🧹 Clearing error state');
    add(const LoadTasks());
  }
}
