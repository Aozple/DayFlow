import 'package:dayflow/core/services/notification_service.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:dayflow/data/models/habit_instance_model.dart';
import 'package:dayflow/data/models/habit_model.dart';
import 'package:dayflow/data/repositories/habit_repository.dart';
import 'package:dayflow/data/repositories/settings_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'habit_event.dart';
part 'habit_state.dart';

class HabitBloc extends Bloc<HabitEvent, HabitState> {
  static const String _tag = 'HabitBloc';
  final HabitRepository _repository;

  // Prevent duplicate operations
  bool _isProcessing = false;
  DateTime? _lastLoadTime;
  static const Duration _minLoadInterval = Duration(milliseconds: 500);

  HabitBloc({required HabitRepository repository})
    : _repository = repository,
      super(const HabitInitial()) {
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

  Future<void> _onLoadHabits(LoadHabits event, Emitter<HabitState> emit) async {
    // Prevent rapid reloads
    if (_isProcessing && !event.forceRefresh) {
      DebugLogger.warning('Load already in progress, skipping', tag: _tag);
      return;
    }

    if (_lastLoadTime != null && !event.forceRefresh) {
      final timeSinceLastLoad = DateTime.now().difference(_lastLoadTime!);
      if (timeSinceLastLoad < _minLoadInterval) {
        DebugLogger.verbose(
          'Too soon to reload, using cached state',
          tag: _tag,
        );
        return;
      }
    }

    _isProcessing = true;

    try {
      DebugLogger.info('Loading all habits', tag: _tag);

      // Keep existing data while loading if we have it
      if (state is! HabitLoaded) {
        emit(const HabitLoading());
      }

      final habits = _repository.getAllHabits();
      final todayInstances = _repository.getInstancesByDate(DateTime.now());
      _lastLoadTime = DateTime.now();

      DebugLogger.success(
        'Habits loaded',
        tag: _tag,
        data:
            '${habits.length} habits, ${todayInstances.length} instances today',
      );

      // Calculate statistics
      final statistics = HabitStatistics.fromHabits(habits, todayInstances);

      emit(
        HabitLoaded(
          habits: habits,
          todayInstances: todayInstances,
          selectedDate: DateTime.now(),
          statistics: statistics,
        ),
      );
    } catch (e) {
      DebugLogger.error('Failed to load habits', tag: _tag, error: e);

      // Try to maintain existing data
      if (state is HabitLoaded) {
        final currentState = state as HabitLoaded;
        emit(HabitError(e.toString()));
        await Future.delayed(const Duration(seconds: 1));
        emit(currentState);
      } else {
        emit(HabitError(e.toString()));
        await Future.delayed(const Duration(seconds: 1));
        emit(
          HabitLoaded(
            habits: const [],
            todayInstances: const [],
            selectedDate: DateTime.now(),
          ),
        );
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _onLoadHabitInstances(
    LoadHabitInstances event,
    Emitter<HabitState> emit,
  ) async {
    try {
      DebugLogger.info(
        'Loading habit instances',
        tag: _tag,
        data: event.date.toString().split(' ')[0],
      );

      final habits = _repository.getAllHabits();
      final instances = _repository.getInstancesByDate(event.date);

      DebugLogger.success(
        'Instances loaded',
        tag: _tag,
        data: '${instances.length} instances for selected date',
      );

      final statistics = HabitStatistics.fromHabits(habits, instances);

      emit(
        HabitLoaded(
          habits: habits,
          todayInstances: instances,
          selectedDate: event.date,
          statistics: statistics,
        ),
      );
    } catch (e) {
      DebugLogger.error('Failed to load instances', tag: _tag, error: e);

      if (state is HabitLoaded) {
        final currentState = state as HabitLoaded;
        emit(
          HabitLoaded(
            habits: currentState.habits,
            todayInstances: const [],
            selectedDate: event.date,
          ),
        );
      }
    }
  }

  Future<void> _onLoadHabitDetails(
    LoadHabitDetails event,
    Emitter<HabitState> emit,
  ) async {
    try {
      DebugLogger.info('Loading habit details', tag: _tag, data: event.habitId);

      final habit = _repository.getHabit(event.habitId);
      if (habit == null) {
        throw Exception('Habit not found');
      }

      final instances = _repository.getInstancesByHabitId(event.habitId);

      DebugLogger.success(
        'Habit details loaded',
        tag: _tag,
        data: '${instances.length} instances found',
      );

      // Emit success state with habit details
      // You might want to create a separate state for this
    } catch (e) {
      DebugLogger.error('Failed to load habit details', tag: _tag, error: e);
      emit(HabitError('Failed to load habit details: ${e.toString()}'));
    }
  }

  Future<void> _onAddHabit(AddHabit event, Emitter<HabitState> emit) async {
    if (_isProcessing) {
      DebugLogger.warning('Operation in progress, skipping add', tag: _tag);
      return;
    }

    _isProcessing = true;

    try {
      DebugLogger.info('Adding new habit', tag: _tag, data: event.habit.title);

      // Save habit
      await _repository.addHabit(event.habit);

      // Handle notifications
      if (event.habit.hasNotification && event.habit.preferredTime != null) {
        await _scheduleNotification(event.habit);
      }

      // Reload habits
      add(const LoadHabits());

      DebugLogger.success('Habit added successfully', tag: _tag);
    } catch (e) {
      DebugLogger.error('Failed to add habit', tag: _tag, error: e);
      emit(HabitError('Failed to add habit: ${e.toString()}'));

      // Auto-recover
      await Future.delayed(const Duration(seconds: 2));
      add(const LoadHabits());
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _onUpdateHabit(
    UpdateHabit event,
    Emitter<HabitState> emit,
  ) async {
    if (_isProcessing) {
      DebugLogger.warning('Operation in progress, skipping update', tag: _tag);
      return;
    }

    _isProcessing = true;

    try {
      DebugLogger.info('Updating habit', tag: _tag, data: event.habit.title);

      await _repository.updateHabit(event.habit);

      // Handle notifications
      await _handleNotificationUpdate(event.habit);

      add(const LoadHabits());

      DebugLogger.success('Habit updated successfully', tag: _tag);
    } catch (e) {
      DebugLogger.error('Failed to update habit', tag: _tag, error: e);
      emit(HabitError('Failed to update habit: ${e.toString()}'));

      // Auto-recover
      await Future.delayed(const Duration(seconds: 2));
      add(const LoadHabits());
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _onDeleteHabit(
    DeleteHabit event,
    Emitter<HabitState> emit,
  ) async {
    try {
      DebugLogger.info('Deleting habit', tag: _tag, data: event.habitId);

      await _repository.deleteHabit(event.habitId);

      // Cancel notifications
      final notificationService = NotificationService();
      if (notificationService.isInitialized) {
        await notificationService.cancelTaskNotifications(event.habitId);
      }

      // Quick update
      if (state is HabitLoaded) {
        final currentState = state as HabitLoaded;
        final habits = _repository.getAllHabits();
        final instances = _repository.getInstancesByDate(
          currentState.selectedDate,
        );
        emit(
          HabitLoaded(
            habits: habits,
            todayInstances: instances,
            selectedDate: currentState.selectedDate,
          ),
        );
      } else {
        add(const LoadHabits());
      }

      DebugLogger.success('Habit deleted successfully', tag: _tag);
    } catch (e) {
      DebugLogger.error('Failed to delete habit', tag: _tag, error: e);
      emit(HabitError('Failed to delete habit: ${e.toString()}'));
    }
  }

  Future<void> _onCompleteHabitInstance(
    CompleteHabitInstance event,
    Emitter<HabitState> emit,
  ) async {
    try {
      DebugLogger.info(
        'Completing habit instance',
        tag: _tag,
        data: event.instanceId,
      );

      await _repository.completeInstance(event.instanceId, value: event.value);

      // Quick update without full reload
      if (state is HabitLoaded) {
        final currentState = state as HabitLoaded;
        final habits = _repository.getAllHabits();
        final instances = _repository.getInstancesByDate(
          currentState.selectedDate,
        );
        final statistics = HabitStatistics.fromHabits(habits, instances);

        emit(
          HabitLoaded(
            habits: habits,
            todayInstances: instances,
            selectedDate: currentState.selectedDate,
            statistics: statistics,
          ),
        );
      } else {
        add(const LoadHabits());
      }

      DebugLogger.success('Instance completed successfully', tag: _tag);
    } catch (e) {
      DebugLogger.error('Failed to complete instance', tag: _tag, error: e);
      emit(HabitError('Failed to complete habit: ${e.toString()}'));
    }
  }

  Future<void> _onUncompleteHabitInstance(
    UncompleteHabitInstance event,
    Emitter<HabitState> emit,
  ) async {
    try {
      DebugLogger.info(
        'Uncompleting habit instance',
        tag: _tag,
        data: event.instanceId,
      );

      final instance = _repository.getInstance(event.instanceId);
      if (instance != null) {
        final updatedInstance = instance.copyWith(
          status: HabitInstanceStatus.pending,
          completedAt: null,
          value: null,
        );
        await _repository.updateInstance(updatedInstance);
      }

      // Quick update
      if (state is HabitLoaded) {
        final currentState = state as HabitLoaded;
        final habits = _repository.getAllHabits();
        final instances = _repository.getInstancesByDate(
          currentState.selectedDate,
        );
        emit(
          HabitLoaded(
            habits: habits,
            todayInstances: instances,
            selectedDate: currentState.selectedDate,
          ),
        );
      }

      DebugLogger.success('Instance uncompleted successfully', tag: _tag);
    } catch (e) {
      DebugLogger.error('Failed to uncomplete instance', tag: _tag, error: e);
      emit(HabitError('Failed to uncomplete habit: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateHabitInstance(
    UpdateHabitInstance event,
    Emitter<HabitState> emit,
  ) async {
    try {
      DebugLogger.info('Updating habit instance', tag: _tag);

      await _repository.updateInstance(event.instance);

      // Reload current state
      if (state is HabitLoaded) {
        final currentState = state as HabitLoaded;
        add(LoadHabitInstances(currentState.selectedDate));
      }

      DebugLogger.success('Instance updated successfully', tag: _tag);
    } catch (e) {
      DebugLogger.error('Failed to update instance', tag: _tag, error: e);
      emit(HabitError('Failed to update instance: ${e.toString()}'));
    }
  }

  Future<void> _onGenerateHabitInstances(
    GenerateHabitInstances event,
    Emitter<HabitState> emit,
  ) async {
    try {
      DebugLogger.info(
        'Generating habit instances',
        tag: _tag,
        data: 'Days ahead: ${event.daysAhead}',
      );

      final habit = _repository.getHabit(event.habitId);
      if (habit != null) {
        await _repository.generateInstances(habit, daysAhead: event.daysAhead);
      }

      // Reload
      add(const LoadHabits());

      DebugLogger.success('Instances generated successfully', tag: _tag);
    } catch (e) {
      DebugLogger.error('Failed to generate instances', tag: _tag, error: e);
      emit(HabitError('Failed to generate instances: ${e.toString()}'));
    }
  }

  Future<void> _onCompleteAllTodayInstances(
    CompleteAllTodayInstances event,
    Emitter<HabitState> emit,
  ) async {
    try {
      DebugLogger.info('Completing all today instances', tag: _tag);

      if (state is HabitLoaded) {
        final currentState = state as HabitLoaded;

        for (final instance in currentState.pendingToday) {
          await _repository.completeInstance(instance.id);
        }

        // Reload
        add(LoadHabitInstances(currentState.selectedDate));
      }

      DebugLogger.success('All instances completed', tag: _tag);
    } catch (e) {
      DebugLogger.error(
        'Failed to complete all instances',
        tag: _tag,
        error: e,
      );
      emit(HabitError('Failed to complete all habits: ${e.toString()}'));
    }
  }

  Future<void> _onFilterHabits(
    FilterHabits event,
    Emitter<HabitState> emit,
  ) async {
    try {
      DebugLogger.info('Applying habit filters', tag: _tag);

      if (state is HabitLoaded) {
        final currentState = state as HabitLoaded;
        emit(currentState.copyWith(activeFilter: event.filter));
      }
    } catch (e) {
      DebugLogger.error('Failed to filter habits', tag: _tag, error: e);
    }
  }

  Future<void> _onSearchHabits(
    SearchHabits event,
    Emitter<HabitState> emit,
  ) async {
    try {
      DebugLogger.info('Searching habits', tag: _tag, data: event.query);

      if (state is HabitLoaded) {
        final currentState = state as HabitLoaded;
        final query = event.query.toLowerCase();

        final filteredHabits =
            currentState.habits.where((habit) {
              return habit.title.toLowerCase().contains(query) ||
                  (habit.description?.toLowerCase().contains(query) ?? false) ||
                  habit.tags.any((tag) => tag.toLowerCase().contains(query));
            }).toList();

        // Create a temporary filter to show search results
        final searchFilter = HabitFilter(
          tags: [event.query], // Use query as a tag filter for display
        );

        emit(
          currentState.copyWith(
            habits: filteredHabits,
            activeFilter: searchFilter,
          ),
        );
      }
    } catch (e) {
      DebugLogger.error('Failed to search habits', tag: _tag, error: e);
    }
  }

  Future<void> _onClearError(ClearError event, Emitter<HabitState> emit) async {
    DebugLogger.info('Clearing error state', tag: _tag);
    add(const LoadHabits());
  }

  // Helper methods
  Future<void> _scheduleNotification(HabitModel habit) async {
    try {
      DebugLogger.info('Scheduling notification', tag: _tag, data: habit.title);

      final settingsRepo = SettingsRepository();
      if (!settingsRepo.isInitialized) {
        await settingsRepo.init();
      }

      final settings = settingsRepo.getSettings();
      final notificationService = NotificationService();

      if (!notificationService.isInitialized) {
        await notificationService.initialize();
      }

      // Schedule recurring notification based on habit frequency
      await _scheduleRecurringNotification(
        habit,
        notificationService,
        settings,
      );

      DebugLogger.success('Notification scheduled', tag: _tag);
    } catch (e) {
      DebugLogger.error('Error scheduling notification', tag: _tag, error: e);
    }
  }

  Future<void> _scheduleRecurringNotification(
    HabitModel habit,
    NotificationService notificationService,
    dynamic settings,
  ) async {
    // This would be implemented based on your notification service capabilities
    // For now, we'll just log it
    DebugLogger.info(
      'Would schedule recurring notification',
      tag: _tag,
      data: {
        'habit': habit.title,
        'frequency': habit.frequency.name,
        'time': habit.preferredTime?.toString(),
      },
    );
  }

  Future<void> _handleNotificationUpdate(HabitModel habit) async {
    try {
      final notificationService = NotificationService();

      if (!notificationService.isInitialized) {
        await notificationService.initialize();
      }

      if (habit.hasNotification && habit.preferredTime != null) {
        DebugLogger.info('Updating notification', tag: _tag);

        final settingsRepo = SettingsRepository();
        if (!settingsRepo.isInitialized) {
          await settingsRepo.init();
        }

        await _scheduleRecurringNotification(
          habit,
          notificationService,
          settingsRepo.getSettings(),
        );
      } else {
        DebugLogger.info('Canceling notifications', tag: _tag);
        await notificationService.cancelTaskNotifications(habit.id);
      }
    } catch (e) {
      DebugLogger.error('Error handling notification', tag: _tag, error: e);
    }
  }

  @override
  Future<void> close() {
    DebugLogger.info('Closing HabitBloc', tag: _tag);
    return super.close();
  }
}
