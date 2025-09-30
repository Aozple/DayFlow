import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/core/constants/statistics_constants.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:dayflow/presentation/widgets/draggable_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StatisticsQuickStats extends StatefulWidget {
  final Map<String, dynamic> overview;

  const StatisticsQuickStats({super.key, required this.overview});

  @override
  State<StatisticsQuickStats> createState() => _StatisticsQuickStatsState();
}

class _StatisticsQuickStatsState extends State<StatisticsQuickStats> {
  final ScrollController _scrollController = ScrollController();
  int? _selectedIndex;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 95,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _getStatCards().length,
        itemBuilder: (context, index) {
          final stat = _getStatCards()[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index < _getStatCards().length - 1 ? 12 : 0,
            ),
            child: _buildStatCard(
              title: stat['title'],
              value: stat['value'],
              icon: stat['icon'],
              color: stat['color'],
              trend: stat['trend'],
              isSelected: _selectedIndex == index,
              onTap: () => _onStatTapped(index, stat),
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getStatCards() {
    final overview = widget.overview;

    return [
      {
        'title': 'Total Points',
        'value': _formatNumber(overview['totalPoints'] ?? 0),
        'icon': CupertinoIcons.bolt_fill,
        'color': AppColors.warning,
        'trend': _calculatePointsTrend(overview['totalPoints'] ?? 0),
        'description':
            'Points earned from completing tasks and maintaining streaks',
      },
      {
        'title': 'Week Avg',
        'value': '${((overview['weeklyAverage'] ?? 0.0) * 100).round()}%',
        'icon': CupertinoIcons.chart_bar_fill,
        'color': AppColors.success,
        'trend': _calculateWeeklyTrend(overview['weeklyAverage'] ?? 0.0),
        'description': 'Average completion rate over the last 7 days',
      },
      {
        'title': 'Tasks Done',
        'value': _formatNumber(overview['totalTasksCompleted'] ?? 0),
        'icon': CupertinoIcons.checkmark_seal_fill,
        'color': AppColors.accent,
        'trend': null,
        'description': 'Total number of tasks completed',
      },
      {
        'title': 'Active Habits',
        'value': _formatNumber(overview['totalActiveHabits'] ?? 0),
        'icon': CupertinoIcons.repeat,
        'color': AppColors.info,
        'trend': null,
        'description': 'Number of habits currently being tracked',
      },
      {
        'title': 'Current Streak',
        'value': _formatNumber(overview['currentStreak'] ?? 0),
        'icon': CupertinoIcons.flame_fill,
        'color': AppColors.error,
        'trend': _calculateStreakTrend(overview['currentStreak'] ?? 0),
        'description': 'Your longest active habit streak',
      },
      {
        'title': 'Overdue',
        'value': _formatNumber(overview['overdueTasks'] ?? 0),
        'icon': CupertinoIcons.exclamationmark_circle,
        'color': AppColors.error,
        'trend': _calculateOverdueTrend(overview['overdueTasks'] ?? 0),
        'description': 'Tasks that are past their due date',
      },
    ];
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? trend,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 125,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(10) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected
                    ? color.withAlpha(100)
                    : AppColors.divider.withAlpha(30),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: color.withAlpha(20),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 22,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, size: 12, color: color),
                  ),
                  if (trend != null) _buildTrendIndicator(trend, color),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendIndicator(String trend, Color baseColor) {
    IconData icon;
    Color color;

    if (trend.startsWith('+')) {
      icon = CupertinoIcons.arrow_up;
      color = AppColors.success;
    } else if (trend.startsWith('-')) {
      icon = CupertinoIcons.arrow_down;
      color = AppColors.error;
    } else {
      icon = CupertinoIcons.minus;
      color = AppColors.textTertiary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 7, color: color),
          const SizedBox(width: 1),
          Text(
            trend.replaceAll('+', '').replaceAll('-', ''),
            style: TextStyle(
              fontSize: 7,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _onStatTapped(int index, Map<String, dynamic> stat) {
    setState(() {
      _selectedIndex = _selectedIndex == index ? null : index;
    });

    DebugLogger.verbose(
      'Quick stat tapped',
      tag: StatisticsConstants.logTag,
      data: {
        'stat': stat['title'],
        'value': stat['value'],
        'selected': _selectedIndex == index,
      },
    );

    if (_selectedIndex == index) {
      _showStatDetails(stat);
    }
  }

  void _showStatDetails(Map<String, dynamic> stat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => DraggableModal(
            title: stat['title'],
            initialHeight: 250,
            minHeight: 200,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (stat['color'] as Color).withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          stat['icon'],
                          size: 20,
                          color: stat['color'],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stat['value'],
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: stat['color'],
                              ),
                            ),
                            if (stat['trend'] != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Text(
                                    'Trend: ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  _buildTrendIndicator(
                                    stat['trend'],
                                    stat['color'],
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    stat['description'] ??
                        'No additional information available.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String? _calculatePointsTrend(int points) {
    if (points > 1000) return '+12%';
    if (points > 500) return '+8%';
    if (points > 100) return '+5%';
    return null;
  }

  String? _calculateWeeklyTrend(double average) {
    if (average > 0.8) return '+5%';
    if (average > 0.6) return '+2%';
    if (average < 0.4) return '-3%';
    return '~';
  }

  String? _calculateStreakTrend(int streak) {
    if (streak >= 30) return '+7d';
    if (streak >= 7) return '+2d';
    if (streak >= 3) return '+1d';
    return null;
  }

  String? _calculateOverdueTrend(int overdue) {
    if (overdue > 10) return '+3';
    if (overdue > 5) return '+1';
    if (overdue == 0) return '-2';
    return null;
  }
}
