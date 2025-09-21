import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Compact widget for managing habit time flexibility preferences.
///
/// Provides a streamlined interface for toggling between scheduled and
/// flexible timing modes with minimal space usage while maintaining
/// clear visual feedback about the current state.
class CreateHabitFlexibleTimeSection extends StatelessWidget {
  final bool isFlexibleTime;
  final Function(bool) onFlexibleTimeToggle;

  const CreateHabitFlexibleTimeSection({
    super.key,
    required this.isFlexibleTime,
    required this.onFlexibleTimeToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.surface.withAlpha(250)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(color: AppColors.divider.withAlpha(30), width: 0.5),
      ),
      child: Row(
        children: [
          _buildTimeIcon(),
          const SizedBox(width: 12),
          _buildContentSection(),
          const SizedBox(width: 16),
          _buildToggleSwitch(),
        ],
      ),
    );
  }

  /// Build time icon with current state styling
  Widget _buildTimeIcon() {
    final color = isFlexibleTime ? AppColors.success : AppColors.accent;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withAlpha(220)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(30),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        isFlexibleTime ? CupertinoIcons.time : CupertinoIcons.clock_fill,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  /// Build main content section with title and description
  Widget _buildContentSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Time Flexibility',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _getDescriptionText(),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          if (isFlexibleTime) _buildFlexibleHint(),
        ],
      ),
    );
  }

  /// Build status badge showing current mode
  Widget _buildStatusBadge() {
    final color = isFlexibleTime ? AppColors.success : AppColors.accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(40), width: 1),
      ),
      child: Text(
        isFlexibleTime ? 'Anytime' : 'Scheduled',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          height: 1.0,
        ),
      ),
    );
  }

  /// Build flexible time hint for additional information
  Widget _buildFlexibleHint() {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.info.withAlpha(10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.info.withAlpha(30), width: 1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.info_circle_fill,
            size: 12,
            color: AppColors.info,
          ),
          SizedBox(width: 6),
          Text(
            'Groups with other flexible habits',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.info,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  /// Build toggle switch with enhanced styling
  Widget _buildToggleSwitch() {
    return Transform.scale(
      scale: 0.9,
      child: CupertinoSwitch(
        value: isFlexibleTime,
        onChanged: (value) {
          HapticFeedback.mediumImpact();
          onFlexibleTimeToggle(value);
        },
        activeTrackColor: AppColors.success,
        inactiveTrackColor: AppColors.accent.withAlpha(100),
        thumbColor: Colors.white,
      ),
    );
  }

  /// Get description text based on current state
  String _getDescriptionText() {
    return isFlexibleTime
        ? 'Complete anytime during the day'
        : 'Habit scheduled at specific time';
  }
}
