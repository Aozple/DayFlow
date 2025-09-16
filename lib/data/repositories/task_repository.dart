import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Repository for task data operations using Hive database
class TaskRepository {
  final Box _taskBox;

  TaskRepository() : _taskBox = Hive.box('tasks');

  // Deep conversion helper to handle nested maps and lists
  dynamic _convertValue(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(
        value.map((k, v) => MapEntry(k.toString(), _convertValue(v))),
      );
    } else if (value is List) {
      return value.map((item) => _convertValue(item)).toList();
    }
    return value;
  }

  Map<String, dynamic> _convertToTypedMap(dynamic data) {
    debugPrint('Converting data type: ${data.runtimeType}');

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      try {
        final converted = <String, dynamic>{};
        data.forEach((key, value) {
          converted[key.toString()] = _convertValue(value);
        });
        return converted;
      } catch (e) {
        debugPrint('Error in map conversion: $e');
        debugPrint('Map keys: ${data.keys.toList()}');
        debugPrint(
          'Map values types: ${data.values.map((v) => v.runtimeType).toList()}',
        );
        rethrow;
      }
    }

    throw Exception(
      'Cannot convert ${data.runtimeType} to Map<String, dynamic>',
    );
  }

  Future<String> addTask(TaskModel task) async {
    try {
      debugPrint('📝 Adding task to Hive: ${task.id}');
      await _taskBox.put(task.id, task.toMap());
      return task.id;
    } catch (e) {
      debugPrint('❌ Error adding task: $e');
      throw Exception('Failed to add task: $e');
    }
  }

  // Get a single task by ID
  TaskModel? getTask(String id) {
    try {
      final taskMap = _taskBox.get(id);
      if (taskMap != null) {
        debugPrint('📖 Reading task from Hive: $id');

        final typedMap = _convertToTypedMap(taskMap);
        return TaskModel.fromMap(typedMap);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting task $id: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      throw Exception('Failed to get task: $e');
    }
  }

  // Get all non-deleted tasks, sorted by creation date
  List<TaskModel> getAllTasks() {
    try {
      debugPrint('\n📚 Getting all tasks from Hive');
      debugPrint('Total keys in box: ${_taskBox.keys.length}');

      final tasks = <TaskModel>[];

      for (var key in _taskBox.keys) {
        try {
          final taskMap = _taskBox.get(key);
          if (taskMap != null) {
            debugPrint('\n🔍 Processing task: $key');

            final typedMap = _convertToTypedMap(taskMap);
            debugPrint('✅ Map converted successfully');

            final task = TaskModel.fromMap(typedMap);
            debugPrint('✅ Task created: ${task.title}');

            if (!task.isDeleted) {
              tasks.add(task);
            }
          }
        } catch (e) {
          debugPrint('❌ Error processing task $key: $e');

          // Try to print the raw data for debugging
          try {
            final rawData = _taskBox.get(key);
            debugPrint('Raw task data: $rawData');
          } catch (_) {}

          continue;
        }
      }

      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      debugPrint('\n✅ Successfully loaded ${tasks.length} tasks');

      return tasks;
    } catch (e) {
      debugPrint('❌ Fatal error in getAllTasks: $e');
      throw Exception('Failed to get tasks: $e');
    }
  }

  // Get tasks due on a specific date
  List<TaskModel> getTasksByDate(DateTime date) {
    try {
      debugPrint(
        '\n📅 Getting tasks for date: ${date.toString().split(' ')[0]}',
      );

      final tasks = getAllTasks();
      final filteredTasks =
          tasks.where((task) {
            if (task.dueDate == null) {
              return false;
            }

            return task.dueDate!.year == date.year &&
                task.dueDate!.month == date.month &&
                task.dueDate!.day == date.day;
          }).toList();

      debugPrint('✅ Found ${filteredTasks.length} tasks for this date');
      return filteredTasks;
    } catch (e) {
      debugPrint('❌ Error getting tasks by date: $e');
      throw Exception('Failed to get tasks by date: $e');
    }
  }

  // Update an existing task
  Future<void> updateTask(TaskModel task) async {
    try {
      debugPrint('🔄 Updating task: ${task.id}');
      await _taskBox.put(task.id, task.toMap());
    } catch (e) {
      debugPrint('❌ Error updating task: $e');
      throw Exception('Failed to update task: $e');
    }
  }

  // Soft delete a task (mark as deleted)
  Future<void> deleteTask(String id) async {
    try {
      debugPrint('🗑️ Soft deleting task: $id');
      final task = getTask(id);
      if (task != null) {
        final deletedTask = task.copyWith(isDeleted: true);
        await updateTask(deletedTask);
      }
    } catch (e) {
      debugPrint('❌ Error deleting task: $e');
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
      debugPrint('✅ Toggling task completion: $id');
      final task = getTask(id);
      if (task != null) {
        final updatedTask = task.copyWith(
          isCompleted: !task.isCompleted,
          completedAt: !task.isCompleted ? DateTime.now() : null,
        );
        await updateTask(updatedTask);
      }
    } catch (e) {
      debugPrint('❌ Error toggling task: $e');
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
      debugPrint('🧹 Clearing all tasks');
      await _taskBox.clear();
    } catch (e) {
      debugPrint('❌ Error clearing tasks: $e');
      throw Exception('Failed to clear all tasks: $e');
    }
  }
}
