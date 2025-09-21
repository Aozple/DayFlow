import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:dayflow/core/constants/app_colors.dart';

/// Compact notification settings widget for task reminders.
///
/// Provides a streamlined interface for configuring task reminder notifications
/// with minimal space usage while maintaining clear visual feedback about
/// timing preferences and notification status.
class CreateTaskNotificationSection extends StatelessWidget {
  final bool hasNotification;
  final int? minutesBefore;
  final bool hasDate;
  final Function(bool) onNotificationToggle;
  final Function(int?) onMinutesChanged;

  const CreateTaskNotificationSection({
    super.key,
    required this.hasNotification,
    this.minutesBefore,
    required this.hasDate,
    required this.onNotificationToggle,
    required this.onMinutesChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasDate) {
      return const SizedBox.shrink();
    }

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
        children: [
          _buildMainRow(context),
          if (hasNotification) _buildTimingRow(context),
        ],
      ),
    );
  }

  /// Build main row with icon, title, status, and toggle
  Widget _buildMainRow(BuildContext context) {
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
        _getShortTimingLabel(),
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
  Widget _buildTimingRow(BuildContext context) {
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
            child: GestureDetector(
              onTap: () => _showTimingOptions(context),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.accent.withAlpha(50),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withAlpha(20),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _getTimingLabel(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                          height: 1.0,
                        ),
                      ),
                    ),
                    Icon(
                      CupertinoIcons.chevron_down,
                      size: 14,
                      color: AppColors.accent,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show timing options modal
  void _showTimingOptions(BuildContext context) {
    final options = [
      {'label': 'At time', 'value': 0},
      {'label': '5 min before', 'value': 5},
      {'label': '10 min before', 'value': 10},
      {'label': '15 min before', 'value': 15},
      {'label': '30 min before', 'value': 30},
      {'label': '1 hour before', 'value': 60},
      {'label': 'Custom', 'value': -1},
    ];

    showCupertinoModalPopup<void>(
      context: context,
      builder:
          (BuildContext context) => CupertinoActionSheet(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.clock, color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Notification Timing',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            actions:
                options.map((option) {
                  final value = option['value'] as int;
                  final label = option['label'] as String;
                  final isSelected =
                      value == minutesBefore ||
                      (value == -1 && _isCustomTiming());

                  return CupertinoActionSheetAction(
                    onPressed: () {
                      Navigator.pop(context);
                      if (value == -1) {
                        _showCustomMinutesDialog(context);
                      } else {
                        HapticFeedback.lightImpact();
                        onMinutesChanged(value);
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSelected) ...[
                          Icon(
                            CupertinoIcons.checkmark_alt,
                            color: AppColors.accent,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          value == -1 && _isCustomTiming()
                              ? '$minutesBefore min before (Custom)'
                              : label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color:
                                isSelected
                                    ? AppColors.accent
                                    : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              isDefaultAction: true,
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
    );
  }

  /// Show custom minutes input dialog
  void _showCustomMinutesDialog(BuildContext context) {
    final controller = TextEditingController(
      text: _isCustomTiming() ? minutesBefore.toString() : '',
    );

    showCupertinoDialog<void>(
      context: context,
      builder:
          (BuildContext context) => CupertinoAlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.timer, color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Custom Timing',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            content: Column(
              children: [
                const SizedBox(height: 12),
                const Text(
                  'Enter how many minutes before the task you want to be reminded:',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: controller,
                  placeholder: 'Minutes before',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.accent.withAlpha(50),
                      width: 1,
                    ),
                  ),
                  suffix: Container(
                    padding: const EdgeInsets.only(right: 8),
                    child: const Text(
                      'min',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              CupertinoDialogAction(
                onPressed: () {
                  final minutes = int.tryParse(controller.text.trim());
                  if (minutes != null && minutes > 0 && minutes <= 1440) {
                    // Max 24 hours
                    HapticFeedback.lightImpact();
                    onMinutesChanged(minutes);
                    Navigator.pop(context);
                  } else {
                    // Show error for invalid input
                    HapticFeedback.heavyImpact();
                  }
                },
                isDefaultAction: true,
                child: const Text(
                  'Set',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );
  }

  /// Check if current timing is custom (not in predefined options)
  bool _isCustomTiming() {
    if (minutesBefore == null) return false;
    return ![0, 5, 10, 15, 30, 60].contains(minutesBefore);
  }

  /// Get status description based on current settings
  String _getStatusDescription() {
    if (!hasNotification) {
      return 'No reminder for this task';
    }
    return 'Remind ${_getTimingDescription()}';
  }

  /// Get short timing label for badge display
  String _getShortTimingLabel() {
    if (minutesBefore == null || minutesBefore == 0) {
      return 'At time';
    } else if (minutesBefore! < 60) {
      return '${minutesBefore}m';
    } else {
      return '${(minutesBefore! / 60).round()}h';
    }
  }

  /// Get timing description for status text
  String _getTimingDescription() {
    if (minutesBefore == null || minutesBefore == 0) {
      return 'at scheduled time';
    } else if (minutesBefore! < 60) {
      return '$minutesBefore minutes before';
    } else {
      final hours = (minutesBefore! / 60).round();
      return '$hours hour${hours > 1 ? 's' : ''} before';
    }
  }

  /// Get full timing label for display
  String _getTimingLabel() {
    if (minutesBefore == null || minutesBefore == 0) {
      return 'At time';
    } else if (minutesBefore == 5) {
      return '5 min before';
    } else if (minutesBefore == 10) {
      return '10 min before';
    } else if (minutesBefore == 15) {
      return '15 min before';
    } else if (minutesBefore == 30) {
      return '30 min before';
    } else if (minutesBefore == 60) {
      return '1 hour before';
    } else if (minutesBefore! < 60) {
      return '$minutesBefore min before';
    } else {
      final hours = (minutesBefore! / 60).round();
      return '$hours hour${hours > 1 ? 's' : ''} before';
    }
  }
}
