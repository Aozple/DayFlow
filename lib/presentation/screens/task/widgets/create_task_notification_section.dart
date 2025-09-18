import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:dayflow/core/constants/app_colors.dart';

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
      return Container();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withAlpha(30), width: 0.5),
      ),
      child: Column(
        children: [
          // Notification Toggle Switch
          SwitchListTile(
            secondary: Icon(
              CupertinoIcons.bell,
              color:
                  hasNotification ? AppColors.accent : AppColors.textSecondary,
              size: 22,
            ),
            title: const Text(
              'Reminder',
              style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
            ),
            value: hasNotification,
            onChanged: onNotificationToggle,
            activeThumbColor: AppColors.accent,
          ),

          // Notification settings (only visible when enabled)
          if (hasNotification) ...[
            // Divider
            Container(
              height: 0.5,
              margin: const EdgeInsets.only(left: 56),
              color: AppColors.divider,
            ),

            // Timing settings
            ListTile(
              leading: Icon(
                CupertinoIcons.clock,
                color: AppColors.accent,
                size: 22,
              ),
              title: const Text(
                'Notify me',
                style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
              ),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _showTimingOptions(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getTimingLabel(),
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      CupertinoIcons.chevron_right,
                      color: AppColors.accent,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

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
    } else {
      return '$minutesBefore min before';
    }
  }

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

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.divider.withAlpha(100),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.clock,
                      color: AppColors.accent,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Notify me',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: const Icon(
                        CupertinoIcons.xmark,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final value = option['value'] as int;
                    final label = option['label'] as String;
                    final isSelected =
                        (value == -1 &&
                            minutesBefore != null &&
                            !options.any(
                              (o) =>
                                  o['value'] == minutesBefore &&
                                  o['value'] != -1,
                            )) ||
                        value == minutesBefore;

                    return CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      onPressed: () {
                        if (value == -1) {
                          Navigator.pop(context);
                          _showCustomMinutesDialog(context);
                        } else {
                          onMinutesChanged(value);
                          Navigator.pop(context);
                        }
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              value == -1 &&
                                      minutesBefore != null &&
                                      !options.any(
                                        (o) =>
                                            o['value'] == minutesBefore &&
                                            o['value'] != -1,
                                      )
                                  ? '$minutesBefore min before'
                                  : label,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                color:
                                    isSelected
                                        ? AppColors.accent
                                        : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              CupertinoIcons.checkmark_alt,
                              color: AppColors.accent,
                              size: 20,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
    );
  }

  void _showCustomMinutesDialog(BuildContext context) {
    final controller = TextEditingController(
      text: minutesBefore?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text(
              'Custom reminder time',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Minutes before task',
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    suffixText: 'minutes',
                    suffixStyle: const TextStyle(
                      color: AppColors.textSecondary,
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.accent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final minutes = int.tryParse(controller.text);
                        if (minutes != null && minutes > 0) {
                          onMinutesChanged(minutes);
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Set',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }
}
