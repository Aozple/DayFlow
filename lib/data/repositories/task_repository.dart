import 'package:dayflow/core/constants/app_constants.dart';
import 'package:dayflow/core/utils/app_date_utils.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:dayflow/data/repositories/base/base_repository.dart';
import 'package:dayflow/data/repositories/interfaces/task_repository_interface.dart';

class TaskRepository extends BaseRepository<TaskModel>
    implements ITaskRepository {
  static const String _tag = 'TaskRepo';

  Map<String, dynamic>? _cachedStats;
  DateTime? _lastStatsUpdate;
  static const Duration _statsCacheDuration = AppConstants.defaultCacheDuration;

  TaskRepository() : super(boxName: AppConstants.tasksBox, tag: _tag);

  @override
  TaskModel fromMap(Map<String, dynamic> map) => TaskModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(TaskModel item) => item.toMap();

  @override
  String getId(TaskModel item) => item.id;

  @override
  bool isDeleted(TaskModel item) => item.isDeleted;

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

    if (tasks.length <= 1) return tasks;

    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tasks;
  }

  @override
  List<TaskModel> getTasksByDate(DateTime date, {bool useCache = true}) {
    try {
      DebugLogger.verbose(
        'Getting tasks for date',
        tag: tag,
        data: date.toString().split(' ')[0],
      );

      final tasks =
          useCache
              ? getAll(operationType: 'filter')
              : getAll(forceRefresh: true);

      final targetDate = DateTime(date.year, date.month, date.day);

      final filteredTasks =
          tasks.where((task) {
            if (task.dueDate == null || task.isDeleted) return false;

            final taskDate = DateTime(
              task.dueDate!.year,
              task.dueDate!.month,
              task.dueDate!.day,
            );

            return taskDate == targetDate;
          }).toList();

      DebugLogger.success(
        'Tasks filtered by date',
        tag: tag,
        data: '${filteredTasks.length}/${tasks.length} tasks',
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
  void invalidateCache() {
    super.invalidateCache();
    _cachedStats = null;
    _lastStatsUpdate = null;
    DebugLogger.verbose('Task statistics cache invalidated', tag: tag);
  }

  @override
  Map<String, dynamic> getStatistics({bool forceRefresh = false}) {
    try {
      if (!forceRefresh &&
          _cachedStats != null &&
          _lastStatsUpdate != null &&
          AppDateUtils.now.difference(_lastStatsUpdate!) < _statsCacheDuration) {
        DebugLogger.verbose('Statistics cache hit', tag: tag);
        return _cachedStats!;
      }

      final allTasks = getAll(operationType: 'read');
      final today = DateTime(
        AppDateUtils.now.year,
        AppDateUtils.now.month,
        AppDateUtils.now.day,
      );

      int completed = 0;
      int pending = 0;
      int overdue = 0;
      int todayTasks = 0;
      int totalActive = 0;

      for (final task in allTasks) {
        if (task.isDeleted) continue;

        totalActive++;

        if (task.isCompleted) {
          completed++;
          continue;
        }

        pending++;

        if (task.dueDate != null) {
          final taskDay = DateTime(
            task.dueDate!.year,
            task.dueDate!.month,
            task.dueDate!.day,
          );

          if (taskDay == today) {
            todayTasks++;
          } else if (taskDay.isBefore(today)) {
            overdue++;
          }
        }
      }

      _cachedStats = {
        'total': totalActive,
        'completed': completed,
        'pending': pending,
        'todayTasks': todayTasks,
        'overdue': overdue,
        'completionRate': totalActive == 0 ? 0.0 : completed / totalActive,
      };

      _lastStatsUpdate = AppDateUtils.now;

      DebugLogger.success(
        'Statistics calculated and cached',
        tag: tag,
        data: _cachedStats,
      );
      return _cachedStats!;
    } catch (e) {
      DebugLogger.error('Failed to get statistics', tag: tag, error: e);
      return _cachedStats ?? {};
    }
  }
}
