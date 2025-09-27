import 'package:dayflow/core/constants/app_constants.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:dayflow/data/repositories/base/base_repository.dart';
import 'package:dayflow/data/repositories/interfaces/task_repository_interface.dart';

class TaskRepository extends BaseRepository<TaskModel>
    implements ITaskRepository {
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
  @override
  Future<String> addTask(TaskModel task) async {
    return await add(task);
  }

  @override
  TaskModel? getTask(String id) {
    return get(id);
  }

  @override
  List<TaskModel> getAllTasks() {
    final tasks = getAll();
    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tasks;
  }

  @override
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

  @override
  Future<void> updateTask(TaskModel task) async {
    await update(task);
  }

  @override
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

  @override
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

  @override
  Future<void> clearAllTasks() async {
    await clearAll();
  }

  @override
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
