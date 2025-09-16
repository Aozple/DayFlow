part of 'task_bloc.dart';

abstract class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {
  const TaskInitial();
}

class TaskLoading extends TaskState {
  final String? message;

  const TaskLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class TaskLoaded extends TaskState {
  final List<TaskModel> tasks;
  final DateTime? selectedDate;
  final TaskFilter? activeFilter;
  final TaskStatistics? statistics;
  final DateTime lastUpdated;

  TaskLoaded({
    required this.tasks,
    this.selectedDate,
    this.activeFilter,
    this.statistics,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  @override
  List<Object?> get props => [
    tasks,
    selectedDate,
    activeFilter,
    statistics,
    lastUpdated,
  ];

  // Computed properties
  List<TaskModel> get activeTasks =>
      tasks.where((task) => !task.isCompleted && !task.isDeleted).toList();

  List<TaskModel> get completedTasks =>
      tasks.where((task) => task.isCompleted && !task.isDeleted).toList();

  List<TaskModel> get deletedTasks =>
      tasks.where((task) => task.isDeleted).toList();

  List<TaskModel> get overdueTasks =>
      activeTasks.where((task) => task.isOverdue).toList();

  List<TaskModel> get todayTasks =>
      tasks.where((task) => task.isDueToday && !task.isDeleted).toList();

  List<TaskModel> get upcomingTasks =>
      activeTasks
          .where(
            (task) =>
                task.dueDate != null && task.dueDate!.isAfter(DateTime.now()),
          )
          .toList();

  Map<String, List<TaskModel>> get tasksByTag {
    final Map<String, List<TaskModel>> grouped = {};
    for (final task in activeTasks) {
      for (final tag in task.tags) {
        grouped.putIfAbsent(tag, () => []).add(task);
      }
    }
    return grouped;
  }

  Map<int, List<TaskModel>> get tasksByPriority {
    final Map<int, List<TaskModel>> grouped = {};
    for (final task in activeTasks) {
      grouped.putIfAbsent(task.priority, () => []).add(task);
    }
    return grouped;
  }

  int get activeCount => activeTasks.length;
  int get completedCount => completedTasks.length;
  int get overdueCount => overdueTasks.length;
  int get todayCount => todayTasks.length;

  double get completionRate {
    final total = tasks.where((t) => !t.isDeleted).length;
    if (total == 0) return 0.0;
    return completedCount / total;
  }

  // Helper methods
  List<TaskModel> getTasksForDate(DateTime date) {
    return tasks.where((task) {
      if (task.dueDate == null || task.isDeleted) return false;
      return task.dueDate!.year == date.year &&
          task.dueDate!.month == date.month &&
          task.dueDate!.day == date.day;
    }).toList();
  }

  List<TaskModel> getFilteredTasks([TaskFilter? filter]) {
    final f = filter ?? activeFilter;
    if (f == null) return tasks;

    var filtered = tasks.where((task) => !task.isDeleted).toList();

    // Apply filters
    if (f.priorities != null && f.priorities!.isNotEmpty) {
      filtered =
          filtered.where((t) => f.priorities!.contains(t.priority)).toList();
    }

    if (f.tags != null && f.tags!.isNotEmpty) {
      filtered =
          filtered
              .where((t) => t.tags.any((tag) => f.tags!.contains(tag)))
              .toList();
    }

    if (f.isCompleted != null) {
      filtered = filtered.where((t) => t.isCompleted == f.isCompleted).toList();
    }

    if (f.hasNotification != null) {
      filtered =
          filtered
              .where((t) => t.hasNotification == f.hasNotification)
              .toList();
    }

    if (f.dueDateFrom != null) {
      filtered =
          filtered
              .where(
                (t) =>
                    t.dueDate != null && !t.dueDate!.isBefore(f.dueDateFrom!),
              )
              .toList();
    }

    if (f.dueDateTo != null) {
      filtered =
          filtered
              .where(
                (t) => t.dueDate != null && !t.dueDate!.isAfter(f.dueDateTo!),
              )
              .toList();
    }

    if (f.searchQuery != null && f.searchQuery!.isNotEmpty) {
      final query = f.searchQuery!.toLowerCase();
      filtered =
          filtered
              .where(
                (t) =>
                    t.title.toLowerCase().contains(query) ||
                    (t.description?.toLowerCase().contains(query) ?? false) ||
                    t.tags.any((tag) => tag.toLowerCase().contains(query)),
              )
              .toList();
    }

    // Apply sorting
    filtered = _sortTasks(filtered, f.sortBy, f.sortAscending);

    return filtered;
  }

  List<TaskModel> _sortTasks(
    List<TaskModel> tasks,
    TaskSortOption sortBy,
    bool ascending,
  ) {
    final sorted = List<TaskModel>.from(tasks);

    switch (sortBy) {
      case TaskSortOption.dueDate:
        sorted.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case TaskSortOption.createdDate:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case TaskSortOption.priority:
        sorted.sort((a, b) => b.priority.compareTo(a.priority));
        break;
      case TaskSortOption.title:
        sorted.sort((a, b) => a.title.compareTo(b.title));
        break;
      case TaskSortOption.completionStatus:
        sorted.sort((a, b) => a.isCompleted ? 1 : -1);
        break;
    }

    return ascending ? sorted : sorted.reversed.toList();
  }

  TaskLoaded copyWith({
    List<TaskModel>? tasks,
    DateTime? selectedDate,
    TaskFilter? activeFilter,
    TaskStatistics? statistics,
    DateTime? lastUpdated,
  }) {
    return TaskLoaded(
      tasks: tasks ?? this.tasks,
      selectedDate: selectedDate ?? this.selectedDate,
      activeFilter: activeFilter ?? this.activeFilter,
      statistics: statistics ?? this.statistics,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class TaskError extends TaskState {
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;
  final List<TaskModel>? previousTasks; // Preserve previous state

  const TaskError(
    this.message, {
    this.error,
    this.stackTrace,
    this.previousTasks,
  });

  @override
  List<Object?> get props => [message, error, stackTrace, previousTasks];
}

class TaskOperationSuccess extends TaskState {
  final String message;
  final TaskOperation operation;
  final TaskModel? task;
  final List<TaskModel>? tasks;

  const TaskOperationSuccess({
    required this.message,
    required this.operation,
    this.task,
    this.tasks,
  });

  @override
  List<Object?> get props => [message, operation, task, tasks];
}

enum TaskOperation { add, update, delete, complete, restore, export, import }

class TaskStatistics {
  final int totalTasks;
  final int completedTasks;
  final int overdueTasks;
  final int todayTasks;
  final int upcomingTasks;
  final Map<int, int> tasksByPriority;
  final Map<String, int> tasksByTag;
  final double averageCompletionTime;
  final double completionRate;

  const TaskStatistics({
    required this.totalTasks,
    required this.completedTasks,
    required this.overdueTasks,
    required this.todayTasks,
    required this.upcomingTasks,
    required this.tasksByPriority,
    required this.tasksByTag,
    required this.averageCompletionTime,
    required this.completionRate,
  });

  factory TaskStatistics.fromTasks(List<TaskModel> tasks) {
    final activeTasks = tasks.where((t) => !t.isDeleted).toList();
    final completed = activeTasks.where((t) => t.isCompleted).toList();

    // Calculate average completion time
    double avgCompletionTime = 0;
    if (completed.isNotEmpty) {
      final totalMinutes = completed.fold(0, (sum, task) {
        if (task.completedAt != null) {
          return sum + task.completedAt!.difference(task.createdAt).inMinutes;
        }
        return sum;
      });
      avgCompletionTime = totalMinutes / completed.length;
    }

    // Group by priority
    final byPriority = <int, int>{};
    for (final task in activeTasks.where((t) => !t.isCompleted)) {
      byPriority[task.priority] = (byPriority[task.priority] ?? 0) + 1;
    }

    // Group by tag
    final byTag = <String, int>{};
    for (final task in activeTasks) {
      for (final tag in task.tags) {
        byTag[tag] = (byTag[tag] ?? 0) + 1;
      }
    }

    return TaskStatistics(
      totalTasks: activeTasks.length,
      completedTasks: completed.length,
      overdueTasks: activeTasks.where((t) => t.isOverdue).length,
      todayTasks: activeTasks.where((t) => t.isDueToday).length,
      upcomingTasks:
          activeTasks
              .where(
                (t) =>
                    !t.isCompleted &&
                    t.dueDate != null &&
                    t.dueDate!.isAfter(DateTime.now()),
              )
              .length,
      tasksByPriority: byPriority,
      tasksByTag: byTag,
      averageCompletionTime: avgCompletionTime,
      completionRate:
          activeTasks.isEmpty ? 0 : completed.length / activeTasks.length,
    );
  }
}
