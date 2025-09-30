import 'package:flutter/foundation.dart';

/// Statistics configuration constants
class StatisticsConstants {
  const StatisticsConstants._();

  // MARK: - Heat Map Configuration
  static const int heatMapDays = 84; // 12 weeks
  static const int perfectDayMinActivities = 8;
  static const int heatMapWeeks = 12;

  // MARK: - Time Configuration
  static const int earlyBirdHour = 9;
  static const int weekDays = 7;
  static const int monthDays = 30;
  static const int averageCalculationDays = 30;

  // MARK: - Points System
  static const int taskCompletionPoints = 10;
  static const int habitCompletionPoints = 15;
  static const int streakBonusPerDay = 5;
  static const int overdueTaskPenalty = -5;
  static const int maxTotalPoints = 999999;

  // MARK: - Activity Levels (for heat map)
  static const Map<int, int> activityLevels = {
    0: 0, // no activity
    2: 1, // low activity
    4: 2, // medium activity
    7: 3, // high activity
    // 8+: 4 (max activity)
  };

  // MARK: - Completion Rate Thresholds
  static const double excellentCompletionRate = 0.8;
  static const double goodCompletionRate = 0.6;
  static const double poorCompletionRate = 0.4;

  // MARK: - Insights Configuration
  static const int maxInsights = 4;
  static const int warningOverdueTasks = 5;
  static const int excellentStreak = 7;
  static const int goodStreak = 3;
  static const int highProductivityTasksPerDay = 5;

  // MARK: - Achievement Thresholds
  static const Map<String, int> achievementThresholds = {
    'task_beginner': 10,
    'task_intermediate': 50,
    'task_master': 100,
    'habit_builder': 5,
    'streak_starter': 3,
    'streak_keeper': 7,
    'streak_master': 30,
    'early_bird': 5,
    'perfect_day': 1,
  };

  // MARK: - Achievement Points
  static const Map<String, int> achievementPoints = {
    'task_beginner': 50,
    'task_intermediate': 200,
    'task_master': 500,
    'habit_builder': 75,
    'streak_starter': 30,
    'streak_keeper': 100,
    'streak_master': 300,
    'early_bird': 100,
    'perfect_day': 150,
  };

  // MARK: - Debug Configuration
  static const bool enableDetailedLogging = kDebugMode;
  static const String logTag = 'Statistics';
}
