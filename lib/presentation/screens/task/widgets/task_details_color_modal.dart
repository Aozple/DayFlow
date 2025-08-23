import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';

/// Modal for quickly changing task color.
///
/// This widget provides a visual interface for changing the color of a task,
/// with a grid of color options and selection indicators.
class TaskDetailsColorModal extends StatelessWidget {
  /// The current task being modified.
  final TaskModel currentTask;

  /// Callback function when the color changes.
  final Function(String) onColorChanged;

  const TaskDetailsColorModal({
    super.key,
    required this.currentTask,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    String selectedColorHex = currentTask.color; // Local state for the picker.

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          height: 320,
          decoration: const BoxDecoration(
            color: AppColors.surface, // Background color.
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              children: [
                // Drag handle.
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header for the color picker modal.
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed:
                            () => Navigator.pop(context), // Cancel button.
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Text(
                        'Select Color', // Title.
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          onColorChanged(
                            selectedColorHex,
                          ); // Update task with selected color.
                          Navigator.pop(context); // Close modal.
                        },
                        child: Text(
                          'Done',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Divider.
                Container(height: 1, color: AppColors.divider),
                // Grid of color options.
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Calculate item size dynamically.
                        final itemSize = (constraints.maxWidth - (3 * 16)) / 4;
                        return Wrap(
                          spacing: 16, // Horizontal spacing.
                          runSpacing: 16, // Vertical spacing.
                          children:
                              AppColors.userColors.map((color) {
                                final colorHex = AppColors.toHex(color);
                                final isSelected =
                                    selectedColorHex ==
                                    colorHex; // Check if this color is selected.
                                return GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      selectedColorHex =
                                          colorHex; // Update local selection.
                                    });
                                    HapticFeedback.lightImpact(); // Provide haptic feedback.
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: itemSize,
                                    height: itemSize,
                                    decoration: BoxDecoration(
                                      color: color, // The actual color.
                                      shape: BoxShape.circle,
                                      boxShadow:
                                          isSelected
                                              ? [
                                                BoxShadow(
                                                  color: color.withAlpha(100),
                                                  blurRadius: 8,
                                                  spreadRadius: 2,
                                                ),
                                              ]
                                              : [], // No shadow if not selected.
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? Colors
                                                    .white // White border if selected.
                                                : AppColors.divider.withAlpha(
                                                  50,
                                                ), // Subtle border otherwise.
                                        width: isSelected ? 3 : 1,
                                      ),
                                    ),
                                    child:
                                        isSelected
                                            ? TweenAnimationBuilder<double>(
                                              tween: Tween(
                                                begin: 0,
                                                end: 1,
                                              ), // Scale animation for checkmark.
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              builder: (context, value, child) {
                                                return Transform.scale(
                                                  scale: value,
                                                  child: const Icon(
                                                    CupertinoIcons
                                                        .checkmark, // Checkmark icon.
                                                    color: Colors.white,
                                                    size: 20,
                                                    weight: 700,
                                                  ),
                                                );
                                              },
                                            )
                                            : null, // No child if not selected.
                                  ),
                                );
                              }).toList(),
                        );
                      },
                    ),
                  ),
                ),
                // Bottom safe area padding.
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        );
      },
    );
  }
}
