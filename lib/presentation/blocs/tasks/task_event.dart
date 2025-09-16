part of 'task_bloc.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

// Load events
class LoadTasks extends TaskEvent {
  final bool forceRefresh;

  const LoadTasks({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class LoadTasksByDate extends TaskEvent {
  final DateTime date;
  final bool includeCompleted;

  const LoadTasksByDate(this.date, {this.includeCompleted = true});

  @override
  List<Object?> get props => [date, includeCompleted];
}

class LoadTasksByDateRange extends TaskEvent {
  final DateTime startDate;
  final DateTime endDate;
  final bool includeCompleted;

  const LoadTasksByDateRange({
    required this.startDate,
    required this.endDate,
    this.includeCompleted = true,
  });

  @override
  List<Object?> get props => [startDate, endDate, includeCompleted];
}

// CRUD events
class AddTask extends TaskEvent {
  final TaskModel task;
  final bool showNotification;

  const AddTask(this.task, {this.showNotification = true});

  @override
  List<Object?> get props => [task, showNotification];
}

class AddMultipleTasks extends TaskEvent {
  final List<TaskModel> tasks;

  const AddMultipleTasks(this.tasks);

  @override
  List<Object?> get props => [tasks];
}

class UpdateTask extends TaskEvent {
  final TaskModel task;
  final bool preserveNotification;

  const UpdateTask(this.task, {this.preserveNotification = false});

  @override
  List<Object?> get props => [task, preserveNotification];
}

class BatchUpdateTasks extends TaskEvent {
  final List<TaskModel> tasks;
  final Map<String, dynamic>? updates;

  const BatchUpdateTasks({required this.tasks, this.updates});

  @override
  List<Object?> get props => [tasks, updates];
}

class ToggleTaskComplete extends TaskEvent {
  final String taskId;
  final bool silent;

  const ToggleTaskComplete(this.taskId, {this.silent = false});

  @override
  List<Object?> get props => [taskId, silent];
}

class DeleteTask extends TaskEvent {
  final String taskId;
  final bool permanent;

  const DeleteTask(this.taskId, {this.permanent = false});

  @override
  List<Object?> get props => [taskId, permanent];
}

class DeleteMultipleTasks extends TaskEvent {
  final List<String> taskIds;
  final bool permanent;

  const DeleteMultipleTasks(this.taskIds, {this.permanent = false});

  @override
  List<Object?> get props => [taskIds, permanent];
}

// Filter and search events
class FilterTasks extends TaskEvent {
  final TaskFilter filter;

  const FilterTasks(this.filter);

  @override
  List<Object?> get props => [filter];
}

class SearchTasks extends TaskEvent {
  final String query;
  final TaskSearchOptions? options;

  const SearchTasks(this.query, {this.options});

  @override
  List<Object?> get props => [query, options];
}

// Utility events
class ClearError extends TaskEvent {
  const ClearError();
}

class RestoreTasks extends TaskEvent {
  final List<String> taskIds;

  const RestoreTasks(this.taskIds);

  @override
  List<Object?> get props => [taskIds];
}

class ExportTasks extends TaskEvent {
  final String format; // 'json', 'csv', 'markdown'
  final TaskFilter? filter;

  const ExportTasks({this.format = 'json', this.filter});

  @override
  List<Object?> get props => [format, filter];
}

class ImportTasks extends TaskEvent {
  final String data;
  final String format;
  final bool merge; // Merge with existing or replace

  const ImportTasks({
    required this.data,
    required this.format,
    this.merge = true,
  });

  @override
  List<Object?> get props => [data, format, merge];
}

// Filter model
class TaskFilter extends Equatable {
  final List<int>? priorities;
  final List<String>? tags;
  final bool? isCompleted;
  final bool? hasNotification;
  final DateTime? dueDateFrom;
  final DateTime? dueDateTo;
  final String? searchQuery;
  final TaskSortOption sortBy;
  final bool sortAscending;

  const TaskFilter({
    this.priorities,
    this.tags,
    this.isCompleted,
    this.hasNotification,
    this.dueDateFrom,
    this.dueDateTo,
    this.searchQuery,
    this.sortBy = TaskSortOption.dueDate,
    this.sortAscending = true,
  });

  @override
  List<Object?> get props => [
    priorities,
    tags,
    isCompleted,
    hasNotification,
    dueDateFrom,
    dueDateTo,
    searchQuery,
    sortBy,
    sortAscending,
  ];

  TaskFilter copyWith({
    List<int>? priorities,
    List<String>? tags,
    bool? isCompleted,
    bool? hasNotification,
    DateTime? dueDateFrom,
    DateTime? dueDateTo,
    String? searchQuery,
    TaskSortOption? sortBy,
    bool? sortAscending,
  }) {
    return TaskFilter(
      priorities: priorities ?? this.priorities,
      tags: tags ?? this.tags,
      isCompleted: isCompleted ?? this.isCompleted,
      hasNotification: hasNotification ?? this.hasNotification,
      dueDateFrom: dueDateFrom ?? this.dueDateFrom,
      dueDateTo: dueDateTo ?? this.dueDateTo,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  bool get hasActiveFilters {
    return priorities != null ||
        tags != null ||
        isCompleted != null ||
        hasNotification != null ||
        dueDateFrom != null ||
        dueDateTo != null ||
        (searchQuery != null && searchQuery!.isNotEmpty);
  }
}

enum TaskSortOption { dueDate, createdDate, priority, title, completionStatus }

class TaskSearchOptions extends Equatable {
  final bool searchTitle;
  final bool searchDescription;
  final bool searchTags;
  final bool searchNotes;
  final bool caseSensitive;

  const TaskSearchOptions({
    this.searchTitle = true,
    this.searchDescription = true,
    this.searchTags = true,
    this.searchNotes = false,
    this.caseSensitive = false,
  });

  @override
  List<Object?> get props => [
    searchTitle,
    searchDescription,
    searchTags,
    searchNotes,
    caseSensitive,
  ];
}
