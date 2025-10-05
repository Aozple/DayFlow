import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/core/utils/color_utils.dart';
import 'package:dayflow/core/utils/custom_snackbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CreateNoteColorPicker extends StatelessWidget {
  final String initialColor;

  final Function(String) onColorSelected;

  const CreateNoteColorPicker({
    super.key,
    required this.initialColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    String selectedColorHex = initialColor;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          height: 300,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
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
                padding: const EdgeInsets.all(16),
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
                      'Note Color',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        onColorSelected(selectedColorHex);
                        Navigator.pop(context);
                        CustomSnackBar.success(context, 'Color updated');
                      },
                      child: Text(
                        'Done',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: AppColors.userColors.length,
                    itemBuilder: (context, index) {
                      final color = AppColors.userColors[index];
                      final colorHex = ColorUtils.toHex(color);
                      final isSelected = selectedColorHex == colorHex;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() => selectedColorHex = colorHex);
                          HapticFeedback.lightImpact();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  isSelected
                                      ? Colors.white
                                      : AppColors.divider.withAlpha(50),
                              width: isSelected ? 3 : 1,
                            ),
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
                          ),
                          child:
                              isSelected
                                  ? const Icon(
                                    CupertinoIcons.checkmark,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                  : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }
}
