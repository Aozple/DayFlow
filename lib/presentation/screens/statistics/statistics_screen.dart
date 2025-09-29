import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/presentation/blocs/habits/habit_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
import 'package:dayflow/presentation/widgets/status_bar_padding.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'widgets/statistics_header.dart';
import 'widgets/quick_stats_cards.dart';
import 'widgets/activity_heatmap.dart';
import 'widgets/productivity_chart.dart';
import 'widgets/habits_breakdown.dart';
import 'widgets/tasks_breakdown.dart';
import 'widgets/insights_section.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _loadData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() => _isLoading = true);

    context.read<TaskBloc>().add(const LoadTasks(forceRefresh: true));
    context.read<HabitBloc>().add(const LoadHabits(forceRefresh: true));

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _onDateRangeChanged(DateTime start, DateTime end) {
    setState(() {
      _startDate = start;
      _endDate = end;
    });
    HapticFeedback.lightImpact();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const StatusBarPadding(),
          StatisticsHeader(
            startDate: _startDate,
            endDate: _endDate,
            onDateRangeChanged: _onDateRangeChanged,
            onBackPressed: () {
              HapticFeedback.lightImpact();
              context.pop();
            },
          ),
          Expanded(child: _isLoading ? _buildLoadingState() : _buildContent()),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CupertinoActivityIndicator(radius: 20),
          SizedBox(height: 16),
          Text(
            'Analyzing your data...',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, taskState) {
        return BlocBuilder<HabitBloc, HabitState>(
          builder: (context, habitState) {
            if (taskState is! TaskLoaded || habitState is! HabitLoaded) {
              return _buildEmptyState();
            }

            return FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: () async => _loadData(),
                color: AppColors.accent,
                backgroundColor: AppColors.surface,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          QuickStatsCards(
                            taskState: taskState,
                            habitState: habitState,
                            dateRange: (_startDate, _endDate),
                          ),
                          const SizedBox(height: 24),
                          ActivityHeatmap(
                            taskState: taskState,
                            habitState: habitState,
                            dateRange: (_startDate, _endDate),
                          ),
                          const SizedBox(height: 24),
                          ProductivityChart(
                            taskState: taskState,
                            habitState: habitState,
                            dateRange: (_startDate, _endDate),
                          ),
                          const SizedBox(height: 24),
                          HabitsBreakdown(
                            habitState: habitState,
                            dateRange: (_startDate, _endDate),
                          ),
                          const SizedBox(height: 24),
                          TasksBreakdown(
                            taskState: taskState,
                            dateRange: (_startDate, _endDate),
                          ),
                          const SizedBox(height: 24),
                          InsightsSection(
                            taskState: taskState,
                            habitState: habitState,
                            dateRange: (_startDate, _endDate),
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.chart_bar,
              size: 48,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No data available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start tracking your tasks and habits',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
