import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dayflow/core/constants/app_colors.dart';

class FormattingToolbar extends StatelessWidget {
  final Offset position;
  final Function(String) onFormat;
  final VoidCallback onHide;
  final String? selectedText;

  const FormattingToolbar({
    super.key,
    required this.position,
    required this.onFormat,
    required this.onHide,
    this.selectedText,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx.clamp(10.0, MediaQuery.of(context).size.width - 280),
      top: position.dy - 70,
      child: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(12),
        color: AppColors.surface,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.divider.withAlpha(50),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Text actions section
              _buildToolbarSection([
                _buildToolbarButton(
                  Icons.content_copy,
                  'Copy',
                  () => _handleCopy(),
                ),
                _buildToolbarButton(
                  Icons.content_cut,
                  'Cut',
                  () => _handleCut(),
                ),
              ]),

              // Divider
              Container(
                width: 1,
                height: 32,
                color: AppColors.divider,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),

              // Formatting actions section
              _buildToolbarSection([
                _buildToolbarButton(
                  Icons.format_bold,
                  'Bold',
                  () => _handleFormat('bold'),
                ),
                _buildToolbarButton(
                  Icons.format_italic,
                  'Italic',
                  () => _handleFormat('italic'),
                ),
                _buildToolbarButton(
                  Icons.format_underlined,
                  'Underline',
                  () => _handleFormat('underline'),
                ),
                _buildToolbarButton(
                  Icons.strikethrough_s,
                  'Strikethrough',
                  () => _handleFormat('strikethrough'),
                ),
                _buildToolbarButton(
                  Icons.code,
                  'Code',
                  () => _handleFormat('code'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // Group toolbar buttons in sections
  Widget _buildToolbarSection(List<Widget> children) {
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }

  // Enhanced toolbar button with better styling
  Widget _buildToolbarButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
  ) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
          child: Icon(icon, size: 18, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  // Handle copy action
  void _handleCopy() {
    if (selectedText != null && selectedText!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: selectedText!));
      HapticFeedback.lightImpact();
    }
    onHide();
  }

  // Handle cut action
  void _handleCut() {
    if (selectedText != null && selectedText!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: selectedText!));
      onFormat('delete');
      HapticFeedback.lightImpact();
    }
    onHide();
  }

  // Handle formatting action
  void _handleFormat(String format) {
    onFormat(format);
    HapticFeedback.lightImpact();
    onHide();
  }
}
