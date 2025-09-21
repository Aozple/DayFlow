import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/presentation/widgets/color_picker_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Simplified accent color picker using the universal ColorPickerModal
class AccentColorPicker extends StatelessWidget {
  /// The currently selected color (in hex format)
  final String currentColor;

  /// Callback function when a color is selected
  final Function(String) onColorSelected;

  const AccentColorPicker({
    super.key,
    required this.currentColor,
    required this.onColorSelected,
  });

  /// Show accent color picker modal
  static Future<void> show({
    required BuildContext context,
    required String currentColor,
    required Function(String) onColorSelected,
  }) async {
    final selectedColor = await ColorPickerModal.show(
      context: context,
      selectedColor: currentColor,
      customColors: AppColors.accentColors,
      title: 'Choose Accent Color',
      previewBuilder: (colorHex) => _buildAccentPreview(colorHex),
      showPreview: true,
    );

    if (selectedColor != null) {
      onColorSelected(selectedColor);
    }
  }

  /// Build accent color preview showing how it affects the app
  static Widget _buildAccentPreview(String colorHex) {
    final accentColor = AppColors.fromHex(colorHex);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withAlpha(30), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withAlpha(80),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'App Accent Color',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      colorHex.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Compact preview elements in single row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Compact button
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Icon with background
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: accentColor.withAlpha(40),
                    width: 1,
                  ),
                ),
                child: Icon(
                  CupertinoIcons.heart_fill,
                  color: accentColor,
                  size: 16,
                ),
              ),

              // Compact switch
              Transform.scale(
                scale: 0.8,
                child: CupertinoSwitch(
                  value: true,
                  onChanged: null,
                  activeTrackColor: accentColor,
                ),
              ),

              // Text with icon
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: accentColor,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Text',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This is now just a wrapper that calls the static show method
    return const SizedBox.shrink();
  }
}
