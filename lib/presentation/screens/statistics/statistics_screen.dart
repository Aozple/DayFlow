import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/habit_model.dart';
import 'package:dayflow/presentation/blocs/habits/habit_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'widgets/stats_header.dart';
import 'widgets/today_overview_card.dart';
import 'widgets/habit_heatmap_card.dart';
import 'widgets/insights_grid.dart';
import 'widgets/trends_card.dart';

class StatisticsScreen extends StatefulWidget {
  final HabitModel? selectedHabit;

  const StatisticsScreen({super.key, this.selectedHabit});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedPeriod = 'Month';
  HabitModel? _focusedHabit;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _focusedHabit = widget.selectedHabit;
    _loadData();
  }

  void _loadData() {
    setState(() => _isLoading = true);
    context.read<HabitBloc>().add(const LoadHabits(forceRefresh: true));
    context.read<TaskBloc>().add(const LoadTasks(forceRefresh: true));
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _changePeriod(String period) {
    setState(() => _selectedPeriod = period);
    HapticFeedback.lightImpact();
  }

  void _selectHabit(HabitModel? habit) {
    setState(() => _focusedHabit = habit);
    HapticFeedback.lightImpact();
  }

  void _onDateTapped(DateTime date) {
    setState(() => _selectedDate = date);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            StatsHeader(
              selectedPeriod: _selectedPeriod,
              focusedHabit: _focusedHabit,
              onBack: () => context.pop(),
              onPeriodChanged: _changePeriod,
              onHabitChanged: _selectHabit,
            ),
            Expanded(
              child: BlocBuilder<HabitBloc, HabitState>(
                builder: (context, habitState) {
                  return BlocBuilder<TaskBloc, TaskState>(
                    builder: (context, taskState) {
                      if (_isLoading) {
                        return _buildLoadingState();
                      }

                      if (habitState is HabitLoaded &&
                          taskState is TaskLoaded) {
                        return _buildContent(habitState, taskState);
                      }

                      return _buildErrorState();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.accent),
          const SizedBox(height: 16),
          const Text(
            'Loading statistics...',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(HabitLoaded habitState, TaskLoaded taskState) {
    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.lightImpact();
        _loadData();
      },
      color: AppColors.accent,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                TodayOverviewCard(
                  habitState: habitState,
                  taskState: taskState,
                  selectedDate: _selectedDate,
                  focusedHabit: _focusedHabit,
                ),
                const SizedBox(height: 16),
                HabitHeatmapCard(
                  habits: habitState.habits,
                  instances: habitState.todayInstances,
                  year: _selectedDate.year,
                  focusedHabit: _focusedHabit,
                  onDateTapped: _onDateTapped,
                ),
                const SizedBox(height: 16),
                InsightsGrid(
                  habitState: habitState,
                  period: _selectedPeriod,
                  focusedHabit: _focusedHabit,
                ),
                const SizedBox(height: 16),
                TrendsCard(
                  habitState: habitState,
                  taskState: taskState,
                  period: _selectedPeriod,
                  focusedHabit: _focusedHabit,
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 40,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Unable to load statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your connection and try again',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _loadData();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
