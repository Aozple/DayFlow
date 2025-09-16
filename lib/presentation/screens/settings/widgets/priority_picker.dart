import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dayflow/presentation/widgets/draggable_modal.dart';

/// Modal for picking the default task priority.
///
/// This widget provides a visual interface for selecting the default priority
/// for new tasks, with color-coded options and descriptions.
class PriorityPicker extends StatelessWidget {
  /// The currently selected priority (1-5).
  final int currentPriority;

  /// Callback function when a priority is selected.
  final Function(int) onPrioritySelected;

  const PriorityPicker({
    super.key,
    required this.currentPriority,
    required this.onPrioritySelected,
  });

  @override
  Widget build(BuildContext context) {
    int selectedPriority = currentPriority; // Local state for the picker.

    return DraggableModal(
      title: 'Default Priority',
      initialHeight: 320,
      minHeight: 200,
      leftAction: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => Navigator.pop(context), // Cancel button.
        child: const Text(
          'Cancel',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
      rightAction: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          onPrioritySelected(
            selectedPriority,
          ); // Dispatch event to update default priority.
          Navigator.pop(context); // Close modal.
          HapticFeedback.mediumImpact(); // Provide haptic feedback.
        },
        child: Text(
          'Done',
          style: TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: List.generate(5, (index) {
                final priority = index + 1;
                final isSelected = selectedPriority == priority;
                Color priorityColor = AppColors.textSecondary;
                String priorityLabel = 'Normal';
                IconData priorityIcon = CupertinoIcons.flag;

                // Determine color, label, and icon based on priority level.
                switch (priority) {
                  case 5:
                    priorityColor = AppColors.getPriorityColor(5);
                    priorityLabel = 'Urgent';
                    priorityIcon = CupertinoIcons.flag;
                    break;
                  case 4:
                    priorityColor = AppColors.getPriorityColor(4);
                    priorityLabel = 'High';
                    priorityIcon = CupertinoIcons.flag;
                    break;
                  case 3:
                    priorityColor = AppColors.getPriorityColor(3);
                    priorityLabel = 'Medium';
                    priorityIcon = CupertinoIcons.flag;
                    break;
                  case 2:
                    priorityColor = AppColors.getPriorityColor(2);
                    priorityLabel = 'Normal';
                    priorityIcon = CupertinoIcons.flag;
                    break;
                  case 1:
                    priorityColor = AppColors.getPriorityColor(1);
                    priorityLabel = 'Low';
                    priorityIcon = CupertinoIcons.flag;
                    break;
                }

                return GestureDetector(
                  onTap: () {
                    setModalState(() {
                      selectedPriority = priority; // Update local selection.
                    });
                    HapticFeedback.selectionClick(); // Provide haptic feedback.
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? priorityColor.withAlpha(
                                10,
                              ) // Subtle background if selected.
                              : Colors.transparent,
                      border: const Border(
                        bottom: BorderSide(
                          color: AppColors.divider,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Priority icon with colored background.
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: priorityColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Icon(
                              priorityIcon,
                              size: 20,
                              color: priorityColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Priority number and label.
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Priority $priority',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isSelected
                                          ? priorityColor // Text color matches priority if selected.
                                          : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                priorityLabel,
                                style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      isSelected
                                          ? priorityColor.withAlpha(200)
                                          : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Checkmark indicator if selected.
                        if (isSelected)
                          Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            color: priorityColor,
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}
