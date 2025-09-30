import 'package:dayflow/core/constants/statistics_constants.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:dayflow/core/services/statistics/overview_statistics_service.dart';
import 'package:dayflow/core/services/statistics/achievement_statistics_service.dart';
import 'package:dayflow/core/services/statistics/heat_map_statistics_service.dart';
import 'package:dayflow/core/services/statistics/insights_statistics_service.dart';
import 'package:dayflow/core/services/statistics/trends_statistics_service.dart';
import 'package:dayflow/presentation/blocs/habits/habit_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';

class StatisticsService {
  const StatisticsService._();

  static Future<Map<String, dynamic>> calculateStatistics({
    required TaskLoaded taskState,
    required HabitLoaded habitState,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await DebugLogger.timeOperation(
      'Statistics calculation',
      () async =>
          _performCalculations(taskState, habitState, startDate, endDate),
    );
  }

  static Future<Map<String, dynamic>> _performCalculations(
    TaskLoaded taskState,
    HabitLoaded habitState,
    DateTime startDate,
    DateTime endDate,
  ) async {
    DebugLogger.info(
      'Starting comprehensive statistics calculation',
      tag: StatisticsConstants.logTag,
      data: {
        'dateRange':
            '${startDate.toString().split(' ')[0]} - ${endDate.toString().split(' ')[0]}',
        'tasksCount': taskState.tasks.length,
        'habitsCount': habitState.habits.length,
      },
    );

    try {
      final results = <String, dynamic>{};

      DebugLogger.debug(
        'Calculating overview...',
        tag: StatisticsConstants.logTag,
      );
      results['overview'] = OverviewStatisticsService.calculateOverview(
        taskState,
        habitState,
      );

      DebugLogger.debug(
        'Calculating achievements...',
        tag: StatisticsConstants.logTag,
      );
      results['achievements'] =
          AchievementStatisticsService.calculateAchievements(
            taskState,
            habitState,
          );

      DebugLogger.debug(
        'Generating heat map...',
        tag: StatisticsConstants.logTag,
      );
      results['heatMapData'] = HeatMapStatisticsService.generateHeatMapData(
        taskState,
        habitState,
      );

      DebugLogger.debug(
        'Generating insights...',
        tag: StatisticsConstants.logTag,
      );
      results['insights'] = InsightsStatisticsService.generateInsights(
        taskState,
        habitState,
        startDate,
        endDate,
      );

      DebugLogger.debug(
        'Calculating trends...',
        tag: StatisticsConstants.logTag,
      );
      results['weeklyTrends'] = TrendsStatisticsService.calculateWeeklyTrends(
        taskState,
        habitState,
      );

      results['monthlyTrends'] = TrendsStatisticsService.calculateMonthlyTrends(
        taskState,
        habitState,
      );

      results['performanceTrends'] =
          TrendsStatisticsService.calculatePerformanceTrends(
            taskState,
            habitState,
          );

      DebugLogger.success(
        'All statistics calculated successfully',
        tag: StatisticsConstants.logTag,
        data: {
          'components': results.keys.toList(),
          'overviewScore':
              '${((results['overview']['todayScore'] as double) * 100).round()}%',
          'achievementsUnlocked':
              (results['achievements'] as List)
                  .where((a) => a.isUnlocked)
                  .length,
          'insightsGenerated': (results['insights'] as List).length,
        },
      );

      return results;
    } catch (e, stackTrace) {
      DebugLogger.error(
        'Failed to calculate statistics',
        tag: StatisticsConstants.logTag,
        error: e,
        stackTrace: stackTrace,
      );
      return _getDefaultStatistics();
    }
  }

  static Map<String, dynamic> _getDefaultStatistics() {
    DebugLogger.warning(
      'Using default statistics data',
      tag: StatisticsConstants.logTag,
    );

    return {
      'overview': OverviewStatisticsService.getDefaultOverview(),
      'achievements': AchievementStatisticsService.getDefaultAchievements(),
      'heatMapData': HeatMapStatisticsService.getDefaultHeatMapData(),
      'insights': InsightsStatisticsService.getDefaultInsights(),
      'weeklyTrends': TrendsStatisticsService.getDefaultWeeklyTrends(),
      'monthlyTrends': TrendsStatisticsService.getDefaultMonthlyTrends(),
      'performanceTrends':
          TrendsStatisticsService.getDefaultPerformanceTrends(),
    };
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final double progress;
  final bool isUnlocked;
  final int points;
  final AchievementCategory category;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.progress,
    required this.isUnlocked,
    required this.points,
    required this.category,
  });
}

enum AchievementCategory { tasks, habits, streaks, special }
