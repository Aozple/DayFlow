import 'dart:async';
import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/core/constants/statistics_constants.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:dayflow/core/services/statistics/statistics_service.dart';
import 'package:dayflow/presentation/blocs/habits/habit_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
import 'package:dayflow/presentation/screens/statistics/widgets/statistics_achievements_card.dart';
import 'package:dayflow/presentation/screens/statistics/widgets/statistics_header.dart';
import 'package:dayflow/presentation/screens/statistics/widgets/statistics_heat_map.dart';
import 'package:dayflow/presentation/screens/statistics/widgets/statistics_insights_card.dart';
import 'package:dayflow/presentation/screens/statistics/widgets/statistics_overview_card.dart';
import 'package:dayflow/presentation/screens/statistics/widgets/statistics_quick_stats.dart';
import 'package:dayflow/presentation/widgets/status_bar_padding.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _cachedStatistics;
  Timer? _debounceTimer;

  int _selectedPeriod = 30;
  final List<int> _periods = [7, 30, 90];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  DateTime get _startDate =>
      DateTime.now().subtract(Duration(days: _selectedPeriod));
  DateTime get _endDate => DateTime.now();

  void _loadData() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _performDataLoad();
    });
  }

  Future<void> _performDataLoad() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      DebugLogger.info(
        'Loading statistics data',
        tag: StatisticsConstants.logTag,
        data: {
          'selectedPeriod': _selectedPeriod,
          'dateRange':
              '${_startDate.toString().split(' ')[0]} - ${_endDate.toString().split(' ')[0]}',
        },
      );

      context.read<TaskBloc>().add(const LoadTasks(forceRefresh: true));
      context.read<HabitBloc>().add(const LoadHabits(forceRefresh: true));

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() => _isLoading = false);
        DebugLogger.success(
          'Statistics data loaded',
          tag: StatisticsConstants.logTag,
        );
      }
    } catch (e, stackTrace) {
      DebugLogger.error(
        'Failed to load statistics data',
        tag: StatisticsConstants.logTag,
        error: e,
        stackTrace: stackTrace,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load data. Please try again.';
        });
      }
    }
  }

  Future<void> _refreshData() async {
    HapticFeedback.lightImpact();

    DebugLogger.info(
      'Manual refresh triggered',
      tag: StatisticsConstants.logTag,
      data: {
        'period': _selectedPeriod,
        'startDate': _startDate.toString().split(' ')[0],
        'endDate': _endDate.toString().split(' ')[0],
      },
    );

    setState(() => _cachedStatistics = null);
    await _performDataLoad();
  }

  void _onPeriodChanged(int period) {
    if (_selectedPeriod != period) {
      HapticFeedback.selectionClick();

      DebugLogger.info(
        'Period changed',
        tag: StatisticsConstants.logTag,
        data: {'from': _selectedPeriod, 'to': period},
      );

      setState(() {
        _selectedPeriod = period;
        _cachedStatistics = null;
      });

      _loadData();
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                child: const Text('Retry'),
                onPressed: () {
                  Navigator.pop(context);
                  _loadData();
                },
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const StatusBarPadding(),
          const StatisticsHeader(),
          _buildPeriodSelector(),
          Expanded(
            child:
                _errorMessage != null
                    ? _buildErrorState()
                    : _isLoading
                    ? _buildLoadingState()
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Row(
        children: [
          const Text(
            'Period:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _periods.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final period = _periods[index];
                  final isSelected = _selectedPeriod == period;

                  return GestureDetector(
                    onTap: () => _onPeriodChanged(period),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? Theme.of(context).colorScheme.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              isSelected ? Theme.of(context).colorScheme.primary : AppColors.divider,
                        ),
                      ),
                      child: Text(
                        _getPeriodLabel(period),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPeriodLabel(int days) {
    switch (days) {
      case 7:
        return 'Week';
      case 30:
        return 'Month';
      case 90:
        return '3 Months';
      default:
        return '$days Days';
    }
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
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Failed to load statistics',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _errorMessage = null);
                _loadData();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
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

            return FutureBuilder<Map<String, dynamic>>(
              future: _getOrCalculateStatistics(taskState, habitState),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                if (snapshot.hasError) {
                  DebugLogger.error(
                    'Statistics calculation failed',
                    tag: StatisticsConstants.logTag,
                    error: snapshot.error,
                  );

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _showErrorDialog('Failed to calculate statistics');
                    }
                  });

                  return _buildErrorState();
                }

                final statistics = snapshot.data;
                if (statistics == null) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: _refreshData,
                  color: Theme.of(context).colorScheme.primary,
                  backgroundColor: AppColors.surface,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 100),
                    children: [
                      const SizedBox(height: 16),
                      StatisticsQuickStats(overview: statistics['overview']),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            StatisticsOverviewCard(
                              overview: statistics['overview'],
                            ),
                            const SizedBox(height: 16),
                            StatisticsHeatMap(
                              heatMapData: statistics['heatMapData'],
                            ),
                            const SizedBox(height: 16),
                            StatisticsAchievementsCard(
                              achievements: statistics['achievements'],
                            ),
                            const SizedBox(height: 16),
                            StatisticsInsightsCard(
                              insights: statistics['insights'],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getOrCalculateStatistics(
    TaskLoaded taskState,
    HabitLoaded habitState,
  ) async {
    if (_cachedStatistics != null) {
      DebugLogger.verbose(
        'Using cached statistics',
        tag: StatisticsConstants.logTag,
      );
      return _cachedStatistics!;
    }

    final statistics = await StatisticsService.calculateStatistics(
      taskState: taskState,
      habitState: habitState,
      startDate: _startDate,
      endDate: _endDate,
    );

    _cachedStatistics = statistics;

    DebugLogger.success(
      'Statistics calculated and cached',
      tag: StatisticsConstants.logTag,
      data: {'period': _selectedPeriod, 'components': statistics.keys.toList()},
    );

    return statistics;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
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
              'Start tracking your tasks and habits\nto see detailed statistics',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Start Tracking',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
