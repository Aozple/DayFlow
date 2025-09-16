import 'package:flutter/material.dart';
import 'package:dayflow/core/constants/app_colors.dart';

abstract class BaseBlockWidget extends StatelessWidget {
  final String blockId;
  final FocusNode focusNode;
  final Function(TextSelection) onSelectionChanged;
  final Function(String, String) onTextChange;

  const BaseBlockWidget({
    super.key,
    required this.blockId,
    required this.focusNode,
    required this.onSelectionChanged,
    required this.onTextChange,
  });

  // Abstract method that each block type must implement
  Widget buildContent(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      child: buildContent(context),
    );
  }

  // Clean text field decoration
  InputDecoration getTextFieldDecoration({
    String? hintText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      border: InputBorder.none,
      contentPadding: EdgeInsets.zero,
      isDense: true,
      hintStyle: TextStyle(
        color: AppColors.textTertiary.withAlpha(120),
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: prefixIcon,
      prefixIconConstraints: prefixIcon != null
          ? const BoxConstraints(minWidth: 28, minHeight: 20)
          : null,
    );
  }

  // Clean text styles
  TextStyle getTextStyle({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    double height = 1.5,
    Color? color,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      color: color ?? AppColors.textPrimary,
    );
  }

  // Heading styles
  TextStyle getHeadingStyle({required int level}) {
    switch (level) {
      case 1:
        return getTextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          height: 1.3,
        );
      case 2:
        return getTextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 1.35,
        );
      case 3:
        return getTextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.4,
        );
      default:
        return getTextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          height: 1.45,
        );
    }
  }

  // Code style
  TextStyle getCodeStyle() {
    return const TextStyle(
      fontFamily: 'monospace',
      fontSize: 14,
      height: 1.6,
      color: AppColors.textPrimary,
    );
  }

  // Handle selection
  void handleSelectionChange(TextEditingController controller) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onSelectionChanged(controller.selection);
    });
  }

  // Handle text change
  void handleTextChange(String text) {
    onTextChange(text, blockId);
  }

  // Minimal block padding
  EdgeInsets getBlockPadding() {
    return EdgeInsets.zero;
  }

  // Simple list bullet
  Widget buildListBullet(String text) {
    return Container(
      width: 20,
      margin: const EdgeInsets.only(right: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  // Simple checkbox for todo
  Widget buildCheckbox({
    required bool checked,
    required VoidCallback onChanged,
  }) {
    return GestureDetector(
      onTap: onChanged,
      child: Container(
        width: 20,
        height: 20,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: checked 
              ? AppColors.accent 
              : AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: checked 
                ? AppColors.accent 
                : AppColors.divider.withAlpha(100),
            width: 1.5,
          ),
        ),
        child: checked
            ? const Icon(
                Icons.check,
                size: 14,
                color: Colors.white,
              )
            : null,
      ),
    );
  }

  // Subtle backgrounds for special blocks
  Color getBlockBackgroundColor(String type) {
    switch (type) {
      case 'quote':
        return AppColors.surfaceLight.withAlpha(20);
      case 'code':
        return AppColors.surface.withAlpha(40);
      case 'callout':
        return AppColors.accent.withAlpha(10);
      default:
        return Colors.transparent;
    }
  }

  // Simple left accent for quotes
  Widget buildQuoteAccent() {
    return Container(
      width: 3,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: AppColors.accent.withAlpha(100),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}