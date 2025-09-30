import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/core/constants/statistics_constants.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:dayflow/core/services/statistics/statistics_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StatisticsAchievementsCard extends StatefulWidget {
  final List<Achievement> achievements;

  const StatisticsAchievementsCard({super.key, required this.achievements});

  @override
  State<StatisticsAchievementsCard> createState() =>
      _StatisticsAchievementsCardState();
}

class _StatisticsAchievementsCardState
    extends State<StatisticsAchievementsCard> {
  Achievement? _selectedAchievement;
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Tasks',
    'Habits',
    'Streaks',
    'Special',
  ];

  @override
  Widget build(BuildContext context) {
    final filteredAchievements = _getFilteredAchievements();
    final unlockedCount =
        filteredAchievements.where((a) => a.isUnlocked).length;
    final totalPoints = filteredAchievements
        .where((a) => a.isUnlocked)
        .fold(0, (sum, a) => sum + a.points);

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
          _buildHeader(unlockedCount, totalPoints),
          const SizedBox(height: 12),
          _buildCategorySelector(),
          const SizedBox(height: 12),
          _buildAchievementsGrid(filteredAchievements),
          if (_selectedAchievement != null) ...[
            const SizedBox(height: 12),
            _buildSelectedAchievementDetails(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(int unlockedCount, int totalPoints) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.warning,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            CupertinoIcons.star_circle_fill,
            size: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Achievements',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$unlockedCount unlocked',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.bolt_fill,
                size: 12,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                '$totalPoints',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return GestureDetector(
            onTap: () => _onCategoryChanged(category),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.divider,
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAchievementsGrid(List<Achievement> achievements) {
    if (achievements.isEmpty) {
      return _buildEmptyState();
    }

    return SizedBox(
      height: 220,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          return _buildAchievementItem(achievements[index]);
        },
      ),
    );
  }

  Widget _buildAchievementItem(Achievement achievement) {
    final isUnlocked = achievement.isUnlocked;
    final isSelected = _selectedAchievement?.id == achievement.id;

    return GestureDetector(
      onTap: () => _onAchievementTapped(achievement),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceLight : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                isSelected
                    ? _getCategoryColor(achievement.category)
                    : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              achievement.icon,
              style: TextStyle(
                fontSize: 20,
                color: isUnlocked ? null : AppColors.textSecondary,
              ),
            ),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color:
                    isUnlocked
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8,
                color:
                    isUnlocked
                        ? AppColors.textSecondary
                        : AppColors.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            !isUnlocked
                ? _buildSimpleProgress(achievement)
                : _buildPointsBadge(achievement),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleProgress(Achievement achievement) {
    final progress = achievement.progress.clamp(0.0, 1.0);
    final color = _getCategoryColor(achievement.category);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 40,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.divider.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${(progress * 100).round()}%',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPointsBadge(Achievement achievement) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _getCategoryColor(achievement.category).withAlpha(20),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _getCategoryColor(achievement.category).withAlpha(100),
          ),
        ),
        child: Text(
          '+${achievement.points}',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _getCategoryColor(achievement.category),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedAchievementDetails() {
    if (_selectedAchievement == null) return const SizedBox.shrink();

    final achievement = _selectedAchievement!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(achievement.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      achievement.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedAchievement = null);
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    CupertinoIcons.xmark,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildDetailStat(
                'Category',
                achievement.category.name.toUpperCase(),
                _getCategoryColor(achievement.category),
              ),
              const SizedBox(width: 16),
              _buildDetailStat(
                'Points',
                '+${achievement.points}',
                AppColors.warning,
              ),
              const SizedBox(width: 16),
              _buildDetailStat(
                'Progress',
                '${(achievement.progress * 100).round()}%',
                AppColors.accent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.star, size: 24, color: AppColors.textTertiary),
          SizedBox(height: 4),
          Text(
            'No achievements found',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<Achievement> _getFilteredAchievements() {
    if (_selectedCategory == 'All') {
      return widget.achievements;
    }

    final categoryEnum = AchievementCategory.values.firstWhere(
      (cat) => cat.name.toLowerCase() == _selectedCategory.toLowerCase(),
      orElse: () => AchievementCategory.tasks,
    );

    return widget.achievements
        .where((achievement) => achievement.category == categoryEnum)
        .toList();
  }

  Color _getCategoryColor(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.tasks:
        return AppColors.success;
      case AchievementCategory.habits:
        return AppColors.info;
      case AchievementCategory.streaks:
        return AppColors.warning;
      case AchievementCategory.special:
        return AppColors.accent;
    }
  }

  void _onCategoryChanged(String category) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedCategory = category;
      _selectedAchievement = null;
    });

    DebugLogger.verbose(
      'Achievement category changed',
      tag: StatisticsConstants.logTag,
      data: {'category': category},
    );
  }

  void _onAchievementTapped(Achievement achievement) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedAchievement =
          _selectedAchievement?.id == achievement.id ? null : achievement;
    });

    DebugLogger.verbose(
      'Achievement tapped',
      tag: StatisticsConstants.logTag,
      data: {
        'achievement': achievement.title,
        'isUnlocked': achievement.isUnlocked,
      },
    );
  }
}
