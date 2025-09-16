import 'package:flutter/material.dart';
import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/note_block.dart';
import 'base_block_widget.dart';

class CalloutBlockWidget extends BaseBlockWidget {
  final CalloutBlock block;
  final Function(CalloutBlock) onChanged;

  CalloutBlockWidget({
    super.key,
    required this.block,
    required super.focusNode,
    required this.onChanged,
    required super.onSelectionChanged,
    required super.onTextChange,
  }) : super(blockId: block.id);

  @override
  Widget buildContent(BuildContext context) {
    return _CalloutFieldWidget(
      block: block,
      focusNode: focusNode,
      onChanged: onChanged,
      onSelectionChanged: onSelectionChanged,
      onTextChange: onTextChange,
    );
  }
}

class _CalloutFieldWidget extends StatefulWidget {
  final CalloutBlock block;
  final FocusNode focusNode;
  final Function(CalloutBlock) onChanged;
  final Function(TextSelection) onSelectionChanged;
  final Function(String, String) onTextChange;

  const _CalloutFieldWidget({
    required this.block,
    required this.focusNode,
    required this.onChanged,
    required this.onSelectionChanged,
    required this.onTextChange,
  });

  @override
  State<_CalloutFieldWidget> createState() => _CalloutFieldWidgetState();
}

class _CalloutFieldWidgetState extends State<_CalloutFieldWidget> {
  late TextEditingController _controller;
  bool _isDisposed = false;
  TextDirection _textDirection = TextDirection.ltr;

  // Enhanced callout types
  final Map<String, _CalloutType> _calloutTypes = {
    'info': const _CalloutType(
      'info',
      'Information',
      Icons.info_outline_rounded,
      Color(0xFF0EA5E9),
    ),
    'warning': const _CalloutType(
      'warning',
      'Warning',
      Icons.warning_amber_rounded,
      Color(0xFFF59E0B),
    ),
    'error': const _CalloutType(
      'error',
      'Error',
      Icons.error_outline_rounded,
      Color(0xFFEF4444),
    ),
    'success': const _CalloutType(
      'success',
      'Success',
      Icons.check_circle_outline_rounded,
      Color(0xFF10B981),
    ),
    'tip': const _CalloutType(
      'tip',
      'Tip',
      Icons.lightbulb_outline_rounded,
      Color(0xFF8B5CF6),
    ),
    'note': const _CalloutType(
      'note',
      'Note',
      Icons.sticky_note_2_outlined,
      Color(0xFF6B7280),
    ),
  };

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.text);
    _controller.addListener(_onTextChanged);
    _controller.addListener(_onSelectionChanged);
    _updateTextDirection(widget.block.text);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_CalloutFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.text != widget.block.text && !_isDisposed) {
      if (_controller.text != widget.block.text) {
        _controller.text = widget.block.text;
        _updateTextDirection(widget.block.text);
      }
    }
  }

  void _onTextChanged() {
    if (_isDisposed) return;

    _updateTextDirection(_controller.text);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        widget.onChanged(widget.block.copyWith(text: _controller.text));
        widget.onTextChange(_controller.text, widget.block.id);
      }
    });
  }

  void _onSelectionChanged() {
    if (_isDisposed || !mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        widget.onSelectionChanged(_controller.selection);
      }
    });
  }

  // Smart RTL/LTR detection
  void _updateTextDirection(String text) {
    if (text.isEmpty) {
      setState(() => _textDirection = TextDirection.ltr);
      return;
    }

    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      setState(() => _textDirection = TextDirection.ltr);
      return;
    }

    final firstChar = trimmedText.runes.first;
    final isRTL = _isRTLCharacter(firstChar);

    setState(() {
      _textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;
    });
  }

  bool _isRTLCharacter(int char) {
    return (char >= 0x0600 && char <= 0x06FF) || // Arabic
        (char >= 0x0750 && char <= 0x077F) || // Arabic Supplement
        (char >= 0xFB50 && char <= 0xFDFF) || // Arabic Presentation Forms
        (char >= 0xFE70 && char <= 0xFEFF) || // Arabic Presentation Forms-B
        (char >= 0x0590 && char <= 0x05FF); // Hebrew
  }

  @override
  Widget build(BuildContext context) {
    final calloutType =
        _calloutTypes[widget.block.calloutType] ?? _calloutTypes['info']!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            calloutType.color.withAlpha(15),
            calloutType.color.withAlpha(8),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              widget.focusNode.hasFocus
                  ? calloutType.color.withAlpha(80)
                  : calloutType.color.withAlpha(40),
          width: widget.focusNode.hasFocus ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: calloutType.color.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 48,
            padding: const EdgeInsets.only(top: 14),
            child: Icon(calloutType.icon, size: 24, color: calloutType.color),
          ),

          // Content and type selector
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type selector with better design
                Padding(
                  padding: const EdgeInsets.only(top: 14, right: 12),
                  child: InkWell(
                    onTap: () => _showTypeSelector(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.divider.withAlpha(30),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            calloutType.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: calloutType.color,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: calloutType.color.withAlpha(150),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Content area with RTL support
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 14, right: 12),
                  child: TextField(
                    controller: _controller,
                    focusNode: widget.focusNode,
                    maxLines: null,
                    textDirection: _textDirection,
                    textAlign:
                        _textDirection == TextDirection.rtl
                            ? TextAlign.right
                            : TextAlign.left,
                    decoration: InputDecoration(
                      hintText: _getPlaceholderText(),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      hintStyle: TextStyle(
                        color: AppColors.textTertiary.withAlpha(100),
                        fontSize: 16,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.1,
                    ),
                    onTap: _onSelectionChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Show type selector with modern design
  void _showTypeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.divider.withAlpha(100),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Select Callout Type',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                const Divider(height: 1),

                // Type options
                ..._calloutTypes.entries.map((entry) {
                  final type = entry.value;
                  final isSelected = widget.block.calloutType == entry.key;

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? type.color.withAlpha(15)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          isSelected
                              ? Border.all(
                                color: type.color.withAlpha(30),
                                width: 0.5,
                              )
                              : null,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              type.color.withAlpha(20),
                              type.color.withAlpha(10),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: type.color.withAlpha(40),
                            width: 0.5,
                          ),
                        ),
                        child: Icon(type.icon, color: type.color, size: 22),
                      ),
                      title: Text(
                        type.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color:
                              isSelected ? type.color : AppColors.textPrimary,
                        ),
                      ),
                      trailing:
                          isSelected
                              ? Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: type.color,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              )
                              : null,
                      onTap: () {
                        widget.onChanged(
                          widget.block.copyWith(calloutType: entry.key),
                        );
                        Navigator.pop(context);
                      },
                    ),
                  );
                }),

                SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
              ],
            ),
          ),
    );
  }

  // Get bilingual placeholder text
  String _getPlaceholderText() {
    switch (widget.block.calloutType) {
      case 'info':
        return 'Add your information here...';
      case 'warning':
        return 'Add your warning here...';
      case 'error':
        return 'Describe the error here...';
      case 'success':
        return 'Add success message here...';
      case 'tip':
        return 'Add your tip here...';
      case 'note':
        return 'Add your note here...';
      default:
        return 'Add your message here...';
    }
  }
}

// Callout type model
class _CalloutType {
  final String key;
  final String name;
  final IconData icon;
  final Color color;

  const _CalloutType(this.key, this.name, this.icon, this.color);
}
