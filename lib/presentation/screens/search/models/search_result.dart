import 'package:dayflow/data/models/task_model.dart';
import 'package:dayflow/data/models/habit_model.dart';

/// Base class for all search results
abstract class SearchResult {
  String get id;
  String get title;
  String? get description;
  List<String> get tags;
  SearchResultType get type;
  DateTime get createdAt;
}

/// Types of searchable content
enum SearchResultType { task, note, habit }

/// Task search result implementation
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

  // Task-specific properties
  bool get isCompleted => task.isCompleted;
  int get priority => task.priority;
  DateTime? get dueDate => task.dueDate;
  String get color => task.color;
}

/// Habit search result implementation
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

  // Habit-specific properties
  bool get isActive => habit.isActive;
  String get frequencyLabel => habit.frequencyLabel;
  int get currentStreak => habit.currentStreak;
  String get color => habit.color;
}
