part of 'habit_bloc.dart';

abstract class HabitState extends Equatable {
  const HabitState();

  @override
  List<Object?> get props => [];
}

class HabitInitial extends HabitState {
  const HabitInitial();
}

class HabitLoading extends HabitState {
  final String? message;

  const HabitLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class HabitLoaded extends HabitState {
  final List<HabitModel> habits;
  final List<HabitInstanceModel> todayInstances;
  final DateTime selectedDate;
  final HabitFilter? activeFilter;
  final HabitStatistics? statistics;
  final DateTime lastUpdated;

  const HabitLoaded({
    required this.habits,
    required this.todayInstances,
    required this.selectedDate,
    this.activeFilter,
    this.statistics,
    required this.lastUpdated,
  });

  // Runtime constructor
  HabitLoaded.create({
    required this.habits,
    required this.todayInstances,
    required this.selectedDate,
    this.activeFilter,
    this.statistics,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  @override
  List<Object?> get props => [
    habits.length,
    _generateHabitsSignature(),
    todayInstances.length,
    _generateInstancesSignature(),
    selectedDate,
    activeFilter,
    statistics,
    lastUpdated.millisecondsSinceEpoch ~/ 1000,
  ];

  @override
  int get hashCode => Object.hash(
    habits.length,
    _generateHabitsSignature(),
    todayInstances.length,
    selectedDate,
    activeFilter,
    statistics,
    lastUpdated.millisecondsSinceEpoch ~/ 1000,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HabitLoaded &&
        habits.length == other.habits.length &&
        todayInstances.length == other.todayInstances.length &&
        selectedDate == other.selectedDate &&
        activeFilter == other.activeFilter &&
        _habitsContentEqual(other.habits) &&
        _instancesContentEqual(other.todayInstances) &&
        ((lastUpdated.difference(other.lastUpdated).abs().inSeconds) < 2);
  }

  // Computed properties
  List<HabitModel> get activeHabits =>
      _filterHabits(predicate: (habit) => habit.isActive);

  List<HabitModel> get inactiveHabits =>
      _filterHabits(predicate: (habit) => !habit.isActive);

  List<HabitInstanceModel> get completedToday =>
      _filterInstances(predicate: (instance) => instance.isCompleted);

  List<HabitInstanceModel> get pendingToday =>
      _filterInstances(predicate: (instance) => instance.isPending);

  // Optimized filter helpers
  List<HabitModel> _filterHabits({
    required bool Function(HabitModel) predicate,
  }) {
    final result = <HabitModel>[];
    for (final habit in habits) {
      if (predicate(habit)) {
        result.add(habit);
      }
    }
    return result;
  }

  List<HabitInstanceModel> _filterInstances({
    required bool Function(HabitInstanceModel) predicate,
  }) {
    final result = <HabitInstanceModel>[];
    for (final instance in todayInstances) {
      if (predicate(instance)) {
        result.add(instance);
      }
    }
    return result;
  }

  double get todayCompletionRate {
    if (todayInstances.isEmpty) return 0.0;
    return completedToday.length / todayInstances.length;
  }

  Map<String, List<HabitModel>> get habitsByFrequency {
    final Map<String, List<HabitModel>> grouped = {};
    for (final habit in activeHabits) {
      final key = habit.frequency.name;
      grouped.putIfAbsent(key, () => []).add(habit);
    }
    return grouped;
  }

  Map<String, List<HabitModel>> get habitsByTag {
    final Map<String, List<HabitModel>> grouped = {};
    for (final habit in activeHabits) {
      for (final tag in habit.tags) {
        grouped.putIfAbsent(tag, () => []).add(habit);
      }
    }
    return grouped;
  }

  // Helper methods
  HabitInstanceModel? getInstanceForHabit(String habitId) {
    try {
      return todayInstances.firstWhere(
        (instance) => instance.habitId == habitId,
      );
    } catch (_) {
      return null;
    }
  }

  List<HabitModel> getFilteredHabits([HabitFilter? filter]) {
    final f = filter ?? activeFilter;
    if (f == null) return habits;

    var filtered = habits.where((habit) => !habit.isDeleted).toList();

    // Apply filters
    if (f.frequencies != null && f.frequencies!.isNotEmpty) {
      filtered =
          filtered.where((h) => f.frequencies!.contains(h.frequency)).toList();
    }

    if (f.types != null && f.types!.isNotEmpty) {
      filtered = filtered.where((h) => f.types!.contains(h.habitType)).toList();
    }

    if (f.isActive != null) {
      filtered = filtered.where((h) => h.isActive == f.isActive).toList();
    }

    if (f.tags != null && f.tags!.isNotEmpty) {
      filtered =
          filtered
              .where((h) => h.tags.any((tag) => f.tags!.contains(tag)))
              .toList();
    }

    if (f.searchQuery?.isNotEmpty == true) {
      final query = f.searchQuery!.toLowerCase();
      filtered =
          filtered
              .where(
                (h) =>
                    h.title.toLowerCase().contains(query) ||
                    (h.description?.toLowerCase().contains(query) ?? false) ||
                    h.tags.any((tag) => tag.toLowerCase().contains(query)),
              )
              .toList();
    }

    // Apply sorting
    filtered = _sortHabits(filtered, f.sortBy, f.sortAscending);

    return filtered;
  }

  List<HabitModel> _sortHabits(
    List<HabitModel> habits,
    HabitSortOption sortBy,
    bool ascending,
  ) {
    final sorted = List<HabitModel>.from(habits);

    switch (sortBy) {
      case HabitSortOption.createdDate:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case HabitSortOption.title:
        sorted.sort((a, b) => a.title.compareTo(b.title));
        break;
      case HabitSortOption.frequency:
        sorted.sort((a, b) => a.frequency.index.compareTo(b.frequency.index));
        break;
      case HabitSortOption.streak:
        sorted.sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
        break;
      case HabitSortOption.completionRate:
        sorted.sort((a, b) => b.totalCompletions.compareTo(a.totalCompletions));
        break;
    }

    return ascending ? sorted : sorted.reversed.toList();
  }

  HabitLoaded copyWith({
    List<HabitModel>? habits,
    List<HabitInstanceModel>? todayInstances,
    DateTime? selectedDate,
    HabitFilter? activeFilter,
    HabitStatistics? statistics,
    DateTime? lastUpdated,
  }) {
    return HabitLoaded(
      habits: habits ?? this.habits,
      todayInstances: todayInstances ?? this.todayInstances,
      selectedDate: selectedDate ?? this.selectedDate,
      activeFilter: activeFilter ?? this.activeFilter,
      statistics: statistics ?? this.statistics,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Generate efficient signature for habits content
  String _generateHabitsSignature() {
    if (habits.isEmpty) return 'empty';

    final buffer = StringBuffer();
    for (final habit in habits) {
      buffer.write('${habit.id}_${habit.isActive}_${habit.currentStreak}');
      if (buffer.length > 200) break;
    }
    return buffer.toString();
  }

  // Generate efficient signature for instances content
  String _generateInstancesSignature() {
    if (todayInstances.isEmpty) return 'empty';

    final buffer = StringBuffer();
    for (final instance in todayInstances) {
      buffer.write('${instance.id}_${instance.status.name}');
      if (buffer.length > 200) break;
    }
    return buffer.toString();
  }

  // Efficient habit content comparison
  bool _habitsContentEqual(List<HabitModel> otherHabits) {
    if (habits.length != otherHabits.length) return false;

    for (int i = 0; i < habits.length; i++) {
      final a = habits[i];
      final b = otherHabits[i];
      if (a.id != b.id ||
          a.isActive != b.isActive ||
          a.title != b.title ||
          a.currentStreak != b.currentStreak) {
        return false;
      }
    }
    return true;
  }

  // Efficient instance content comparison
  bool _instancesContentEqual(List<HabitInstanceModel> otherInstances) {
    if (todayInstances.length != otherInstances.length) return false;

    for (int i = 0; i < todayInstances.length; i++) {
      final a = todayInstances[i];
      final b = otherInstances[i];
      if (a.id != b.id || a.status != b.status || a.habitId != b.habitId) {
        return false;
      }
    }
    return true;
  }
}

class HabitError extends HabitState {
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;

  const HabitError(this.message, {this.error, this.stackTrace});

  @override
  List<Object?> get props => [message, error, stackTrace];
}

class HabitOperationSuccess extends HabitState {
  final String message;
  final HabitOperation operation;
  final HabitModel? habit;

  const HabitOperationSuccess({
    required this.message,
    required this.operation,
    this.habit,
  });

  @override
  List<Object?> get props => [message, operation, habit];
}

enum HabitOperation { add, update, delete, complete, skip }

class HabitStatistics {
  final int totalHabits;
  final int activeHabits;
  final int completedToday;
  final int pendingToday;
  final double todayCompletionRate;
  final double averageStreak;
  final int longestStreak;
  final Map<HabitFrequency, int> habitsByFrequency;
  final Map<String, int> habitsByTag;

  const HabitStatistics({
    required this.totalHabits,
    required this.activeHabits,
    required this.completedToday,
    required this.pendingToday,
    required this.todayCompletionRate,
    required this.averageStreak,
    required this.longestStreak,
    required this.habitsByFrequency,
    required this.habitsByTag,
  });

  factory HabitStatistics.fromHabits(
    List<HabitModel> habits,
    List<HabitInstanceModel> todayInstances,
  ) {
    final activeHabits = habits.where((h) => h.isActive).toList();
    final completed = todayInstances.where((i) => i.isCompleted).length;
    final pending = todayInstances.where((i) => i.isPending).length;

    // Calculate average streak
    double avgStreak = 0;
    int maxStreak = 0;
    if (activeHabits.isNotEmpty) {
      final totalStreak = activeHabits.fold(
        0,
        (sum, habit) => sum + habit.currentStreak,
      );
      avgStreak = totalStreak / activeHabits.length;
      maxStreak = activeHabits
          .map((h) => h.longestStreak)
          .reduce((a, b) => a > b ? a : b);
    }

    // Group by frequency
    final byFrequency = <HabitFrequency, int>{};
    for (final habit in activeHabits) {
      byFrequency[habit.frequency] = (byFrequency[habit.frequency] ?? 0) + 1;
    }

    // Group by tag
    final byTag = <String, int>{};
    for (final habit in activeHabits) {
      for (final tag in habit.tags) {
        byTag[tag] = (byTag[tag] ?? 0) + 1;
      }
    }

    return HabitStatistics(
      totalHabits: habits.length,
      activeHabits: activeHabits.length,
      completedToday: completed,
      pendingToday: pending,
      todayCompletionRate:
          todayInstances.isEmpty ? 0 : completed / todayInstances.length,
      averageStreak: avgStreak,
      longestStreak: maxStreak,
      habitsByFrequency: byFrequency,
      habitsByTag: byTag,
    );
  }
}
