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

  const TaskLoaded({
    required this.tasks,
    this.selectedDate,
    this.activeFilter,
    this.statistics,
    required this.lastUpdated,
  });

  TaskLoaded.create({
    required this.tasks,
    this.selectedDate,
    this.activeFilter,
    this.statistics,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? AppDateUtils.now;

  @override
  List<Object?> get props => [
    tasks.length,
    _generateTasksSignature(),
    selectedDate,
    activeFilter,
    statistics,
    lastUpdated.millisecondsSinceEpoch ~/ 1000,
  ];

  @override
  int get hashCode => Object.hash(
    tasks.length,
    _generateTasksSignature(),
    selectedDate,
    activeFilter,
    statistics,
    lastUpdated.millisecondsSinceEpoch ~/ 1000,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TaskLoaded &&
        tasks.length == other.tasks.length &&
        selectedDate == other.selectedDate &&
        activeFilter == other.activeFilter &&
        _tasksContentEqual(other.tasks) &&
        ((lastUpdated.difference(other.lastUpdated).abs().inSeconds) < 2);
  }

  String _generateTasksSignature() {
    if (tasks.isEmpty) return 'empty';

    final buffer = StringBuffer();
    for (final task in tasks) {
      buffer.write('${task.id}_${task.isCompleted}_${task.title.hashCode}');
      if (buffer.length > 200) break;
    }
    return buffer.toString();
  }

  bool _tasksContentEqual(List<TaskModel> otherTasks) {
    if (tasks.length != otherTasks.length) return false;

    for (int i = 0; i < tasks.length; i++) {
      final a = tasks[i];
      final b = otherTasks[i];
      if (a.id != b.id ||
          a.isCompleted != b.isCompleted ||
          a.title != b.title ||
          a.createdAt != b.createdAt) {
        return false;
      }
    }
    return true;
  }

  List<TaskModel> get activeTasks =>
      _filterTasks(predicate: (task) => !task.isCompleted && !task.isDeleted);

  List<TaskModel> get completedTasks =>
      _filterTasks(predicate: (task) => task.isCompleted && !task.isDeleted);

  List<TaskModel> get deletedTasks =>
      _filterTasks(predicate: (task) => task.isDeleted);

  List<TaskModel> get overdueTasks => _filterTasks(
    predicate: (task) => !task.isCompleted && !task.isDeleted && task.isOverdue,
  );

  List<TaskModel> get todayTasks =>
      _filterTasks(predicate: (task) => !task.isDeleted && task.isDueToday);

  List<TaskModel> get upcomingTasks => _filterTasks(
    predicate:
        (task) =>
            !task.isCompleted &&
            !task.isDeleted &&
            task.dueDate != null &&
            task.dueDate!.isAfter(AppDateUtils.now),
  );

  List<TaskModel> _filterTasks({required bool Function(TaskModel) predicate}) {
    final result = <TaskModel>[];
    for (final task in tasks) {
      if (predicate(task)) {
        result.add(task);
      }
    }
    return result;
  }

  Map<String, List<TaskModel>> get tasksByTag {
    final Map<String, List<TaskModel>> grouped = {};
    final active = activeTasks;

    for (final task in active) {
      for (final tag in task.tags) {
        grouped.putIfAbsent(tag, () => []).add(task);
      }
    }
    return grouped;
  }

  Map<int, List<TaskModel>> get tasksByPriority {
    final Map<int, List<TaskModel>> grouped = {};
    final active = activeTasks;

    for (final task in active) {
      grouped.putIfAbsent(task.priority, () => []).add(task);
    }
    return grouped;
  }

  int get activeCount =>
      _countTasks((task) => !task.isCompleted && !task.isDeleted);
  int get completedCount =>
      _countTasks((task) => task.isCompleted && !task.isDeleted);
  int get overdueCount => _countTasks(
    (task) => !task.isCompleted && !task.isDeleted && task.isOverdue,
  );
  int get todayCount =>
      _countTasks((task) => !task.isDeleted && task.isDueToday);

  int _countTasks(bool Function(TaskModel) predicate) {
    int count = 0;
    for (final task in tasks) {
      if (predicate(task)) count++;
    }
    return count;
  }

  double get completionRate {
    final total = _countTasks((task) => !task.isDeleted);
    if (total == 0) return 0.0;
    return completedCount / total;
  }

  List<TaskModel> getTasksForDate(DateTime date) {
    return _filterTasks(
      predicate: (task) {
        if (task.dueDate == null || task.isDeleted) return false;
        final dueDate = task.dueDate!;
        return dueDate.year == date.year &&
            dueDate.month == date.month &&
            dueDate.day == date.day;
      },
    );
  }

  List<TaskModel> getFilteredTasks([TaskFilter? filter]) {
    final f = filter ?? activeFilter;
    if (f == null) return tasks.where((task) => !task.isDeleted).toList();

    var filtered = tasks.where((task) => !task.isDeleted).toList();

    if (f.priorities?.isNotEmpty == true) {
      filtered =
          filtered.where((t) => f.priorities!.contains(t.priority)).toList();
    }

    if (f.tags?.isNotEmpty == true) {
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

    if (f.searchQuery?.isNotEmpty == true) {
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

    return _sortTasks(filtered, f.sortBy, f.sortAscending);
  }

  List<TaskModel> _sortTasks(
    List<TaskModel> tasksToSort,
    TaskSortOption sortBy,
    bool ascending,
  ) {
    final sorted = List<TaskModel>.from(tasksToSort);

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
    return TaskLoaded.create(
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
  final List<TaskModel>? previousTasks;

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

    final byPriority = <int, int>{};
    for (final task in activeTasks.where((t) => !t.isCompleted)) {
      byPriority[task.priority] = (byPriority[task.priority] ?? 0) + 1;
    }

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
                    t.dueDate!.isAfter(AppDateUtils.now),
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
