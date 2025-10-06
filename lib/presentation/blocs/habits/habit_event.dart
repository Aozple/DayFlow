part of 'habit_bloc.dart';

abstract class HabitEvent extends Equatable {
  const HabitEvent();

  @override
  List<Object?> get props => [];
}

class LoadHabits extends HabitEvent {
  final bool forceRefresh;

  const LoadHabits({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class LoadHabitInstances extends HabitEvent {
  final DateTime date;

  const LoadHabitInstances(this.date);

  @override
  List<Object?> get props => [date];
}

class LoadHabitDetails extends HabitEvent {
  final String habitId;

  const LoadHabitDetails(this.habitId);

  @override
  List<Object?> get props => [habitId];
}

class AddHabit extends HabitEvent {
  final HabitModel habit;

  const AddHabit(this.habit);

  @override
  List<Object?> get props => [habit];
}

class UpdateHabit extends HabitEvent {
  final HabitModel habit;
  final bool regenerateInstances;

  const UpdateHabit(this.habit, {this.regenerateInstances = true});

  @override
  List<Object?> get props => [habit, regenerateInstances];
}

class DeleteHabit extends HabitEvent {
  final String habitId;

  const DeleteHabit(this.habitId);

  @override
  List<Object?> get props => [habitId];
}

class CompleteHabitInstance extends HabitEvent {
  final String instanceId;
  final int? value;

  const CompleteHabitInstance(this.instanceId, {this.value});

  @override
  List<Object?> get props => [instanceId, value];
}

class UncompleteHabitInstance extends HabitEvent {
  final String instanceId;

  const UncompleteHabitInstance(this.instanceId);

  @override
  List<Object?> get props => [instanceId];
}

class UpdateHabitInstance extends HabitEvent {
  final HabitInstanceModel instance;

  const UpdateHabitInstance(this.instance);

  @override
  List<Object?> get props => [instance];
}

class GenerateHabitInstances extends HabitEvent {
  final String habitId;
  final int daysAhead;

  const GenerateHabitInstances(
    this.habitId, {
    this.daysAhead = AppConstants.defaultDaysAhead,
  });

  @override
  List<Object?> get props => [habitId, daysAhead];
}

class CompleteAllTodayInstances extends HabitEvent {
  const CompleteAllTodayInstances();
}

class FilterHabits extends HabitEvent {
  final HabitFilter filter;

  const FilterHabits(this.filter);

  @override
  List<Object?> get props => [filter];
}

class SearchHabits extends HabitEvent {
  final String query;

  const SearchHabits(this.query);

  @override
  List<Object?> get props => [query];
}

class ClearError extends HabitEvent {
  const ClearError();
}

class ExportHabits extends HabitEvent {
  final String format;

  const ExportHabits({this.format = 'json'});

  @override
  List<Object?> get props => [format];
}

class HabitFilter extends Equatable {
  final List<HabitFrequency>? frequencies;
  final List<HabitType>? types;
  final bool? isActive;
  final List<String>? tags;
  final String? searchQuery;
  final HabitSortOption sortBy;
  final bool sortAscending;

  const HabitFilter({
    this.frequencies,
    this.types,
    this.isActive,
    this.tags,
    this.searchQuery,
    this.sortBy = HabitSortOption.createdDate,
    this.sortAscending = false,
  });

  @override
  List<Object?> get props => [
    frequencies,
    types,
    isActive,
    tags,
    searchQuery,
    sortBy,
    sortAscending,
  ];

  HabitFilter copyWith({
    List<HabitFrequency>? frequencies,
    List<HabitType>? types,
    bool? isActive,
    List<String>? tags,
    String? searchQuery,
    HabitSortOption? sortBy,
    bool? sortAscending,
  }) {
    return HabitFilter(
      frequencies: frequencies ?? this.frequencies,
      types: types ?? this.types,
      isActive: isActive ?? this.isActive,
      tags: tags ?? this.tags,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  bool get hasActiveFilters {
    return frequencies != null ||
        types != null ||
        isActive != null ||
        tags != null ||
        (searchQuery != null && searchQuery!.isNotEmpty);
  }
}

enum HabitSortOption { createdDate, title, frequency, streak, completionRate }
