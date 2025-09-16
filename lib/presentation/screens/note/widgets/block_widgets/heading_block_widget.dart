import 'package:flutter/material.dart';
import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/note_block.dart';
import 'base_block_widget.dart';

class HeadingBlockWidget extends BaseBlockWidget {
  final HeadingBlock block;
  final Function(HeadingBlock) onChanged;

  HeadingBlockWidget({
    super.key,
    required this.block,
    required super.focusNode,
    required this.onChanged,
    required super.onSelectionChanged,
    required super.onTextChange,
  }) : super(blockId: block.id);

  @override
  Widget buildContent(BuildContext context) {
    return _HeadingFieldWidget(
      block: block,
      focusNode: focusNode,
      onChanged: onChanged,
      onSelectionChanged: onSelectionChanged,
      onTextChange: onTextChange,
    );
  }
}

class _HeadingFieldWidget extends StatefulWidget {
  final HeadingBlock block;
  final FocusNode focusNode;
  final Function(HeadingBlock) onChanged;
  final Function(TextSelection) onSelectionChanged;
  final Function(String, String) onTextChange;

  const _HeadingFieldWidget({
    required this.block,
    required this.focusNode,
    required this.onChanged,
    required this.onSelectionChanged,
    required this.onTextChange,
  });

  @override
  State<_HeadingFieldWidget> createState() => _HeadingFieldWidgetState();
}

class _HeadingFieldWidgetState extends State<_HeadingFieldWidget> {
  late TextEditingController _controller;
  bool _isDisposed = false;
  TextDirection _textDirection = TextDirection.ltr;

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
  void didUpdateWidget(_HeadingFieldWidget oldWidget) {
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

    // Check first significant character
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      setState(() => _textDirection = TextDirection.ltr);
      return;
    }

    // Get first actual character (non-space, non-punctuation)
    final firstChar = trimmedText.runes.first;

    // Check if it's a Persian/Arabic character
    final isRTL = _isRTLCharacter(firstChar);

    setState(() {
      _textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;
    });
  }

  // Check if character is Persian/Arabic
  bool _isRTLCharacter(int char) {
    // Persian/Arabic Unicode ranges
    return (char >= 0x0600 && char <= 0x06FF) || // Arabic
        (char >= 0x0750 && char <= 0x077F) || // Arabic Supplement
        (char >= 0xFB50 && char <= 0xFDFF) || // Arabic Presentation Forms
        (char >= 0xFE70 && char <= 0xFEFF); // Arabic Presentation Forms-B
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact level selector
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              textDirection: TextDirection.ltr, // Keep selector always LTR
              children: [
                // Visual heading indicator
                Container(
                  width: 3,
                  height: _getHeadingFontSize(widget.block.level),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.accent,
                        AppColors.accent.withAlpha(100),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Level badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent.withAlpha(20),
                        AppColors.accent.withAlpha(10),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.accent.withAlpha(40),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'H${widget.block.level}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.text_fields,
                        size: 12,
                        color: AppColors.accent.withAlpha(150),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // RTL/LTR indicator
                if (_controller.text.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withAlpha(50),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _textDirection == TextDirection.rtl
                          ? Icons.format_align_right
                          : Icons.format_align_left,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),

                // Level selector buttons
                _buildCompactLevelSelector(),
              ],
            ),
          ),

          // Heading text field with RTL support
          TextField(
            controller: _controller,
            focusNode: widget.focusNode,
            maxLines: null,
            textDirection: _textDirection,
            textAlign:
                _textDirection == TextDirection.rtl
                    ? TextAlign.right
                    : TextAlign.left,
            decoration: InputDecoration(
              hintText: _getPlaceholderText(widget.block.level),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
              hintStyle: TextStyle(
                color: AppColors.textTertiary.withAlpha(100),
                fontSize: _getHeadingFontSize(widget.block.level),
                fontWeight: _getHeadingWeight(widget.block.level),
              ),
            ),
            style: TextStyle(
              fontSize: _getHeadingFontSize(widget.block.level),
              fontWeight: _getHeadingWeight(widget.block.level),
              height: 1.3,
              color: AppColors.textPrimary,
              letterSpacing: widget.block.level <= 2 ? -0.5 : 0,
            ),
            onTap: _onSelectionChanged,
          ),
        ],
      ),
    );
  }

  // Build compact level selector with H1, H2, etc.
  Widget _buildCompactLevelSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(50),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider.withAlpha(30), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(6, (index) {
          final level = index + 1;
          final isSelected = widget.block.level == level;

          return InkWell(
            onTap: () {
              widget.onChanged(widget.block.copyWith(level: level));
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              height: 28,
              constraints: const BoxConstraints(minWidth: 32),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? AppColors.accent.withAlpha(20)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border:
                    isSelected
                        ? Border.all(
                          color: AppColors.accent.withAlpha(40),
                          width: 0.5,
                        )
                        : null,
              ),
              child: Center(
                child: Text(
                  'H$level',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color:
                        isSelected ? AppColors.accent : AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // Get placeholder text based on level (bilingual)
  String _getPlaceholderText(int level) {
    switch (level) {
      case 1:
        return 'Main heading...';
      case 2:
        return 'Section heading...';
      case 3:
        return 'Subsection heading...';
      case 4:
        return 'Paragraph heading...';
      case 5:
        return 'Small heading...';
      case 6:
        return 'Tiny heading...';
      default:
        return 'Heading text...';
    }
  }

  // Get font size for different heading levels
  double _getHeadingFontSize(int level) {
    switch (level) {
      case 1:
        return 28;
      case 2:
        return 24;
      case 3:
        return 20;
      case 4:
        return 18;
      case 5:
        return 16;
      case 6:
        return 14;
      default:
        return 18;
    }
  }

  // Get font weight for different heading levels
  FontWeight _getHeadingWeight(int level) {
    switch (level) {
      case 1:
        return FontWeight.w800;
      case 2:
        return FontWeight.w700;
      case 3:
        return FontWeight.w600;
      case 4:
        return FontWeight.w600;
      case 5:
        return FontWeight.w500;
      case 6:
        return FontWeight.w500;
      default:
        return FontWeight.w600;
    }
  }
}
