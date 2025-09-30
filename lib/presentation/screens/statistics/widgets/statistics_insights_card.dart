import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/core/constants/statistics_constants.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StatisticsInsightsCard extends StatefulWidget {
  final List<String> insights;

  const StatisticsInsightsCard({super.key, required this.insights});

  @override
  State<StatisticsInsightsCard> createState() => _StatisticsInsightsCardState();
}

class _StatisticsInsightsCardState extends State<StatisticsInsightsCard> {
  int _currentInsightIndex = 0;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.insights.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildMainInsight(),
          if (_isExpanded && widget.insights.length > 1) ...[
            const SizedBox(height: 12),
            _buildAllInsights(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.info,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            CupertinoIcons.lightbulb_fill,
            size: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Insights',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (widget.insights.length > 1) ...[
          Text(
            '${_currentInsightIndex + 1}/${widget.insights.length}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _isExpanded = !_isExpanded);
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _isExpanded
                    ? CupertinoIcons.chevron_up
                    : CupertinoIcons.chevron_down,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMainInsight() {
    if (widget.insights.isEmpty) return const SizedBox.shrink();

    final insight = widget.insights[_currentInsightIndex];

    return _buildInsightItem(insight, isMain: true);
  }

  Widget _buildAllInsights() {
    return Column(
      children:
          widget.insights
              .asMap()
              .entries
              .where((entry) => entry.key != _currentInsightIndex)
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildInsightItem(entry.value, isMain: false),
                ),
              )
              .toList(),
    );
  }

  Widget _buildInsightItem(String insight, {bool isMain = false}) {
    final iconData = _getInsightIcon(insight);
    final color = _getInsightColor(insight);
    final cleanInsight = _cleanInsightText(insight);

    return Container(
      padding: EdgeInsets.all(isMain ? 12 : 10),
      decoration: BoxDecoration(
        color: isMain ? AppColors.surfaceLight : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isMain ? color : AppColors.divider,
          width: isMain ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(iconData, size: isMain ? 16 : 14, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cleanInsight,
                  style: TextStyle(
                    fontSize: isMain ? 14 : 13,
                    color: AppColors.textPrimary,
                    fontWeight: isMain ? FontWeight.w600 : FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                if (isMain) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getInsightCategory(insight),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isMain && widget.insights.length > 1)
            GestureDetector(
              onTap: _nextInsight,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  CupertinoIcons.forward,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getInsightIcon(String insight) {
    final lowerInsight = insight.toLowerCase();

    if (lowerInsight.contains('excellent') ||
        lowerInsight.contains('perfect')) {
      return CupertinoIcons.star_fill;
    } else if (lowerInsight.contains('overdue') ||
        lowerInsight.contains('review')) {
      return CupertinoIcons.exclamationmark_triangle;
    } else if (lowerInsight.contains('streak') ||
        lowerInsight.contains('amazing')) {
      return CupertinoIcons.flame_fill;
    } else if (lowerInsight.contains('try') ||
        lowerInsight.contains('breaking') ||
        lowerInsight.contains('consider')) {
      return CupertinoIcons.lightbulb;
    } else if (lowerInsight.contains('good') ||
        lowerInsight.contains('great') ||
        lowerInsight.contains('all')) {
      return CupertinoIcons.hand_thumbsup_fill;
    } else if (lowerInsight.contains('keep') ||
        lowerInsight.contains('building') ||
        lowerInsight.contains('consistency')) {
      return CupertinoIcons.bolt_fill;
    } else if (lowerInsight.contains('averaging') ||
        lowerInsight.contains('productivity')) {
      return CupertinoIcons.rocket_fill;
    } else if (lowerInsight.contains('completed') ||
        lowerInsight.contains('management')) {
      return CupertinoIcons.star_circle_fill;
    } else {
      return CupertinoIcons.info_circle;
    }
  }

  Color _getInsightColor(String insight) {
    final lowerInsight = insight.toLowerCase();

    if (lowerInsight.contains('excellent') ||
        lowerInsight.contains('perfect') ||
        lowerInsight.contains('all') ||
        lowerInsight.contains('great')) {
      return AppColors.success;
    } else if (lowerInsight.contains('overdue') ||
        lowerInsight.contains('review') ||
        lowerInsight.contains('try')) {
      return AppColors.warning;
    } else if (lowerInsight.contains('streak') ||
        lowerInsight.contains('amazing') ||
        lowerInsight.contains('keep')) {
      return AppColors.error;
    } else if (lowerInsight.contains('breaking') ||
        lowerInsight.contains('consider') ||
        lowerInsight.contains('tip')) {
      return AppColors.info;
    } else {
      return AppColors.accent;
    }
  }

  String _cleanInsightText(String insight) {
    String cleaned = insight;

    const emojis = [
      '🎉',
      '✨',
      '⚠️',
      '🔥',
      '💡',
      '👍',
      '💪',
      '🚀',
      '⭐',
      '📈',
      '🎯',
      '🔄',
      '💯',
      '🌟',
      '👌',
      '✅',
      '❌',
      '⚡',
    ];

    for (final emoji in emojis) {
      cleaned = cleaned.replaceAll(emoji, '');
    }

    return cleaned.trim();
  }

  String _getInsightCategory(String insight) {
    final lowerInsight = insight.toLowerCase();

    if (lowerInsight.contains('task')) {
      return 'Tasks';
    } else if (lowerInsight.contains('habit')) {
      return 'Habits';
    } else if (lowerInsight.contains('streak')) {
      return 'Streaks';
    } else if (lowerInsight.contains('overdue') ||
        lowerInsight.contains('time')) {
      return 'Time';
    } else if (lowerInsight.contains('productivity') ||
        lowerInsight.contains('averaging')) {
      return 'Productivity';
    } else {
      return 'General';
    }
  }

  void _nextInsight() {
    HapticFeedback.lightImpact();
    setState(() {
      _currentInsightIndex =
          (_currentInsightIndex + 1) % widget.insights.length;
    });

    DebugLogger.verbose(
      'Insight navigation',
      tag: StatisticsConstants.logTag,
      data: {'currentIndex': _currentInsightIndex},
    );
  }
}
