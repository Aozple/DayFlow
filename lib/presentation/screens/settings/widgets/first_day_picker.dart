import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FirstDayPicker extends StatelessWidget {
  final String currentDay;

  final Function(String) onDaySelected;

  const FirstDayPicker({
    super.key,
    required this.currentDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.divider, width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const Text(
                    'First Day of Week',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Done',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        CupertinoIcons.calendar,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      title: const Text(
                        'Saturday',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: const Text(
                        'Traditional week start',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing:
                          currentDay == 'saturday'
                              ? Icon(
                                CupertinoIcons.checkmark_circle_fill,
                                color: AppColors.accent,
                                size: 24,
                              )
                              : null,
                      onTap: () {
                        onDaySelected('saturday');
                        Navigator.pop(context);
                        HapticFeedback.selectionClick();
                      },
                    ),

                    const Divider(height: 1, color: AppColors.divider),

                    ListTile(
                      leading: const Icon(
                        CupertinoIcons.calendar,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      title: const Text(
                        'Monday',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: const Text(
                        'International standard',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing:
                          currentDay == 'monday'
                              ? Icon(
                                CupertinoIcons.checkmark_circle_fill,
                                color: AppColors.accent,
                                size: 24,
                              )
                              : null,
                      onTap: () {
                        onDaySelected('monday');
                        Navigator.pop(context);
                        HapticFeedback.selectionClick();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
