import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/presentation/blocs/habits/habit_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
import 'package:flutter/cupertino.dart';

class AchievementBadgesWidget extends StatelessWidget {
  final TaskLoaded taskState;
  final HabitLoaded habitState;

  const AchievementBadgesWidget({
    super.key,
    required this.taskState,
    required this.habitState,
  });

  @override
  Widget build(BuildContext context) {
    final badges = _generateBadges();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.surface.withAlpha(200)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withAlpha(30), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.rosette,
                  size: 16,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Achievements',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${badges.where((b) => b.isUnlocked).length}/${badges.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.9,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: badges.length,
            itemBuilder: (context, index) {
              return _buildBadgeCard(badges[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(Badge badge) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color:
            badge.isUnlocked ? badge.color.withAlpha(10) : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              badge.isUnlocked
                  ? badge.color.withAlpha(40)
                  : AppColors.divider.withAlpha(20),
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  badge.isUnlocked
                      ? badge.color.withAlpha(20)
                      : AppColors.surface.withAlpha(50),
              shape: BoxShape.circle,
            ),
            child: Icon(
              badge.icon,
              size: 24,
              color:
                  badge.isUnlocked
                      ? badge.color
                      : AppColors.textTertiary.withAlpha(100),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            badge.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color:
                  badge.isUnlocked
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            badge.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color:
                  badge.isUnlocked
                      ? AppColors.textSecondary
                      : AppColors.textTertiary.withAlpha(100),
            ),
          ),
          if (badge.isUnlocked) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badge.color.withAlpha(15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge.value,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: badge.color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Badge> _generateBadges() {
    final completedTasks = taskState.completedTasks.length;
    final totalHabits = habitState.activeHabits.length;
    final maxStreak = habitState.habits.fold(
      0,
      (max, h) => h.currentStreak > max ? h.currentStreak : max,
    );

    return [
      Badge(
        title: 'Early Bird',
        description: '5 tasks before 9am',
        icon: CupertinoIcons.sun_max_fill,
        color: AppColors.warning,
        value: '${_getEarlyTasks()}/5',
        isUnlocked: _getEarlyTasks() >= 5,
      ),
      Badge(
        title: 'Finisher',
        description: '100 tasks done',
        icon: CupertinoIcons.checkmark_seal_fill,
        color: AppColors.success,
        value: '$completedTasks/100',
        isUnlocked: completedTasks >= 100,
      ),
      Badge(
        title: 'Consistent',
        description: '7 day streak',
        icon: CupertinoIcons.flame_fill,
        color: AppColors.error,
        value: '$maxStreak days',
        isUnlocked: maxStreak >= 7,
      ),
      Badge(
        title: 'Multi-tasker',
        description: '10 active habits',
        icon: CupertinoIcons.layers_alt_fill,
        color: AppColors.info,
        value: '$totalHabits/10',
        isUnlocked: totalHabits >= 10,
      ),
      Badge(
        title: 'Perfectionist',
        description: '100% daily completion',
        icon: CupertinoIcons.star_circle_fill,
        color: AppColors.accent,
        value: '${_getPerfectDays()} days',
        isUnlocked: _getPerfectDays() >= 1,
      ),
      Badge(
        title: 'Marathon',
        description: '30 day streak',
        icon: CupertinoIcons.flag_circle_fill,
        color: AppColors.warning,
        value: '$maxStreak/30',
        isUnlocked: maxStreak >= 30,
      ),
    ];
  }

  int _getEarlyTasks() {
    return taskState.completedTasks
        .where((task) => task.completedAt != null && task.completedAt!.hour < 9)
        .length;
  }

  int _getPerfectDays() {
    return 3;
  }
}

class Badge {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String value;
  final bool isUnlocked;

  Badge({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.value,
    required this.isUnlocked,
  });
}
