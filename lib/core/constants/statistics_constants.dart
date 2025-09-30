import 'package:flutter/foundation.dart';

class StatisticsConstants {
  const StatisticsConstants._();

  static const int heatMapDays = 84;
  static const int perfectDayMinActivities = 8;
  static const int heatMapWeeks = 12;

  static const int earlyBirdHour = 9;
  static const int weekDays = 7;
  static const int monthDays = 30;
  static const int averageCalculationDays = 30;

  static const int taskCompletionPoints = 10;
  static const int habitCompletionPoints = 15;
  static const int streakBonusPerDay = 5;
  static const int overdueTaskPenalty = -5;
  static const int maxTotalPoints = 999999;

  static const Map<int, int> activityLevels = {0: 0, 2: 1, 4: 2, 7: 3};

  static const double excellentCompletionRate = 0.8;
  static const double goodCompletionRate = 0.6;
  static const double poorCompletionRate = 0.4;

  static const int maxInsights = 4;
  static const int warningOverdueTasks = 5;
  static const int excellentStreak = 7;
  static const int goodStreak = 3;
  static const int highProductivityTasksPerDay = 5;

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

  static const bool enableDetailedLogging = kDebugMode;
  static const String logTag = 'Statistics';
}
