import 'package:dayflow/data/models/task_model.dart';
import 'package:dayflow/data/models/habit_model.dart';

abstract class SearchResult {
  String get id;
  String get title;
  String? get description;
  List<String> get tags;
  SearchResultType get type;
  DateTime get createdAt;
}

enum SearchResultType { task, note, habit }

class TaskSearchResult extends SearchResult {
  final TaskModel task;

  TaskSearchResult(this.task);

  @override
  String get id => task.id;

  @override
  String get title => task.title;

  @override
  String? get description => task.description;

  @override
  List<String> get tags => task.tags;

  @override
  SearchResultType get type =>
      task.isNote ? SearchResultType.note : SearchResultType.task;

  @override
  DateTime get createdAt => task.createdAt;

  bool get isCompleted => task.isCompleted;
  int get priority => task.priority;
  DateTime? get dueDate => task.dueDate;
  String get color => task.color;
}

class HabitSearchResult extends SearchResult {
  final HabitModel habit;

  HabitSearchResult(this.habit);

  @override
  String get id => habit.id;

  @override
  String get title => habit.title;

  @override
  String? get description => habit.description;

  @override
  List<String> get tags => habit.tags;

  @override
  SearchResultType get type => SearchResultType.habit;

  @override
  DateTime get createdAt => habit.createdAt;

  bool get isActive => habit.isActive;
  String get frequencyLabel => habit.frequencyLabel;
  int get currentStreak => habit.currentStreak;
  String get color => habit.color;
}
