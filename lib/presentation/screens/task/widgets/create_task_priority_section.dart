import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Section for selecting task priority.
///
/// This widget provides a visual interface for selecting the task priority,
/// with color-coded options and labels.
class CreateTaskPrioritySection extends StatelessWidget {
  /// The currently selected priority (1-5).
  final int priority;

  /// Callback function when the priority changes.
  final Function(int) onPriorityChanged;

  const CreateTaskPrioritySection({
    super.key,
    required this.priority,
    required this.onPriorityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.flag, color: AppColors.accent, size: 22),
              const SizedBox(width: 12),
              const Text(
                'Priority',
                style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Row of priority selection buttons (1 to 5).
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (index) {
              final priorityValue = index + 1;
              final isSelected = priority == priorityValue;
              return GestureDetector(
                onTap:
                    () => onPriorityChanged(
                      priorityValue,
                    ), // Update selected priority.
                child: AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 200,
                  ), // Smooth animation for selection.
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppColors.accent : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.divider,
                      width: isSelected ? 0 : 1,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Display the priority number.
                        Text(
                          priorityValue.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                          ),
                        ),
                        // Add "High" label for priority 5.
                        if (priorityValue == 5)
                          Text(
                            'High',
                            style: TextStyle(
                              fontSize: 9,
                              color:
                                  isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                            ),
                          ),
                        // Add "Low" label for priority 1.
                        if (priorityValue == 1)
                          Text(
                            'Low',
                            style: TextStyle(
                              fontSize: 9,
                              color:
                                  isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
