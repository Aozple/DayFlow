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

  // Last processed values to avoid duplicate processing
  String? _lastSearchQuery;

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

  // Refresh current state with optimized repository calls
  Future<TaskLoaded> _refreshTasksState({DateTime? selectedDate}) async {
    final tasks = _repository.getAll(operationType: 'read');

    DateTime? currentSelectedDate;
    if (state is TaskLoaded) {
      currentSelectedDate = (state as TaskLoaded).selectedDate;
    }

    return TaskLoaded.create(
      tasks: tasks,
      selectedDate: selectedDate ?? currentSelectedDate,
    );
  }

  Future<void> _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    if (!canProcess(forceRefresh: event.forceRefresh)) return;

    await performOperation(
      operationName: 'Load Tasks',
      operation: () async {
        final tasks = _repository.getAll(operationType: 'read');
        DateTime? selectedDate;
        if (state is TaskLoaded) {
          selectedDate = (state as TaskLoaded).selectedDate;
        }
        return TaskLoaded.create(tasks: tasks, selectedDate: selectedDate);
      },
      emit: emit,
      loadingState: state is! TaskLoaded ? const TaskLoading() : null,
      successState: (result) => result,
      errorState: (error) => const TaskError('Failed to load tasks'),
      fallbackState:
          state is TaskLoaded ? state : TaskLoaded.create(tasks: const []),
    );
  }

  Future<void> _onLoadTasksByDate(
    LoadTasksByDate event,
    Emitter<TaskState> emit,
  ) async {
    try {
      logInfo('Loading by date: ${event.date.toString().split(' ')[0]}');

      // Load all tasks with new selected date
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
        emit(TaskLoaded.create(tasks: const [], selectedDate: event.date));
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

  Future<void> _onSearchTasks(
    SearchTasks event,
    Emitter<TaskState> emit,
  ) async {
    // Skip if same query
    if (_lastSearchQuery == event.query) {
      logVerbose('Skipping duplicate search query');
      return;
    }
    try {
      logInfo('Processing search: "${event.query}"');
      _lastSearchQuery = event.query;

      if (state is TaskLoaded) {
        final currentState = state as TaskLoaded;

        // Create search filter efficiently
        final searchFilter =
            event.query.trim().isNotEmpty
                ? TaskFilter(searchQuery: event.query.trim())
                : null;

        // Only emit if filter actually changed
        if (_filterActuallyChanged(currentState.activeFilter, searchFilter)) {
          emit(currentState.copyWith(activeFilter: searchFilter));
          logSuccess('Search filter applied');
        } else {
          logVerbose('Search filter unchanged, skipping emit');
        }
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
      logInfo('Processing filter');

      if (state is TaskLoaded) {
        final currentState = state as TaskLoaded;

        // Only emit if filter actually changed
        if (_filterActuallyChanged(currentState.activeFilter, event.filter)) {
          emit(currentState.copyWith(activeFilter: event.filter));
          logSuccess('Filter applied');
        } else {
          logVerbose('Filter unchanged, skipping emit');
        }
      }
    } catch (e) {
      logError('Filter failed', error: e);
    }
  }

  Future<void> _onClearError(ClearError event, Emitter<TaskState> emit) async {
    logInfo('Clearing error');
    add(const LoadTasks());
  }

  // Helper to check if filter actually changed
  bool _filterActuallyChanged(TaskFilter? oldFilter, TaskFilter? newFilter) {
    if (oldFilter == null && newFilter == null) return false;
    if (oldFilter == null || newFilter == null) return true;

    return oldFilter.searchQuery != newFilter.searchQuery ||
        oldFilter.priorities != newFilter.priorities ||
        oldFilter.isCompleted != newFilter.isCompleted ||
        oldFilter.hasNotification != newFilter.hasNotification ||
        oldFilter.tags != newFilter.tags;
  }
}
