import 'package:dayflow/data/models/task_model.dart';
import 'package:equatable/equatable.dart';

/// Base class for all task states
abstract class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object?> get props => [];
}

/// Initial state when app starts
class TaskInitial extends TaskState {
  const TaskInitial();
}

/// Loading state while fetching data
class TaskLoading extends TaskState {
  const TaskLoading();
}

/// Success state with loaded tasks
class TaskLoaded extends TaskState {
  final List<TaskModel> tasks;
  final DateTime? selectedDate; // Currently selected date (if any)

  const TaskLoaded({required this.tasks, this.selectedDate});

  @override
  List<Object?> get props => [tasks, selectedDate];

  /// Helper getters for UI
  List<TaskModel> get activeTasks =>
      tasks.where((task) => !task.isCompleted && !task.isDeleted).toList();

  List<TaskModel> get completedTasks =>
      tasks.where((task) => task.isCompleted && !task.isDeleted).toList();

  int get activeCount => activeTasks.length;
  int get completedCount => completedTasks.length;
}

/// Error state when something goes wrong
class TaskError extends TaskState {
  final String message;
  
  const TaskError(this.message);
  
  @override
  List<Object?> get props => [message];
}

/// State for specific operations
class TaskOperationSuccess extends TaskState {
  final String message;
  
  const TaskOperationSuccess(this.message);
  
  @override
  List<Object?> get props => [message];
}