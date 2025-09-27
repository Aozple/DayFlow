import 'package:dayflow/core/services/notifications/notification_service.dart';
import 'package:dayflow/data/models/habit_instance_model.dart';
import 'package:dayflow/data/models/habit_model.dart';
import 'package:dayflow/data/repositories/habit_repository.dart';
import 'package:dayflow/presentation/blocs/base/base_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

part 'habit_event.dart';
part 'habit_state.dart';

class HabitBloc extends BaseBloc<HabitEvent, HabitState> {
  final HabitRepository _repository = GetIt.I<HabitRepository>();
  final NotificationService _notificationService =
      GetIt.I<NotificationService>();

  HabitBloc() : super(tag: 'HabitBloc', initialState: const HabitInitial()) {
    on<LoadHabits>(_onLoadHabits);
    on<LoadHabitInstances>(_onLoadHabitInstances);
    on<LoadHabitDetails>(_onLoadHabitDetails);
    on<AddHabit>(_onAddHabit);
    on<UpdateHabit>(_onUpdateHabit);
    on<DeleteHabit>(_onDeleteHabit);
    on<CompleteHabitInstance>(_onCompleteHabitInstance);
    on<UncompleteHabitInstance>(_onUncompleteHabitInstance);
    on<UpdateHabitInstance>(_onUpdateHabitInstance);
    on<GenerateHabitInstances>(_onGenerateHabitInstances);
    on<CompleteAllTodayInstances>(_onCompleteAllTodayInstances);
    on<FilterHabits>(_onFilterHabits);
    on<SearchHabits>(_onSearchHabits);
    on<ClearError>(_onClearError);
  }

  Future<HabitLoaded> _refreshHabitsState({DateTime? selectedDate}) async {
    final habits = _repository.getAllHabits();
    final currentState = state is HabitLoaded ? state as HabitLoaded : null;
    final date = selectedDate ?? currentState?.selectedDate ?? DateTime.now();
    final instances = _repository.getInstancesByDate(date);
    final statistics = HabitStatistics.fromHabits(habits, instances);

    return HabitLoaded(
      habits: habits,
      todayInstances: instances,
      selectedDate: date,
      statistics: statistics,
    );
  }

  Future<void> _onLoadHabits(LoadHabits event, Emitter<HabitState> emit) async {
    if (!canProcess(forceRefresh: event.forceRefresh)) return;

    await performOperation(
      operationName: 'Load Habits',
      operation: () async {
        final habits = _repository.getAllHabits();
        final todayInstances = _repository.getInstancesByDate(DateTime.now());
        final statistics = HabitStatistics.fromHabits(habits, todayInstances);

        return HabitLoaded(
          habits: habits,
          todayInstances: todayInstances,
          selectedDate: DateTime.now(),
          statistics: statistics,
        );
      },
      emit: emit,
      loadingState: state is! HabitLoaded ? const HabitLoading() : null,
      successState: (result) => result,
      errorState: (error) => HabitError(error),
      fallbackState:
          state is HabitLoaded
              ? state
              : HabitLoaded(
                habits: const [],
                todayInstances: const [],
                selectedDate: DateTime.now(),
              ),
    );
  }

  Future<void> _onLoadHabitInstances(
    LoadHabitInstances event,
    Emitter<HabitState> emit,
  ) async {
    await performOperation(
      operationName: 'Load Instances',
      operation: () async {
        final habits = _repository.getAllHabits();
        final instances = _repository.getInstancesByDate(event.date);
        final statistics = HabitStatistics.fromHabits(habits, instances);

        return HabitLoaded(
          habits: habits,
          todayInstances: instances,
          selectedDate: event.date,
          statistics: statistics,
        );
      },
      emit: emit,
      successState: (result) => result,
      checkProcessing: false,
    );
  }

  Future<void> _onLoadHabitDetails(
    LoadHabitDetails event,
    Emitter<HabitState> emit,
  ) async {
    await performOperation(
      operationName: 'Load Habit Details',
      operation: () async {
        final habit = _repository.getHabit(event.habitId);
        if (habit == null) {
          throw Exception('Habit not found');
        }

        final instances = _repository.getInstancesByHabitId(event.habitId);

        return {'habit': habit, 'instances': instances};
      },
      emit: emit,
      successState: (result) {
        // Details loaded successfully, but keep current state
        // Just log the success - this event is for loading data, not changing state
        logSuccess(
          'Details loaded',
          data: '${(result['instances'] as List).length} instances',
        );
        return state;
      },
      errorState: (error) => const HabitError('Failed to load habit details'),
    );
  }

  Future<void> _onAddHabit(AddHabit event, Emitter<HabitState> emit) async {
    await performOperation(
      operationName: 'Add Habit',
      operation: () async {
        await _repository.addHabit(event.habit);

        if (event.habit.hasNotification && event.habit.preferredTime != null) {
          await _notificationService.scheduleHabitNotification(event.habit);
        }

        return await _refreshHabitsState();
      },
      emit: emit,
      successState: (result) => result,
      errorState: (error) => const HabitError('Failed to add habit'),
    );
  }

  Future<void> _onUpdateHabit(
    UpdateHabit event,
    Emitter<HabitState> emit,
  ) async {
    await performOperation(
      operationName: 'Update Habit',
      operation: () async {
        await _repository.updateHabit(event.habit);

        if (event.habit.hasNotification && event.habit.preferredTime != null) {
          await _notificationService.scheduleHabitNotification(event.habit);
        } else {
          await _notificationService.cancelHabitNotification(event.habit.id);
        }

        return await _refreshHabitsState();
      },
      emit: emit,
      successState: (result) => result,
      errorState: (error) => const HabitError('Failed to update habit'),
    );
  }

  Future<void> _onDeleteHabit(
    DeleteHabit event,
    Emitter<HabitState> emit,
  ) async {
    await performOperation(
      operationName: 'Delete Habit',
      operation: () async {
        await _repository.deleteHabit(event.habitId);
        await _notificationService.cancelHabitNotification(event.habitId);

        if (state is HabitLoaded) {
          final currentState = state as HabitLoaded;
          final habits = _repository.getAllHabits();
          final instances = _repository.getInstancesByDate(
            currentState.selectedDate,
          );

          return HabitLoaded(
            habits: habits,
            todayInstances: instances,
            selectedDate: currentState.selectedDate,
          );
        }

        return null;
      },
      emit: emit,
      successState: (result) => result ?? state,
      errorState: (error) => const HabitError('Failed to delete habit'),
      checkProcessing: false,
    );

    if (state is! HabitLoaded) {
      add(const LoadHabits());
    }
  }

  Future<void> _onCompleteHabitInstance(
    CompleteHabitInstance event,
    Emitter<HabitState> emit,
  ) async {
    await performOperation(
      operationName: 'Complete Instance',
      operation: () async {
        await _repository.completeInstance(
          event.instanceId,
          value: event.value,
        );

        if (state is HabitLoaded) {
          final currentState = state as HabitLoaded;
          final habits = _repository.getAllHabits();
          final instances = _repository.getInstancesByDate(
            currentState.selectedDate,
          );
          final statistics = HabitStatistics.fromHabits(habits, instances);

          return HabitLoaded(
            habits: habits,
            todayInstances: instances,
            selectedDate: currentState.selectedDate,
            statistics: statistics,
          );
        }

        return null;
      },
      emit: emit,
      successState: (result) => result ?? state,
      errorState: (error) => const HabitError('Failed to complete habit'),
      checkProcessing: false,
    );

    if (state is! HabitLoaded) {
      add(const LoadHabits());
    }
  }

  Future<void> _onUncompleteHabitInstance(
    UncompleteHabitInstance event,
    Emitter<HabitState> emit,
  ) async {
    await performOperation(
      operationName: 'Uncomplete Instance',
      operation: () async {
        final instance = _repository.getInstance(event.instanceId);
        if (instance != null) {
          final updatedInstance = instance.copyWith(
            status: HabitInstanceStatus.pending,
            completedAt: null,
            value: null,
          );
          await _repository.updateInstance(updatedInstance);
        }

        return await _refreshHabitsState();
      },
      emit: emit,
      successState: (result) => result,
      errorState: (error) => const HabitError('Failed to uncomplete habit'),
    );
  }

  Future<void> _onUpdateHabitInstance(
    UpdateHabitInstance event,
    Emitter<HabitState> emit,
  ) async {
    await performOperation(
      operationName: 'Update Instance',
      operation: () async {
        await _repository.updateInstance(event.instance);
        return true;
      },
      emit: emit,
      successState: (_) => state,
      errorState: (error) => const HabitError('Failed to update instance'),
      checkProcessing: false,
    );

    if (state is HabitLoaded) {
      final currentState = state as HabitLoaded;
      add(LoadHabitInstances(currentState.selectedDate));
    }
  }

  Future<void> _onGenerateHabitInstances(
    GenerateHabitInstances event,
    Emitter<HabitState> emit,
  ) async {
    await performOperation(
      operationName: 'Generate Instances',
      operation: () async {
        final habit = _repository.getHabit(event.habitId);
        if (habit != null) {
          await _repository.generateInstances(
            habit,
            daysAhead: event.daysAhead,
          );
        }
        return true;
      },
      emit: emit,
      successState: (_) => state,
      errorState: (error) => const HabitError('Failed to generate instances'),
    );

    add(const LoadHabits());
  }

  Future<void> _onCompleteAllTodayInstances(
    CompleteAllTodayInstances event,
    Emitter<HabitState> emit,
  ) async {
    await performOperation(
      operationName: 'Complete All Today',
      operation: () async {
        if (state is HabitLoaded) {
          final currentState = state as HabitLoaded;

          for (final instance in currentState.pendingToday) {
            await _repository.completeInstance(instance.id);
          }

          return true;
        }
        return false;
      },
      emit: emit,
      successState: (_) => state,
      errorState: (error) => const HabitError('Failed to complete all habits'),
    );

    if (state is HabitLoaded) {
      final currentState = state as HabitLoaded;
      add(LoadHabitInstances(currentState.selectedDate));
    }
  }

  Future<void> _onFilterHabits(
    FilterHabits event,
    Emitter<HabitState> emit,
  ) async {
    try {
      logInfo('Applying filter');

      if (state is HabitLoaded) {
        final currentState = state as HabitLoaded;
        emit(currentState.copyWith(activeFilter: event.filter));
      }
    } catch (e) {
      logError('Filter failed', error: e);
    }
  }

  Future<void> _onSearchHabits(
    SearchHabits event,
    Emitter<HabitState> emit,
  ) async {
    try {
      logInfo('Searching habits: "${event.query}"');

      if (state is HabitLoaded) {
        final currentState = state as HabitLoaded;

        // Create proper search filter
        final searchFilter =
            event.query.isNotEmpty
                ? HabitFilter(
                  // We can search in tags, but also should allow title/description search
                  tags:
                      currentState.habitsByTag.keys
                          .where(
                            (tag) => tag.toLowerCase().contains(
                              event.query.toLowerCase(),
                            ),
                          )
                          .toList(),
                )
                : null;

        emit(currentState.copyWith(activeFilter: searchFilter));

        logSuccess('Search filter applied');
      }
    } catch (e) {
      logError('Search failed', error: e);
    }
  }

  Future<void> _onClearError(ClearError event, Emitter<HabitState> emit) async {
    logInfo('Clearing error');
    add(const LoadHabits());
  }
}
