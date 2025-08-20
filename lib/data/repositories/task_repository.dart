import 'package:dayflow/data/models/task_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

// This class acts as a bridge between our app's task logic and the database.
// It uses Hive, a local NoSQL database, to store and retrieve task data.
class TaskRepository {
  // This is our reference to the 'tasks' box in Hive, where all task data lives.
  final Box _taskBox;

  // The constructor initializes the repository by getting the 'tasks' box.
  TaskRepository() : _taskBox = Hive.box('tasks');

  // Adds a new task to the database.
  // It takes a TaskModel object and saves its data.
  // Returns the ID of the newly added task.
  Future<String> addTask(TaskModel task) async {
    try {
      // We store the task as a Map, using its ID as the key for easy retrieval.
      await _taskBox.put(task.id, task.toMap());
      return task.id;
    } catch (e) {
      // If something goes wrong, we throw an exception.
      throw Exception('Failed to add task: $e');
    }
  }

  // Retrieves a single task from the database using its ID.
  // Returns the TaskModel if found, otherwise returns null.
  TaskModel? getTask(String id) {
    try {
      final taskMap = _taskBox.get(id); // Get the task data as a Map.
      if (taskMap != null) {
        // Convert the Map back into a TaskModel object.
        return TaskModel.fromMap(Map<String, dynamic>.from(taskMap));
      }
      return null; // Task not found.
    } catch (e) {
      throw Exception('Failed to get task: $e');
    }
  }

  // Fetches all tasks that haven't been marked as deleted.
  // The tasks are sorted by their creation date, with the newest ones first.
  List<TaskModel> getAllTasks() {
    try {
      final tasks = <TaskModel>[];

      // Loop through all entries in the task box.
      for (var key in _taskBox.keys) {
        final taskMap = _taskBox.get(key);
        if (taskMap != null) {
          final task = TaskModel.fromMap(Map<String, dynamic>.from(taskMap));

          // Only add tasks that are not marked as deleted.
          if (!task.isDeleted) {
            tasks.add(task);
          }
        }
      }

      // Sort the tasks so the most recently created ones appear first.
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return tasks;
    } catch (e) {
      throw Exception('Failed to get tasks: $e');
    }
  }

  // Retrieves tasks that are due on a specific date.
  // This is super handy for displaying tasks in a daily view.
  List<TaskModel> getTasksByDate(DateTime date) {
    try {
      final tasks = getAllTasks(); // Get all tasks first.

      // Filter the tasks to only include those whose due date matches the given date.
      return tasks.where((task) {
        if (task.dueDate == null) {
          return false; // If a task has no due date, it's not for this specific day.
        }

        // Compare year, month, and day to see if it's the same day.
        return task.dueDate!.year == date.year &&
            task.dueDate!.month == date.month &&
            task.dueDate!.day == date.day;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get tasks by date: $e');
    }
  }

  // Updates an existing task in the database.
  // It takes an updated TaskModel object and saves its new state.
  Future<void> updateTask(TaskModel task) async {
    try {
      await _taskBox.put(task.id, task.toMap()); // Overwrite the existing task with the new data.
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  // Performs a "soft delete" on a task.
  // Instead of removing it completely, it just marks the task as deleted.
  // This allows for potential recovery later.
  Future<void> deleteTask(String id) async {
    try {
      final task = getTask(id); // Get the task first.
      if (task != null) {
        // Create a copy of the task, but set `isDeleted` to true.
        final deletedTask = task.copyWith(isDeleted: true);
        await updateTask(deletedTask); // Update the task in the database.
      }
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  // Permanently deletes a task from the database.
  // Use this with extreme caution, as the data cannot be recovered after this.
  Future<void> permanentlyDeleteTask(String id) async {
    try {
      await _taskBox.delete(id); // Remove the task entry completely.
    } catch (e) {
      throw Exception('Failed to permanently delete task: $e');
    }
  }

  // Toggles the completion status of a task (completed/pending).
  // It also updates the `completedAt` timestamp.
  Future<void> toggleTaskComplete(String id) async {
    try {
      final task = getTask(id); // Get the task.
      if (task != null) {
        // Create an updated task with the toggled `isCompleted` status
        // and set `completedAt` accordingly.
        final updatedTask = task.copyWith(
          isCompleted: !task.isCompleted,
          completedAt: !task.isCompleted ? DateTime.now() : null,
        );
        await updateTask(updatedTask); // Save the updated task.
      }
    } catch (e) {
      throw Exception('Failed to toggle task completion: $e');
    }
  }

  // Gathers various statistics about tasks for display on a dashboard.
  // Returns a Map containing total, completed, pending, today's tasks, and overdue tasks.
  Map<String, dynamic> getStatistics() {
    final allTasks = getAllTasks(); // Get all non-deleted tasks.
    final today = DateTime.now(); // Get the current date.

    return {
      'total': allTasks.length, // Total number of tasks.
      'completed': allTasks.where((t) => t.isCompleted).length, // Number of completed tasks.
      'pending': allTasks.where((t) => !t.isCompleted).length, // Number of pending tasks.
      'todayTasks': getTasksByDate(today).length, // Number of tasks due today.
      'overdue': allTasks.where((t) {
        // Count tasks that are not completed and have a due date before today.
        if (t.dueDate == null || t.isCompleted) {
          return false;
        }
        return t.dueDate!.isBefore(today);
      }),
    };
  }

  // Clears all tasks from the database.
  // This is a powerful operation and should be used with extreme caution!
  Future<void> clearAllTasks() async {
    try {
      await _taskBox.clear(); // Remove all entries from the 'tasks' box.
    } catch (e) {
      throw Exception('Failed to clear all tasks: $e');
    }
  }
}
