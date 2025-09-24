import 'package:dayflow/data/models/habit_model.dart';
import 'package:dayflow/data/models/habit_instance_model.dart';

abstract class IHabitRepository {
  // Habit CRUD
  Future<String> addHabit(HabitModel habit);
  HabitModel? getHabit(String id);
  List<HabitModel> getAllHabits();
  Future<void> updateHabit(HabitModel habit);
  Future<void> deleteHabit(String id);

  // Instance CRUD
  Future<void> addInstance(HabitInstanceModel instance);
  HabitInstanceModel? getInstance(String id);
  List<HabitInstanceModel> getInstancesByHabitId(String habitId);
  List<HabitInstanceModel> getInstancesByDate(DateTime date);
  Future<void> updateInstance(HabitInstanceModel instance);
  Future<void> completeInstance(String instanceId, {int? value});

  // Instance generation
  Future<void> generateInstances(HabitModel habit, {int daysAhead});

  // Statistics
  Map<String, dynamic> getStatistics();

  // Clear
  Future<void> clearAllHabits();
}
