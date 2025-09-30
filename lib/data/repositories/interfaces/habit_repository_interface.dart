import 'package:dayflow/data/models/habit_model.dart';
import 'package:dayflow/data/models/habit_instance_model.dart';

abstract class IHabitRepository {
  Future<String> addHabit(HabitModel habit);
  HabitModel? getHabit(String id);
  List<HabitModel> getAllHabits();
  Future<void> updateHabit(HabitModel habit);
  Future<void> deleteHabit(String id);

  Future<void> addInstance(HabitInstanceModel instance);
  HabitInstanceModel? getInstance(String id);
  List<HabitInstanceModel> getInstancesByHabitId(String habitId);
  List<HabitInstanceModel> getInstancesByDate(DateTime date);
  Future<void> updateInstance(HabitInstanceModel instance);
  Future<void> completeInstance(String instanceId, {int? value});

  Future<void> generateInstances(HabitModel habit, {int daysAhead});

  Map<String, dynamic> getStatistics();

  Future<void> clearAllHabits();
}
