import 'package:dayflow/core/services/notification_service.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:dayflow/data/repositories/settings_repository.dart';
import 'package:dayflow/data/repositories/task_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'task_event.dart';
part 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  static const String _tag = 'TaskBloc';
  final TaskRepository _repository;

  // Prevent duplicate operations
  bool _isProcessing = false;
  DateTime? _lastLoadTime;
  static const Duration _minLoadInterval = Duration(milliseconds: 500);

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

  Future<void> _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    // Prevent rapid reloads
    if (_isProcessing) {
      DebugLogger.warning('Load already in progress, skipping', tag: _tag);
      return;
    }

    if (_lastLoadTime != null) {
      final timeSinceLastLoad = DateTime.now().difference(_lastLoadTime!);
      if (timeSinceLastLoad < _minLoadInterval) {
        DebugLogger.verbose(
          'Too soon to reload, using cached state',
          tag: _tag,
        );
        return;
      }
    }

    _isProcessing = true;

    try {
      DebugLogger.info('Loading all tasks', tag: _tag);

      // Keep existing data while loading if we have it
      if (state is! TaskLoaded) {
        emit(const TaskLoading());
      }

      final tasks = _repository.getAllTasks();
      _lastLoadTime = DateTime.now();

      DebugLogger.success(
        'Tasks loaded',
        tag: _tag,
        data: '${tasks.length} tasks',
      );

      // Preserve selected date if we had one
      DateTime? selectedDate;
      if (state is TaskLoaded) {
        selectedDate = (state as TaskLoaded).selectedDate;
      }

      emit(TaskLoaded(tasks: tasks, selectedDate: selectedDate));
    } catch (e) {
      DebugLogger.error('Failed to load tasks', tag: _tag, error: e);

      // Try to maintain existing data
      if (state is TaskLoaded) {
        final currentState = state as TaskLoaded;
        emit(TaskError(e.toString()));
        await Future.delayed(const Duration(seconds: 1));
        emit(currentState);
      } else {
        emit(TaskError(e.toString()));
        await Future.delayed(const Duration(seconds: 1));
        emit(TaskLoaded(tasks: const []));
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _onLoadTasksByDate(
    LoadTasksByDate event,
    Emitter<TaskState> emit,
  ) async {
    try {
      DebugLogger.info(
        'Loading tasks by date',
        tag: _tag,
        data: event.date.toString().split(' ')[0],
      );

      // Get all tasks (uses cache if available)
      final allTasks = _repository.getAllTasks();

      // Filter for selected date
      final tasksForDate = _repository.getTasksByDate(event.date);

      DebugLogger.success(
        'Tasks filtered',
        tag: _tag,
        data: '${tasksForDate.length} tasks for selected date',
      );

      emit(TaskLoaded(tasks: allTasks, selectedDate: event.date));
    } catch (e) {
      DebugLogger.error('Failed to load tasks by date', tag: _tag, error: e);

      // Maintain state with new date
      if (state is TaskLoaded) {
        final currentState = state as TaskLoaded;
        emit(TaskLoaded(tasks: currentState.tasks, selectedDate: event.date));
      } else {
        emit(TaskLoaded(tasks: const [], selectedDate: event.date));
      }
    }
  }

  Future<void> _onAddTask(AddTask event, Emitter<TaskState> emit) async {
    if (_isProcessing) {
      DebugLogger.warning('Operation in progress, skipping add', tag: _tag);
      return;
    }

    _isProcessing = true;

    try {
      DebugLogger.info('Adding new task', tag: _tag, data: event.task.title);

      // Save task
      await _repository.addTask(event.task);

      // Handle notifications
      if (event.task.hasNotification && event.task.dueDate != null) {
        await _scheduleNotification(event.task);
      }

      // Reload tasks
      add(const LoadTasks());

      DebugLogger.success('Task added successfully', tag: _tag);
    } catch (e) {
      DebugLogger.error('Failed to add task', tag: _tag, error: e);
      emit(TaskError('Failed to add task: ${e.toString()}'));

      // Auto-recover
      await Future.delayed(const Duration(seconds: 2));
      add(const LoadTasks());
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _onUpdateTask(UpdateTask event, Emitter<TaskState> emit) async {
    if (_isProcessing) {
      DebugLogger.warning('Operation in progress, skipping update', tag: _tag);
      return;
    }

    _isProcessing = true;

    try {
      DebugLogger.info('Updating task', tag: _tag, data: event.task.title);

      await _repository.updateTask(event.task);

      // Handle notifications
      await _handleNotificationUpdate(event.task);

      add(const LoadTasks());

      DebugLogger.success('Task updated successfully', tag: _tag);
    } catch (e) {
      DebugLogger.error('Failed to update task', tag: _tag, error: e);
      emit(TaskError('Failed to update task: ${e.toString()}'));

      // Auto-recover
      await Future.delayed(const Duration(seconds: 2));
      add(const LoadTasks());
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _onToggleTaskComplete(
    ToggleTaskComplete event,
    Emitter<TaskState> emit,
  ) async {
    try {
      DebugLogger.info(
        'Toggling task completion',
        tag: _tag,
        data: event.taskId,
      );

      await _repository.toggleTaskComplete(event.taskId);

      // Quick update without full reload
      if (state is TaskLoaded) {
        final currentState = state as TaskLoaded;
        final tasks = _repository.getAllTasks();
        emit(TaskLoaded(tasks: tasks, selectedDate: currentState.selectedDate));
      } else {
        add(const LoadTasks());
      }

      DebugLogger.success('Task toggled successfully', tag: _tag);
    } catch (e) {
      DebugLogger.error('Failed to toggle task', tag: _tag, error: e);
      emit(TaskError('Failed to toggle task: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteTask(DeleteTask event, Emitter<TaskState> emit) async {
    try {
      DebugLogger.info('Deleting task', tag: _tag, data: event.taskId);

      await _repository.deleteTask(event.taskId);

      // Quick update
      if (state is TaskLoaded) {
        final currentState = state as TaskLoaded;
        final tasks = _repository.getAllTasks();
        emit(TaskLoaded(tasks: tasks, selectedDate: currentState.selectedDate));
      } else {
        add(const LoadTasks());
      }

      DebugLogger.success('Task deleted successfully', tag: _tag);
    } catch (e) {
      DebugLogger.error('Failed to delete task', tag: _tag, error: e);
      emit(TaskError('Failed to delete task: ${e.toString()}'));
    }
  }

  Future<void> _onClearError(ClearError event, Emitter<TaskState> emit) async {
    DebugLogger.info('Clearing error state', tag: _tag);
    add(const LoadTasks());
  }

  // Helper methods
  Future<void> _scheduleNotification(TaskModel task) async {
    try {
      DebugLogger.info('Scheduling notification', tag: _tag, data: task.title);

      final settingsRepo = SettingsRepository();
      if (!settingsRepo.isInitialized) {
        await settingsRepo.init();
      }

      final settings = settingsRepo.getSettings();
      final notificationService = NotificationService();

      if (!notificationService.isInitialized) {
        await notificationService.initialize();
      }

      final success = await notificationService.scheduleTaskNotification(
        task: task,
        settings: settings,
      );

      if (success) {
        DebugLogger.success('Notification scheduled', tag: _tag);
      } else {
        DebugLogger.warning('Failed to schedule notification', tag: _tag);
      }
    } catch (e) {
      DebugLogger.error('Error scheduling notification', tag: _tag, error: e);
    }
  }

  Future<void> _handleNotificationUpdate(TaskModel task) async {
    try {
      final notificationService = NotificationService();

      if (!notificationService.isInitialized) {
        await notificationService.initialize();
      }

      if (task.hasNotification && task.dueDate != null) {
        DebugLogger.info('Updating notification', tag: _tag);

        final settingsRepo = SettingsRepository();
        if (!settingsRepo.isInitialized) {
          await settingsRepo.init();
        }

        await notificationService.scheduleTaskNotification(
          task: task,
          settings: settingsRepo.getSettings(),
        );
      } else {
        DebugLogger.info('Canceling notifications', tag: _tag);
        await notificationService.cancelTaskNotifications(task.id);
      }
    } catch (e) {
      DebugLogger.error('Error handling notification', tag: _tag, error: e);
    }
  }

  @override
  Future<void> close() {
    DebugLogger.info('Closing TaskBloc', tag: _tag);
    return super.close();
  }
}
