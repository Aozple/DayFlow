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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: buildContent(context),
    );
  }

  // Common text field decoration for consistency
  InputDecoration getTextFieldDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      border: InputBorder.none,
      contentPadding: EdgeInsets.zero,
      isDense: true,
      hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 16),
    );
  }

  // Common text style for blocks
  TextStyle getTextStyle({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    double height = 1.6,
    Color? color,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      color: color ?? AppColors.textPrimary,
    );
  }

  // Handle text selection changes with callback
  void handleSelectionChange(TextEditingController controller) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onSelectionChanged(controller.selection);
    });
  }

  // Handle text changes with callback
  void handleTextChange(String text) {
    onTextChange(text, blockId);
  }

  // Common container decoration for blocks
  BoxDecoration getBlockDecoration({bool isActive = false}) {
    return BoxDecoration(
      color: isActive ? AppColors.accent.withAlpha(10) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      border:
          isActive
              ? Border.all(color: AppColors.accent.withAlpha(30), width: 1)
              : null,
    );
  }

  // Common padding for block content
  EdgeInsets getBlockPadding() {
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  }
}
