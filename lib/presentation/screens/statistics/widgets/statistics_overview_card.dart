import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/core/constants/statistics_constants.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:dayflow/presentation/widgets/draggable_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StatisticsOverviewCard extends StatefulWidget {
  final Map<String, dynamic> overview;

  const StatisticsOverviewCard({super.key, required this.overview});

  @override
  State<StatisticsOverviewCard> createState() => _StatisticsOverviewCardState();
}

class _StatisticsOverviewCardState extends State<StatisticsOverviewCard>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  int? _selectedMetricIndex;
  bool _showDetailedProgress = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: (widget.overview['todayScore'] as double? ?? 0.0),
    ).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    _progressController.forward();

    final score = widget.overview['todayScore'] as double? ?? 0.0;
    if (score >= 0.9) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildMetricsRow(),
          const SizedBox(height: 16),
          _buildProgressSection(),
          if (_showDetailedProgress) ...[
            const SizedBox(height: 12),
            _buildDetailedProgress(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final todayScore = widget.overview['todayScore'] as double? ?? 0.0;
    final scorePercent = (todayScore * 100).round();

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.accent.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(CupertinoIcons.today, size: 16, color: AppColors.accent),
        ),
        const SizedBox(width: 10),
        const Text(
          'Today\'s Overview',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: _buildScoreBadge(scorePercent),
            );
          },
        ),
      ],
    );
  }

  Widget _buildScoreBadge(int score) {
    Color color;
    String label;
    IconData icon;

    if (score >= 90) {
      color = AppColors.success;
      label = 'Perfect';
      icon = CupertinoIcons.star_fill;
    } else if (score >= 70) {
      color = AppColors.accent;
      label = 'Great';
      icon = CupertinoIcons.heart_fill;
    } else if (score >= 50) {
      color = AppColors.warning;
      label = 'Good';
      icon = CupertinoIcons.hand_thumbsup_fill;
    } else {
      color = AppColors.error;
      label = 'Keep Going';
      icon = CupertinoIcons.bolt_fill;
    }

    return GestureDetector(
      onTap: () => _showScoreDetails(score, label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsRow() {
    final overview = widget.overview;

    final metrics = [
      {
        'icon': CupertinoIcons.checkmark_circle_fill,
        'value':
            '${overview['todayTasksCompleted'] ?? 0}/${overview['todayTasksTotal'] ?? 0}',
        'label': 'Tasks',
        'color': AppColors.success,
        'completion':
            overview['todayTasksTotal'] > 0
                ? (overview['todayTasksCompleted'] ?? 0) /
                    (overview['todayTasksTotal'] ?? 1)
                : 0.0,
        'description': 'Tasks completed today',
      },
      {
        'icon': CupertinoIcons.repeat,
        'value':
            '${overview['todayHabitsCompleted'] ?? 0}/${overview['todayHabitsTotal'] ?? 0}',
        'label': 'Habits',
        'color': AppColors.info,
        'completion':
            overview['todayHabitsTotal'] > 0
                ? (overview['todayHabitsCompleted'] ?? 0) /
                    (overview['todayHabitsTotal'] ?? 1)
                : 0.0,
        'description': 'Habits completed today',
      },
      {
        'icon': CupertinoIcons.flame_fill,
        'value': '${overview['currentStreak'] ?? 0}',
        'label': 'Streak',
        'color': AppColors.warning,
        'completion': null,
        'description': 'Current longest streak',
      },
    ];

    return Row(
      children:
          metrics.asMap().entries.map((entry) {
            final index = entry.key;
            final metric = entry.value;
            final isSelected = _selectedMetricIndex == index;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index < metrics.length - 1 ? 12 : 0,
                ),
                child: _buildMetric(
                  metric: metric,
                  isSelected: isSelected,
                  onTap: () => _onMetricTapped(index, metric),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildMetric({
    required Map<String, dynamic> metric,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = metric['color'] as Color;
    final completion = metric['completion'] as double?;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(15) : color.withAlpha(10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color.withAlpha(100) : color.withAlpha(40),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(metric['icon'], size: 16, color: color),
            const SizedBox(height: 6),
            Text(
              metric['value'],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              metric['label'],
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
            if (completion != null) ...[
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: completion,
                backgroundColor: color.withAlpha(30),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 2,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Daily Progress',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            Row(
              children: [
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return Text(
                      '${(_progressAnimation.value * 100).round()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap:
                      () => setState(
                        () => _showDetailedProgress = !_showDetailedProgress,
                      ),
                  child: Icon(
                    _showDetailedProgress
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.info_circle,
                    size: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progressAnimation.value.clamp(0.0, 1.0),
                backgroundColor: AppColors.divider.withAlpha(60),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(_progressAnimation.value),
                ),
                minHeight: 8,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDetailedProgress() {
    final overview = widget.overview;
    final tasksCompletion =
        overview['todayTasksTotal'] > 0
            ? (overview['todayTasksCompleted'] ?? 0) /
                (overview['todayTasksTotal'] ?? 1)
            : 0.0;
    final habitsCompletion =
        overview['todayHabitsTotal'] > 0
            ? (overview['todayHabitsCompleted'] ?? 0) /
                (overview['todayHabitsTotal'] ?? 1)
            : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider.withAlpha(20)),
      ),
      child: Column(
        children: [
          _buildProgressDetail('Tasks', tasksCompletion, AppColors.success),
          const SizedBox(height: 8),
          _buildProgressDetail('Habits', habitsCompletion, AppColors.info),
        ],
      ),
    );
  }

  Widget _buildProgressDetail(String label, double completion, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: completion.clamp(0.0, 1.0),
            backgroundColor: color.withAlpha(30),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(completion * 100).round()}%',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.9) return AppColors.success;
    if (progress >= 0.7) return AppColors.accent;
    if (progress >= 0.5) return AppColors.warning;
    return AppColors.error;
  }

  void _onMetricTapped(int index, Map<String, dynamic> metric) {
    setState(() {
      _selectedMetricIndex = _selectedMetricIndex == index ? null : index;
    });

    DebugLogger.verbose(
      'Overview metric tapped',
      tag: StatisticsConstants.logTag,
      data: {
        'metric': metric['label'],
        'value': metric['value'],
        'selected': _selectedMetricIndex == index,
      },
    );

    if (_selectedMetricIndex == index) {
      _showMetricDetails(metric);
    }
  }

  void _showMetricDetails(Map<String, dynamic> metric) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => DraggableModal(
            title: metric['label'],
            initialHeight: 270,
            minHeight: 260,
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
                          color: metric['color'],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          metric['icon'],
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              metric['value'],
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: metric['color'],
                              ),
                            ),
                            if (metric['completion'] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${(metric['completion'] * 100).round()}% complete',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    metric['description'] ??
                        'No additional information available.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  if (metric['completion'] != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: metric['completion'],
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: metric['color'],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
    );
  }

  void _showScoreDetails(int score, String label) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$score%'),
                const SizedBox(width: 8),
                Text(label),
              ],
            ),
            content: Column(
              children: [
                const SizedBox(height: 8),
                Text('Your daily completion score is $score%.'),
                const SizedBox(height: 8),
                if (score >= 90)
                  const Text(
                    '🎉 Perfect! You\'re absolutely crushing it today!',
                  )
                else if (score >= 70)
                  const Text('🔥 Great work! You\'re doing amazing!')
                else if (score >= 50)
                  const Text('👍 Good progress! Keep it up!')
                else
                  const Text('💪 Every step counts! You\'ve got this!'),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }
}
