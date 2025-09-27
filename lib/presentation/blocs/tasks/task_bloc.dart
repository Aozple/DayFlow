import 'dart:async';
import 'package:dayflow/core/services/notifications/notification_service.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:dayflow/data/repositories/task_repository.dart';
import 'package:dayflow/presentation/blocs/base/base_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

part 'task_event.dart';
part 'task_state.dart';

class TaskBloc extends BaseBloc<TaskEvent, TaskState> {
  final TaskRepository _repository = GetIt.I<TaskRepository>();
  final NotificationService _notificationService =
      GetIt.I<NotificationService>();

  TaskBloc() : super(tag: 'TaskBloc', initialState: const TaskInitial()) {
    on<LoadTasks>(_onLoadTasks);
    on<LoadTasksByDate>(_onLoadTasksByDate);
    on<AddTask>(_onAddTask);
    on<UpdateTask>(_onUpdateTask);
    on<ToggleTaskComplete>(_onToggleTaskComplete);
    on<DeleteTask>(_onDeleteTask);
    on<ClearError>(_onClearError);
    on<SearchTasks>(_onSearchTasks);
    on<FilterTasks>(_onFilterTasks);
  }

  Future<TaskLoaded> _refreshTasksState({DateTime? selectedDate}) async {
    final tasks = _repository.getAllTasks();
    final currentState = state is TaskLoaded ? state as TaskLoaded : null;

    return TaskLoaded(
      tasks: tasks,
      selectedDate: selectedDate ?? currentState?.selectedDate,
    );
  }

  Future<void> _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    if (!canProcess(forceRefresh: event.forceRefresh)) return;

    await performOperation(
      operationName: 'Load Tasks',
      operation: () async {
        final tasks = _repository.getAllTasks();
        DateTime? selectedDate;
        if (state is TaskLoaded) {
          selectedDate = (state as TaskLoaded).selectedDate;
        }
        return TaskLoaded(tasks: tasks, selectedDate: selectedDate);
      },
      emit: emit,
      loadingState: state is! TaskLoaded ? const TaskLoading() : null,
      successState: (result) => result,
      errorState: (error) => TaskError(error),
      fallbackState: state is TaskLoaded ? state : TaskLoaded(tasks: const []),
    );
  }

  Future<void> _onLoadTasksByDate(
    LoadTasksByDate event,
    Emitter<TaskState> emit,
  ) async {
    try {
      logInfo('Loading by date: ${event.date.toString().split(' ')[0]}');

      // Always load all tasks, but change selectedDate
      // UI will use getTasksForDate() to show filtered tasks
      final refreshedState = await _refreshTasksState(selectedDate: event.date);

      emit(refreshedState);

      final tasksForDate = refreshedState.getTasksForDate(event.date);
      logSuccess(
        'Date changed',
        data: '${tasksForDate.length} tasks for selected date',
      );
    } catch (e) {
      logError('Date filter failed', error: e);

      // Fallback: keep current state but update date
      if (state is TaskLoaded) {
        final currentState = state as TaskLoaded;
        emit(currentState.copyWith(selectedDate: event.date));
      } else {
        emit(TaskLoaded(tasks: const [], selectedDate: event.date));
      }
    }
  }

  Future<void> _onAddTask(AddTask event, Emitter<TaskState> emit) async {
    await performOperation(
      operationName: 'Add Task',
      operation: () async {
        await _repository.addTask(event.task);

        if (event.task.hasNotification && event.task.dueDate != null) {
          await _notificationService.scheduleTaskNotification(event.task);
        }

        return await _refreshTasksState();
      },
      emit: emit,
      successState: (result) => result,
      errorState: (error) => const TaskError('Failed to add task'),
    );
  }

  Future<void> _onUpdateTask(UpdateTask event, Emitter<TaskState> emit) async {
    await performOperation(
      operationName: 'Update Task',
      operation: () async {
        await _repository.updateTask(event.task);

        if (event.task.hasNotification && event.task.dueDate != null) {
          await _notificationService.scheduleTaskNotification(event.task);
        } else {
          await _notificationService.cancelTaskNotification(event.task.id);
        }

        return await _refreshTasksState();
      },
      emit: emit,
      successState: (result) => result,
      errorState: (error) => const TaskError('Failed to update task'),
    );
  }

  Future<void> _onToggleTaskComplete(
    ToggleTaskComplete event,
    Emitter<TaskState> emit,
  ) async {
    await performOperation(
      operationName: 'Toggle Task',
      operation: () async {
        await _repository.toggleTaskComplete(event.taskId);
        return await _refreshTasksState();
      },
      emit: emit,
      successState: (result) => result,
      errorState: (error) => const TaskError('Failed to toggle task'),
    );
  }

  Future<void> _onDeleteTask(DeleteTask event, Emitter<TaskState> emit) async {
    await performOperation(
      operationName: 'Delete Task',
      operation: () async {
        await _repository.deleteTask(event.taskId);
        await _notificationService.cancelTaskNotification(event.taskId);
        return await _refreshTasksState();
      },
      emit: emit,
      successState: (result) => result,
      errorState: (error) => const TaskError('Failed to delete task'),
    );
  }

  Future<void> _onClearError(ClearError event, Emitter<TaskState> emit) async {
    logInfo('Clearing error');
    add(const LoadTasks());
  }

  Future<void> _onSearchTasks(
    SearchTasks event,
    Emitter<TaskState> emit,
  ) async {
    try {
      logInfo('Searching tasks: "${event.query}"');

      if (state is TaskLoaded) {
        final currentState = state as TaskLoaded;

        // Create search filter
        final searchFilter = TaskFilter(
          searchQuery: event.query.isNotEmpty ? event.query : null,
        );

        emit(currentState.copyWith(activeFilter: searchFilter));

        logSuccess('Search filter applied');
      }
    } catch (e) {
      logError('Search failed', error: e);
    }
  }

  Future<void> _onFilterTasks(
    FilterTasks event,
    Emitter<TaskState> emit,
  ) async {
    try {
      logInfo('Applying task filter');

      if (state is TaskLoaded) {
        final currentState = state as TaskLoaded;
        emit(currentState.copyWith(activeFilter: event.filter));

        logSuccess('Filter applied');
      }
    } catch (e) {
      logError('Filter failed', error: e);
    }
  }
}
