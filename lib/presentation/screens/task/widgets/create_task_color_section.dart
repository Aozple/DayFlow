import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Section for selecting a task color.
///
/// This widget provides a visual interface for selecting the task color,
/// with a grid of color options and selection indicators.
class CreateTaskColorSection extends StatelessWidget {
  /// The currently selected color (in hex format).
  final String selectedColor;

  /// Callback function when the color changes.
  final Function(String) onColorChanged;

  const CreateTaskColorSection({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
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
              Icon(
                CupertinoIcons.paintbrush,
                color: AppColors.accent,
                size: 22,
              ),
              const SizedBox(width: 12),
              const Text(
                'Color',
                style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Wrap widget to display color options, allowing them to wrap to the next line.
          Wrap(
            spacing: 12, // Horizontal spacing between color circles.
            runSpacing: 12, // Vertical spacing between lines of color circles.
            children:
                AppColors.userColors.map((color) {
                  final colorHex = AppColors.toHex(
                    color,
                  ); // Convert color to hex string for comparison.
                  final isSelected =
                      selectedColor ==
                      colorHex; // Check if this color is currently selected.
                  return GestureDetector(
                    onTap:
                        () => onColorChanged(
                          colorHex,
                        ), // Update selected color on tap.
                    child: AnimatedContainer(
                      duration: const Duration(
                        milliseconds: 200,
                      ), // Smooth animation for selection.
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color, // The actual color of the circle.
                        shape: BoxShape.circle, // Make it a circle.
                        border: Border.all(
                          color:
                              isSelected
                                  ? AppColors
                                      .textPrimary // Highlight border if selected.
                                  : Colors
                                      .transparent, // No border if not selected.
                          width: 3,
                        ),
                      ),
                      child:
                          isSelected
                              ? const Icon(
                                Icons.check, // Show a checkmark if selected.
                                color: Colors.white,
                                size: 20,
                              )
                              : null, // No child if not selected.
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}
