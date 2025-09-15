import 'package:dayflow/data/models/task_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Repository for task data operations using Hive database
class TaskRepository {
  // Reference to the Hive box storing tasks
  final Box _taskBox;

  // Initialize with the tasks box
  TaskRepository() : _taskBox = Hive.box('tasks');

  // Add a new task to the database
  Future<String> addTask(TaskModel task) async {
    try {
      // Store task using its ID as the key
      await _taskBox.put(task.id, task.toMap());
      return task.id;
    } catch (e) {
      throw Exception('Failed to add task: $e');
    }
  }

  // Get a single task by ID
  TaskModel? getTask(String id) {
    try {
      final taskMap = _taskBox.get(id);
      if (taskMap != null) {
        return TaskModel.fromMap(Map<String, dynamic>.from(taskMap));
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get task: $e');
    }
  }

  // Get all non-deleted tasks, sorted by creation date
  List<TaskModel> getAllTasks() {
    try {
      final tasks = <TaskModel>[];

      // Collect all non-deleted tasks
      for (var key in _taskBox.keys) {
        final taskMap = _taskBox.get(key);
        if (taskMap != null) {
          final task = TaskModel.fromMap(Map<String, dynamic>.from(taskMap));
          if (!task.isDeleted) {
            tasks.add(task);
          }
        }
      }

      // Sort by creation date (newest first)
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return tasks;
    } catch (e) {
      throw Exception('Failed to get tasks: $e');
    }
  }

  // Get tasks due on a specific date
  List<TaskModel> getTasksByDate(DateTime date) {
    try {
      final tasks = getAllTasks();

      // Filter tasks by matching due date
      return tasks.where((task) {
        if (task.dueDate == null) {
          return false;
        }

        // Compare year, month, and day
        return task.dueDate!.year == date.year &&
            task.dueDate!.month == date.month &&
            task.dueDate!.day == date.day;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get tasks by date: $e');
    }
  }

  // Update an existing task
  Future<void> updateTask(TaskModel task) async {
    try {
      await _taskBox.put(task.id, task.toMap());
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  // Soft delete a task (mark as deleted)
  Future<void> deleteTask(String id) async {
    try {
      final task = getTask(id);
      if (task != null) {
        final deletedTask = task.copyWith(isDeleted: true);
        await updateTask(deletedTask);
      }
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  // Permanently remove a task from the database
  Future<void> permanentlyDeleteTask(String id) async {
    try {
      await _taskBox.delete(id);
    } catch (e) {
      throw Exception('Failed to permanently delete task: $e');
    }
  }

  // Toggle task completion status
  Future<void> toggleTaskComplete(String id) async {
    try {
      final task = getTask(id);
      if (task != null) {
        final updatedTask = task.copyWith(
          isCompleted: !task.isCompleted,
          completedAt: !task.isCompleted ? DateTime.now() : null,
        );
        await updateTask(updatedTask);
      }
    } catch (e) {
      throw Exception('Failed to toggle task completion: $e');
    }
  }

  // Get task statistics for dashboard
  Map<String, dynamic> getStatistics() {
    final allTasks = getAllTasks();
    final today = DateTime.now();

    return {
      'total': allTasks.length,
      'completed': allTasks.where((t) => t.isCompleted).length,
      'pending': allTasks.where((t) => !t.isCompleted).length,
      'todayTasks': getTasksByDate(today).length,
      'overdue': allTasks.where((t) {
        if (t.dueDate == null || t.isCompleted) {
          return false;
        }
        return t.dueDate!.isBefore(today);
      }),
    };
  }

  // Remove all tasks from the database
  Future<void> clearAllTasks() async {
    try {
      await _taskBox.clear();
    } catch (e) {
      throw Exception('Failed to clear all tasks: $e');
    }
  }
}
