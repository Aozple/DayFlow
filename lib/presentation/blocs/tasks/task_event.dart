part of 'task_bloc.dart';

/// Base class for all task-related events
/// Equatable helps BLoC to compare events and avoid unnecessary rebuilds
abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all tasks
class LoadTasks extends TaskEvent {
  const LoadTasks();
}

/// Event to load tasks for a specific date
class LoadTasksByDate extends TaskEvent {
  final DateTime date;

  const LoadTasksByDate(this.date);

  @override
  List<Object?> get props => [date]; // Include date in props for comparison
}

/// Event to add a new task
class AddTask extends TaskEvent {
  final TaskModel task;

  const AddTask(this.task);

  @override
  List<Object?> get props => [task];
}

/// Event to update an existing task
class UpdateTask extends TaskEvent {
  final TaskModel task;

  const UpdateTask(this.task);

  @override
  List<Object?> get props => [];
}

/// Event to toggle task completion
class ToggleTaskComplete extends TaskEvent {
  final String taskId;

  const ToggleTaskComplete(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

/// Event to delete a task (soft delete)
class DeleteTask extends TaskEvent {
  final String taskId;

  const DeleteTask(this.taskId);

  @override
  List<Object?> get props => [taskId];
}
