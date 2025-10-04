import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';

class TaskDetailsColorModal extends StatelessWidget {
  final TaskModel currentTask;

  final Function(String) onColorChanged;

  const TaskDetailsColorModal({
    super.key,
    required this.currentTask,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    String selectedColorHex = currentTask.color;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          height: 320,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

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
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Text(
                        'Select Color',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          onColorChanged(selectedColorHex);
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Done',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Container(height: 1, color: AppColors.divider),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final itemSize = (constraints.maxWidth - (3 * 16)) / 4;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children:
                              AppColors.userColors.map((color) {
                                final colorHex = AppColors.toHex(color);
                                final isSelected = selectedColorHex == colorHex;
                                return GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      selectedColorHex = colorHex;
                                    });
                                    HapticFeedback.lightImpact();
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: itemSize,
                                    height: itemSize,
                                    decoration: BoxDecoration(
                                      color: color,
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
                                              : [],
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : AppColors.divider.withAlpha(
                                                  50,
                                                ),
                                        width: isSelected ? 3 : 1,
                                      ),
                                    ),
                                    child:
                                        isSelected
                                            ? TweenAnimationBuilder<double>(
                                              tween: Tween(begin: 0, end: 1),
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              builder: (context, value, child) {
                                                return Transform.scale(
                                                  scale: value,
                                                  child: const Icon(
                                                    CupertinoIcons.checkmark,
                                                    color: Colors.white,
                                                    size: 20,
                                                    weight: 700,
                                                  ),
                                                );
                                              },
                                            )
                                            : null,
                                  ),
                                );
                              }).toList(),
                        );
                      },
                    ),
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        );
      },
    );
  }
}
