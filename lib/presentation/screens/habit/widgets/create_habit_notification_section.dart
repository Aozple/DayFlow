import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Compact notification settings widget for habit reminders.
///
/// Provides a streamlined interface for configuring habit reminder notifications
/// with minimal space usage while maintaining clear visual feedback about
/// timing preferences and notification status.
class CreateHabitNotificationSection extends StatelessWidget {
  final bool hasNotification;
  final int minutesBefore;
  final Function(bool) onNotificationToggle;
  final Function(int) onMinutesChanged;

  const CreateHabitNotificationSection({
    super.key,
    required this.hasNotification,
    required this.minutesBefore,
    required this.onNotificationToggle,
    required this.onMinutesChanged,
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
      child: Column(
        children: [_buildMainRow(), if (hasNotification) _buildTimingRow()],
      ),
    );
  }

  /// Build main row with icon, title, status, and toggle
  Widget _buildMainRow() {
    return Row(
      children: [
        _buildNotificationIcon(),
        const SizedBox(width: 12),
        _buildHeaderInfo(),
        const Spacer(),
        _buildToggleSwitch(),
      ],
    );
  }

  /// Build notification icon with current state styling
  Widget _buildNotificationIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              hasNotification
                  ? [AppColors.accent, AppColors.accent.withAlpha(220)]
                  : [
                    AppColors.textSecondary.withAlpha(150),
                    AppColors.textSecondary.withAlpha(100),
                  ],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow:
            hasNotification
                ? [
                  BoxShadow(
                    color: AppColors.accent.withAlpha(30),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
      child: Icon(
        hasNotification ? CupertinoIcons.bell_fill : CupertinoIcons.bell,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  /// Build header information section
  Widget _buildHeaderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Reminder',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
            if (hasNotification) ...[
              const SizedBox(width: 8),
              _buildTimingBadge(),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _getStatusDescription(),
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  /// Build timing badge showing current setting
  Widget _buildTimingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accent.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withAlpha(40), width: 1),
      ),
      child: Text(
        _getTimingLabel(minutesBefore),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.accent,
          height: 1.0,
        ),
      ),
    );
  }

  /// Build toggle switch with enhanced styling
  Widget _buildToggleSwitch() {
    return Transform.scale(
      scale: 0.9,
      child: CupertinoSwitch(
        value: hasNotification,
        onChanged: (value) {
          HapticFeedback.mediumImpact();
          onNotificationToggle(value);
        },
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: AppColors.textSecondary.withAlpha(100),
        thumbColor: Colors.white,
      ),
    );
  }

  /// Build timing options row for notification timing
  Widget _buildTimingRow() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withAlpha(8),
            AppColors.accent.withAlpha(5),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withAlpha(30), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              CupertinoIcons.clock_fill,
              size: 16,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'When:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                _buildTimingButton(0, 'On time'),
                const SizedBox(width: 8),
                _buildTimingButton(5, '5m'),
                const SizedBox(width: 8),
                _buildTimingButton(15, '15m'),
                const SizedBox(width: 8),
                _buildTimingButton(30, '30m'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual timing selection button
  Widget _buildTimingButton(int minutes, String label) {
    final isSelected = minutesBefore == minutes;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onMinutesChanged(minutes);
        },
        child: Container(
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors:
                  isSelected
                      ? [AppColors.accent, AppColors.accent.withAlpha(220)]
                      : [AppColors.surface, AppColors.surface.withAlpha(200)],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isSelected
                      ? AppColors.accent
                      : AppColors.divider.withAlpha(50),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: AppColors.accent.withAlpha(30),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                    : null,
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(
                    CupertinoIcons.checkmark_alt,
                    size: 10,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Get status description based on current settings
  String _getStatusDescription() {
    if (!hasNotification) {
      return 'No reminders for this habit';
    }
    return 'Remind ${_getTimingDescription(minutesBefore)}';
  }

  /// Get timing label for badge display
  String _getTimingLabel(int minutes) {
    switch (minutes) {
      case 0:
        return 'On time';
      case 5:
        return '5 min';
      case 15:
        return '15 min';
      case 30:
        return '30 min';
      default:
        return '${minutes}m';
    }
  }

  /// Get timing description for status text
  String _getTimingDescription(int minutes) {
    if (minutes == 0) {
      return 'at scheduled time';
    }
    return '$minutes minutes before';
  }
}
