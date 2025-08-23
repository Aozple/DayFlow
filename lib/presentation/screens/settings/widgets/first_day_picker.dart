import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Modal for picking the first day of the week.
///
/// This widget provides a simple interface for selecting whether the week
/// should start on Saturday or Monday, with descriptions of each option.
class FirstDayPicker extends StatelessWidget {
  /// The currently selected day ('saturday' or 'monday').
  final String currentDay;

  /// Callback function when a day is selected.
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
        type:
            MaterialType
                .transparency, // Needed for InkWell/ListTile to work correctly.
        child: Column(
          children: [
            // Header for the picker.
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
                    onPressed: () => Navigator.pop(context), // Cancel button.
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const Text(
                    'First Day of Week', // Title.
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context), // Done button.
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
            // Options for Saturday and Monday.
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Saturday option.
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
                                CupertinoIcons
                                    .checkmark_circle_fill, // Checkmark if selected.
                                color: AppColors.accent,
                                size: 24,
                              )
                              : null,
                      onTap: () {
                        onDaySelected('saturday'); // Dispatch update event.
                        Navigator.pop(context); // Close modal.
                        HapticFeedback.selectionClick(); // Provide haptic feedback.
                      },
                    ),
                    // Divider between options.
                    const Divider(height: 1, color: AppColors.divider),
                    // Monday option.
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
                        onDaySelected('monday'); // Dispatch update event.
                        Navigator.pop(context); // Close modal.
                        HapticFeedback.selectionClick(); // Provide haptic feedback.
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
