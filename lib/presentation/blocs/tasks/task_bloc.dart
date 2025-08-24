import 'package:dayflow/data/models/task_model.dart';
import 'package:dayflow/data/repositories/task_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'task_event.dart';
part 'task_state.dart';

// This is our TaskBloc, which handles all the logic and state management for tasks.
// It extends Bloc, taking TaskEvent (what happens) and TaskState (what the UI sees).
class TaskBloc extends Bloc<TaskEvent, TaskState> {
  // We need a TaskRepository to interact with our task data (like saving or loading).
  final TaskRepository _repository;

  // The constructor sets up the repository and registers all our event handlers.
  TaskBloc({required TaskRepository repository})
    : _repository = repository,
      super(const TaskInitial()) {
    // When a LoadTasks event comes in, call _onLoadTasks.
    on<LoadTasks>(_onLoadTasks);
    // When a LoadTasksByDate event comes in, call _onLoadTasksByDate.
    on<LoadTasksByDate>(_onLoadTasksByDate);
    // When an AddTask event comes in, call _onAddTask.
    on<AddTask>(_onAddTask);
    // When an UpdateTask event comes in, call _onUpdateTask.
    on<UpdateTask>(_onUpdateTask);
    // When a ToggleTaskComplete event comes in, call _onToggleTaskComplete.
    on<ToggleTaskComplete>(_onToggleTaskComplete);
    // When a DeleteTask event comes in, call _onDeleteTask.
    on<DeleteTask>(_onDeleteTask);
  }

  // This method handles the `LoadTasks` event.
  // It fetches all tasks and emits a `TaskLoaded` state.
  Future<void> _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    try {
      // Grab all tasks from our repository.
      final tasks = _repository.getAllTasks();

      // Tell the UI that tasks are loaded and provide the list.
      emit(TaskLoaded(tasks: tasks));
    } catch (e) {
      // If something breaks, emit an error state.
      emit(TaskError(e.toString()));
    }
  }

  // This method handles the `LoadTasksByDate` event.
  // It loads tasks specifically for a given date.
  Future<void> _onLoadTasksByDate(
    LoadTasksByDate event,
    Emitter<TaskState> emit,
  ) async {
    emit(const TaskLoading()); // First, emit a loading state.

    try {
      // Get tasks filtered by the specified date.
      final tasks = _repository.getTasksByDate(event.date);
      // Emit the loaded tasks, also keeping track of the selected date.
      emit(TaskLoaded(tasks: tasks, selectedDate: event.date));
    } catch (e) {
      emit(TaskError(e.toString())); // Handle any errors.
    }
  }

  // This method handles the `AddTask` event.
  // It adds a new task to the repository and then reloads all tasks.
  Future<void> _onAddTask(AddTask event, Emitter<TaskState> emit) async {
    try {
      // Add the new task to the database via the repository.
      await _repository.addTask(event.task);

      // After adding, trigger a full reload to update the UI.
      add(const LoadTasks());
    } catch (e) {
      emit(TaskError(e.toString())); // Handle errors during task addition.
    }
  }

  // This method handles the `UpdateTask` event.
  // It updates an existing task in the repository and then reloads all tasks.
  Future<void> _onUpdateTask(UpdateTask event, Emitter<TaskState> emit) async {
    try {
      await _repository.updateTask(event.task); // Update the task in the database.
      add(const LoadTasks()); // Reload tasks to reflect the changes.
    } catch (e) {
      emit(TaskError(e.toString())); // Handle errors during task update.
    }
  }

  // This method handles the `ToggleTaskComplete` event.
  // It flips the completion status of a task.
  Future<void> _onToggleTaskComplete(
    ToggleTaskComplete event,
    Emitter<TaskState> emit,
  ) async {
    try {
      await _repository.toggleTaskComplete(event.taskId); // Toggle completion status in the repository.

      // If we're already in a `TaskLoaded` state, we can update it directly
      // without a full reload, which is a bit smoother.
      if (state is TaskLoaded) {
        final currentState = state as TaskLoaded;
        final tasks = _repository.getAllTasks(); // Get the updated list of tasks.
        emit(TaskLoaded(tasks: tasks, selectedDate: currentState.selectedDate)); // Emit the new state.
      } else {
        add(const LoadTasks()); // Otherwise, just trigger a full reload.
      }
    } catch (e) {
      emit(TaskError(e.toString())); // Handle errors during status toggle.
    }
  }

  // This method handles the `DeleteTask` event.
  // It marks a task as deleted in the repository.
  Future<void> _onDeleteTask(DeleteTask event, Emitter<TaskState> emit) async {
    try {
      await _repository.deleteTask(event.taskId); // Mark the task as deleted.

      // Similar to toggling completion, update the state if already loaded,
      // otherwise trigger a full reload.
      if (state is TaskLoaded) {
        final currentState = state as TaskLoaded;
        final tasks = _repository.getAllTasks(); // Get the updated list.
        emit(TaskLoaded(tasks: tasks, selectedDate: currentState.selectedDate)); // Emit the new state.
      } else {
        add(const LoadTasks()); // Fallback to full reload.
      }
    } catch (e) {
      emit(TaskError(e.toString())); // Handle errors during task deletion.
    }
  }
}
