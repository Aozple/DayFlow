import 'package:dayflow/data/models/task_model.dart';

abstract class ITaskRepository {
  Future<String> addTask(TaskModel task);
  TaskModel? getTask(String id);
  List<TaskModel> getAllTasks();
  List<TaskModel> getTasksByDate(DateTime date);
  Future<void> updateTask(TaskModel task);
  Future<void> deleteTask(String id);
  Future<void> toggleTaskComplete(String id);
  Future<void> clearAllTasks();

  Map<String, dynamic> getStatistics();

  void invalidateCache();
  bool isCacheValid();
}
