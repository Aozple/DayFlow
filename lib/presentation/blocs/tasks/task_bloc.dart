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
  final NotificationService _notificationService = NotificationService();

  TaskBloc() : super(tag: 'TaskBloc', initialState: const TaskInitial()) {
    on<LoadTasks>(_onLoadTasks);
    on<LoadTasksByDate>(_onLoadTasksByDate);
    on<AddTask>(_onAddTask);
    on<UpdateTask>(_onUpdateTask);
    on<ToggleTaskComplete>(_onToggleTaskComplete);
    on<DeleteTask>(_onDeleteTask);
    on<ClearError>(_onClearError);
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
      final allTasks = _repository.getAllTasks();
      final tasksForDate = _repository.getTasksByDate(event.date);
      logSuccess('Filtered', data: '${tasksForDate.length} tasks');
      emit(TaskLoaded(tasks: allTasks, selectedDate: event.date));
    } catch (e) {
      logError('Filter failed', error: e);
      if (state is TaskLoaded) {
        emit(
          TaskLoaded(
            tasks: (state as TaskLoaded).tasks,
            selectedDate: event.date,
          ),
        );
      } else {
        emit(TaskLoaded(tasks: const [], selectedDate: event.date));
      }
    }
  }

  Future<void> _onAddTask(AddTask event, Emitter<TaskState> emit) async {
    try {
      logInfo('Adding task: ${event.task.title}');
      await _repository.addTask(event.task);

      if (event.task.hasNotification && event.task.dueDate != null) {
        await _notificationService.scheduleTaskNotification(event.task);
      }

      if (state is TaskLoaded) {
        final currentState = state as TaskLoaded;
        final tasks = _repository.getAllTasks();
        emit(TaskLoaded(tasks: tasks, selectedDate: currentState.selectedDate));
      } else {
        final tasks = _repository.getAllTasks();
        emit(TaskLoaded(tasks: tasks));
      }

      logSuccess('Task added and UI updated');
    } catch (e) {
      logError('Add failed', error: e);
      emit(const TaskError('Failed to add task'));
    }
  }

  Future<void> _onUpdateTask(UpdateTask event, Emitter<TaskState> emit) async {
    try {
      logInfo('Updating task: ${event.task.title}');
      await _repository.updateTask(event.task);

      if (event.task.hasNotification && event.task.dueDate != null) {
        await _notificationService.scheduleTaskNotification(event.task);
      } else {
        await _notificationService.cancelTaskNotification(event.task.id);
      }

      if (state is TaskLoaded) {
        final currentState = state as TaskLoaded;
        final tasks = _repository.getAllTasks();
        emit(TaskLoaded(tasks: tasks, selectedDate: currentState.selectedDate));
      } else {
        final tasks = _repository.getAllTasks();
        emit(TaskLoaded(tasks: tasks));
      }

      logSuccess('Task updated');
    } catch (e) {
      logError('Update failed', error: e);
      emit(const TaskError('Failed to update task'));
    }
  }

  Future<void> _onToggleTaskComplete(
    ToggleTaskComplete event,
    Emitter<TaskState> emit,
  ) async {
    try {
      logInfo('Toggling task: ${event.taskId}');
      await _repository.toggleTaskComplete(event.taskId);

      if (state is TaskLoaded) {
        final currentState = state as TaskLoaded;
        final tasks = _repository.getAllTasks();
        emit(TaskLoaded(tasks: tasks, selectedDate: currentState.selectedDate));
      } else {
        add(const LoadTasks());
      }

      logSuccess('Task toggled');
    } catch (e) {
      logError('Toggle failed', error: e);
      emit(const TaskError('Failed to toggle task'));
    }
  }

  Future<void> _onDeleteTask(DeleteTask event, Emitter<TaskState> emit) async {
    try {
      logInfo('Deleting task: ${event.taskId}');
      await _repository.deleteTask(event.taskId);
      await _notificationService.cancelTaskNotification(event.taskId);

      if (state is TaskLoaded) {
        final currentState = state as TaskLoaded;
        final tasks = _repository.getAllTasks();
        emit(TaskLoaded(tasks: tasks, selectedDate: currentState.selectedDate));
      } else {
        add(const LoadTasks());
      }

      logSuccess('Task deleted');
    } catch (e) {
      logError('Delete failed', error: e);
      emit(const TaskError('Failed to delete task'));
    }
  }

  Future<void> _onClearError(ClearError event, Emitter<TaskState> emit) async {
    logInfo('Clearing error');
    add(const LoadTasks());
  }
}
