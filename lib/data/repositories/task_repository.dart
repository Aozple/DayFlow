import 'package:dayflow/core/constants/app_constants.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:dayflow/data/repositories/base/base_repository.dart';

class TaskRepository extends BaseRepository<TaskModel> {
  static const String _tag = 'TaskRepo';

  TaskRepository() : super(boxName: AppConstants.tasksBox, tag: _tag);

  @override
  TaskModel fromMap(Map<String, dynamic> map) => TaskModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(TaskModel item) => item.toMap();

  @override
  String getId(TaskModel item) => item.id;

  @override
  bool isDeleted(TaskModel item) => item.isDeleted;

  // Task-specific methods
  Future<String> addTask(TaskModel task) async {
    return await add(task);
  }

  TaskModel? getTask(String id) {
    return get(id);
  }

  List<TaskModel> getAllTasks() {
    final tasks = getAll();
    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tasks;
  }

  List<TaskModel> getTasksByDate(DateTime date) {
    try {
      DebugLogger.info('Getting tasks for date', tag: tag, data: date);

      final tasks = getAllTasks();
      final filteredTasks =
          tasks.where((task) {
            if (task.dueDate == null) return false;
            return task.dueDate!.year == date.year &&
                task.dueDate!.month == date.month &&
                task.dueDate!.day == date.day;
          }).toList();

      DebugLogger.success(
        'Tasks filtered',
        tag: tag,
        data: '${filteredTasks.length} tasks',
      );
      return filteredTasks;
    } catch (e) {
      DebugLogger.error('Failed to get tasks by date', tag: tag, error: e);
      return [];
    }
  }

  Future<void> updateTask(TaskModel task) async {
    await update(task);
  }

  Future<void> deleteTask(String id) async {
    try {
      final task = getTask(id);
      if (task != null) {
        // Soft delete
        final deletedTask = task.copyWith(isDeleted: true);
        await updateTask(deletedTask);
        DebugLogger.success('Task soft deleted', tag: tag);
      } else {
        DebugLogger.warning('Task not found for deletion', tag: tag);
      }
    } catch (e) {
      DebugLogger.error('Failed to delete task', tag: tag, error: e);
      throw Exception('Failed to delete task: $e');
    }
  }

  Future<void> toggleTaskComplete(String id) async {
    try {
      final task = getTask(id);
      if (task != null) {
        final updatedTask = task.copyWith(
          isCompleted: !task.isCompleted,
          completedAt: !task.isCompleted ? DateTime.now() : null,
        );
        await updateTask(updatedTask);
        DebugLogger.success('Task toggled', tag: tag);
      }
    } catch (e) {
      DebugLogger.error('Failed to toggle task', tag: tag, error: e);
      throw Exception('Failed to toggle task: $e');
    }
  }

  Future<void> clearAllTasks() async {
    await clearAll();
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

      DebugLogger.info('Statistics calculated', tag: tag, data: stats);
      return stats;
    } catch (e) {
      DebugLogger.error('Failed to get statistics', tag: tag, error: e);
      return {};
    }
  }
}
