import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dayflow/presentation/widgets/draggable_modal.dart';

/// Modal for picking the app's accent color.
///
/// This widget provides a visual interface for selecting the app's accent color,
/// with a live preview of how the color will look in the app.
class AccentColorPicker extends StatelessWidget {
  /// The currently selected color (in hex format).
  final String currentColor;

  /// Callback function when a color is selected.
  final Function(String) onColorSelected;

  const AccentColorPicker({
    super.key,
    required this.currentColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    String selectedColorHex = currentColor; // Local state for the picker.

    return DraggableModal(
      title: 'Accent Color',
      initialHeight: 420,
      minHeight: 250,
      allowFullScreen: true,
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
          onColorSelected(
            selectedColorHex,
          ); // Dispatch event to update accent color.
          Navigator.pop(context); // Close the modal.
          HapticFeedback.mediumImpact(); // Provide haptic feedback.
        },
        child: Text(
          'Apply',
          style: TextStyle(
            color: AppColors.fromHex(
              selectedColorHex,
            ), // Apply button color matches selected accent.
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Live preview section of the selected accent color.
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Color swatch preview.
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.fromHex(selectedColorHex),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.fromHex(
                                    selectedColorHex,
                                  ).withAlpha(100),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Preview',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your app accent color',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.fromHex(selectedColorHex),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Sample UI elements showing the accent color in action.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Sample button.
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.fromHex(selectedColorHex),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Button',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          // Sample icon.
                          Icon(
                            CupertinoIcons.heart_fill,
                            color: AppColors.fromHex(selectedColorHex),
                            size: 24,
                          ),
                          // Sample switch.
                          CupertinoSwitch(
                            value: true,
                            onChanged: null, // Disabled for preview.
                            activeTrackColor: AppColors.fromHex(
                              selectedColorHex,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // List of selectable accent color options.
                ...AppColors.accentColors.asMap().entries.map((entry) {
                  final index = entry.key;
                  final color = entry.value;
                  final colorHex = AppColors.toHex(color);
                  final isSelected = selectedColorHex == colorHex;
                  // Define human-readable names for the colors.
                  final colorNames = [
                    'Blue',
                    'Green',
                    'Red',
                    'Orange',
                    'Yellow',
                    'Indigo',
                    'Purple',
                    'Cyan',
                    'Pink',
                  ];
                  final colorName =
                      index < colorNames.length ? colorNames[index] : 'Custom';

                  return GestureDetector(
                    onTap: () {
                      setModalState(
                        () => selectedColorHex = colorHex,
                      ); // Update local selection.
                      HapticFeedback.selectionClick(); // Provide haptic feedback.
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? color.withAlpha(
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
                          // Color preview square.
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? Colors
                                            .white // White border if selected.
                                        : AppColors.divider.withAlpha(
                                          100,
                                        ), // Subtle border otherwise.
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow:
                                  isSelected
                                      ? [
                                        BoxShadow(
                                          color: color.withAlpha(100),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                      : [],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Color name and hex code.
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  colorName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isSelected
                                            ? color // Text color matches accent if selected.
                                            : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  colorHex.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Checkmark indicator if selected.
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child:
                                isSelected
                                    ? Icon(
                                      CupertinoIcons.checkmark_circle_fill,
                                      key: ValueKey(
                                        colorHex,
                                      ), // Key for animation.
                                      color: color,
                                      size: 24,
                                    )
                                    : const SizedBox(
                                      key: ValueKey(
                                        'empty',
                                      ), // Key for animation.
                                      width: 24,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
