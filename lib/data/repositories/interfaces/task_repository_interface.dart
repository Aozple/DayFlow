import 'package:dayflow/data/models/task_model.dart';

abstract class ITaskRepository {
  // CRUD operations
  Future<String> addTask(TaskModel task);
  TaskModel? getTask(String id);
  List<TaskModel> getAllTasks();
  List<TaskModel> getTasksByDate(DateTime date);
  Future<void> updateTask(TaskModel task);
  Future<void> deleteTask(String id);
  Future<void> toggleTaskComplete(String id);
  Future<void> clearAllTasks();

  // Statistics
  Map<String, dynamic> getStatistics();

  // Cache management
  void invalidateCache();
  bool isCacheValid();
}
