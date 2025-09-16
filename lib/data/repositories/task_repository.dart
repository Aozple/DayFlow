import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TaskRepository {
  static const String _tag = 'TaskRepo';
  final Box _taskBox;

  // Cache for performance
  List<TaskModel>? _cachedTasks;
  DateTime? _lastCacheUpdate;
  static const Duration _cacheDuration = Duration(seconds: 30);

  TaskRepository() : _taskBox = Hive.box('tasks');

  // Deep conversion helper
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
        DebugLogger.error('Map conversion failed', tag: _tag, error: e);
        rethrow;
      }
    }

    throw Exception(
      'Cannot convert ${data.runtimeType} to Map<String, dynamic>',
    );
  }

  // Cache management
  void _invalidateCache() {
    _cachedTasks = null;
    _lastCacheUpdate = null;
    DebugLogger.verbose('Cache invalidated', tag: _tag);
  }

  bool _isCacheValid() {
    if (_cachedTasks == null || _lastCacheUpdate == null) return false;
    final age = DateTime.now().difference(_lastCacheUpdate!);
    return age < _cacheDuration;
  }

  Future<String> addTask(TaskModel task) async {
    return DebugLogger.timeOperation('Add Task', () async {
      try {
        await _taskBox.put(task.id, task.toMap());
        _invalidateCache();
        DebugLogger.success(
          'Task added: ${task.title}',
          tag: _tag,
          data: 'ID: ${task.id}',
        );
        return task.id;
      } catch (e) {
        DebugLogger.error('Failed to add task', tag: _tag, error: e);
        throw Exception('Failed to add task: $e');
      }
    });
  }

  TaskModel? getTask(String id) {
    try {
      DebugLogger.verbose('Getting task: $id', tag: _tag);

      // Check cache first
      if (_isCacheValid()) {
        final cached = _cachedTasks?.firstWhere(
          (t) => t.id == id,
          orElse: () => throw Exception('Not found'),
        );
        if (cached != null) {
          DebugLogger.verbose('Task found in cache', tag: _tag);
          return cached;
        }
      }

      final taskMap = _taskBox.get(id);
      if (taskMap != null) {
        final typedMap = _convertToTypedMap(taskMap);
        final task = TaskModel.fromMap(typedMap);
        DebugLogger.success('Task retrieved: ${task.title}', tag: _tag);
        return task;
      }

      DebugLogger.warning('Task not found: $id', tag: _tag);
      return null;
    } catch (e) {
      DebugLogger.error('Failed to get task', tag: _tag, error: e);
      return null;
    }
  }

  List<TaskModel> getAllTasks() {
    try {
      // Return cached if valid
      if (_isCacheValid()) {
        DebugLogger.info(
          'Returning cached tasks',
          tag: _tag,
          data: '${_cachedTasks!.length} tasks',
        );
        return _cachedTasks!;
      }

      final stopwatch = Stopwatch()..start();
      DebugLogger.info('Loading tasks from storage', tag: _tag);
      final tasks = <TaskModel>[];

      for (var key in _taskBox.keys) {
        try {
          final taskMap = _taskBox.get(key);
          if (taskMap != null) {
            final typedMap = _convertToTypedMap(taskMap);
            final task = TaskModel.fromMap(typedMap);

            if (!task.isDeleted) {
              tasks.add(task);
            }
          }
        } catch (e) {
          DebugLogger.warning(
            'Skipping corrupted task: $key',
            tag: _tag,
            data: e.toString(),
          );
          continue;
        }
      }

      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Update cache
      _cachedTasks = tasks;
      _lastCacheUpdate = DateTime.now();

      stopwatch.stop();
      DebugLogger.success(
        'Tasks loaded successfully',
        tag: _tag,
        data:
            '${tasks.length} active tasks (${stopwatch.elapsedMilliseconds}ms)',
      );

      return tasks;
    } catch (e) {
      DebugLogger.error('Failed to get all tasks', tag: _tag, error: e);
      return _cachedTasks ?? [];
    }
  }

  List<TaskModel> getTasksByDate(DateTime date) {
    try {
      DebugLogger.info(
        'Getting tasks for date',
        tag: _tag,
        data: date.toString().split(' ')[0],
      );

      final tasks = getAllTasks();
      final filteredTasks =
          tasks.where((task) {
            if (task.dueDate == null) return false;
            return task.dueDate!.year == date.year &&
                task.dueDate!.month == date.month &&
                task.dueDate!.day == date.day;
          }).toList();

      DebugLogger.success(
        'Tasks filtered by date',
        tag: _tag,
        data: '${filteredTasks.length} tasks found',
      );

      return filteredTasks;
    } catch (e) {
      DebugLogger.error('Failed to get tasks by date', tag: _tag, error: e);
      return [];
    }
  }

  Future<void> updateTask(TaskModel task) async {
    return DebugLogger.timeOperation('Update Task', () async {
      try {
        await _taskBox.put(task.id, task.toMap());
        _invalidateCache();
        DebugLogger.success('Task updated: ${task.title}', tag: _tag);
      } catch (e) {
        DebugLogger.error('Failed to update task', tag: _tag, error: e);
        throw Exception('Failed to update task: $e');
      }
    });
  }

  Future<void> deleteTask(String id) async {
    return DebugLogger.timeOperation('Delete Task', () async {
      try {
        final task = getTask(id);
        if (task != null) {
          final deletedTask = task.copyWith(isDeleted: true);
          await updateTask(deletedTask);
          DebugLogger.success('Task soft deleted: ${task.title}', tag: _tag);
        } else {
          DebugLogger.warning('Task not found for deletion: $id', tag: _tag);
        }
      } catch (e) {
        DebugLogger.error('Failed to delete task', tag: _tag, error: e);
        throw Exception('Failed to delete task: $e');
      }
    });
  }

  Future<void> toggleTaskComplete(String id) async {
    return DebugLogger.timeOperation('Toggle Task', () async {
      try {
        final task = getTask(id);
        if (task != null) {
          final updatedTask = task.copyWith(
            isCompleted: !task.isCompleted,
            completedAt: !task.isCompleted ? DateTime.now() : null,
          );
          await updateTask(updatedTask);
          DebugLogger.success(
            'Task ${updatedTask.isCompleted ? "completed" : "uncompleted"}: ${task.title}',
            tag: _tag,
          );
        }
      } catch (e) {
        DebugLogger.error('Failed to toggle task', tag: _tag, error: e);
        throw Exception('Failed to toggle task completion: $e');
      }
    });
  }

  Future<void> clearAllTasks() async {
    return DebugLogger.timeOperation('Clear All Tasks', () async {
      try {
        await _taskBox.clear();
        _invalidateCache();
        DebugLogger.success('All tasks cleared', tag: _tag);
      } catch (e) {
        DebugLogger.error('Failed to clear tasks', tag: _tag, error: e);
        throw Exception('Failed to clear all tasks: $e');
      }
    });
  }

  Map<String, dynamic> getStatistics() {
    try {
      final allTasks = getAllTasks();
      final today = DateTime.now();

      final stats = {
        'total': allTasks.length,
        'completed': allTasks.where((t) => t.isCompleted).length,
        'pending': allTasks.where((t) => !t.isCompleted).length,
        'todayTasks': getTasksByDate(today).length,
        'overdue':
            allTasks.where((t) {
              if (t.dueDate == null || t.isCompleted) return false;
              return t.dueDate!.isBefore(today);
            }).length,
      };

      DebugLogger.info('Statistics calculated', tag: _tag, data: stats);
      return stats;
    } catch (e) {
      DebugLogger.error('Failed to get statistics', tag: _tag, error: e);
      return {};
    }
  }
}
