import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/core/utils/custom_snackbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A Cupertino-style modal for picking the note's color.
///
/// This widget presents a grid of color options that the user can select from
/// to customize the appearance of their note. It provides visual feedback
/// for the selected color and includes a confirmation button.
class CreateNoteColorPicker extends StatelessWidget {
  /// The initially selected color (in hex format).
  final String initialColor;

  /// Callback function when a color is selected.
  final Function(String) onColorSelected;

  const CreateNoteColorPicker({
    super.key,
    required this.initialColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    String selectedColorHex =
        initialColor; // Temporarily hold the selected color in the modal.

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          height: 300,
          decoration: const BoxDecoration(
            color: AppColors.surface, // Background color.
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ), // Rounded top corners.
          ),
          child: Column(
            children: [
              // Drag handle for the modal.
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
                padding: const EdgeInsets.all(16),
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
                      'Note Color', // Title.
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        onColorSelected(
                          selectedColorHex,
                        ); // Apply selected color to main state.
                        Navigator.pop(context); // Close modal.
                        CustomSnackBar.success(
                          context,
                          'Color updated',
                        ); // Show success message.
                      },
                      child: Text(
                        'Done',
                        style: TextStyle(color: AppColors.accent),
                      ),
                    ),
                  ],
                ),
              ),
              // Grid view for displaying selectable color options.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    physics:
                        const BouncingScrollPhysics(), // iOS-style scroll physics.
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4, // 4 columns of colors.
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount:
                        AppColors
                            .userColors
                            .length, // Number of available colors.
                    itemBuilder: (context, index) {
                      final color = AppColors.userColors[index];
                      final colorHex = AppColors.toHex(color);
                      final isSelected =
                          selectedColorHex ==
                          colorHex; // Check if this color is selected.
                      return GestureDetector(
                        onTap: () {
                          setModalState(
                            () => selectedColorHex = colorHex,
                          ); // Update selected color in modal state.
                          HapticFeedback.lightImpact(); // Provide haptic feedback.
                        },
                        child: AnimatedContainer(
                          duration: const Duration(
                            milliseconds: 200,
                          ), // Smooth animation for selection.
                          decoration: BoxDecoration(
                            color: color, // The actual color.
                            shape: BoxShape.circle, // Circular shape.
                            border: Border.all(
                              color:
                                  isSelected
                                      ? Colors
                                          .white // White border if selected.
                                      : AppColors.divider.withAlpha(
                                        50,
                                      ), // Subtle border if not selected.
                              width:
                                  isSelected
                                      ? 3
                                      : 1, // Thicker border if selected.
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
                                    : [], // No shadow if not selected.
                          ),
                          child:
                              isSelected
                                  ? const Icon(
                                    CupertinoIcons
                                        .checkmark, // Checkmark if selected.
                                    color: Colors.white,
                                    size: 20,
                                  )
                                  : null, // No child if not selected.
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).padding.bottom,
              ), // Space for safe area.
            ],
          ),
        );
      },
    );
  }
}
