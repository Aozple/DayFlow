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
  bool _isEditing = false;
  TextDirection _textDirection = TextDirection.ltr;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.text);
    _controller.addListener(_onTextChanged);
    _controller.addListener(_onSelectionChanged);

    widget.focusNode.addListener(_onFocusChange);

    _updateTextDirection(widget.block.text);
  }

  @override
  void dispose() {
    _isDisposed = true;
    widget.focusNode.removeListener(_onFocusChange);
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

  void _onFocusChange() {
    if (!_isDisposed && mounted) {
      setState(() {
        _isEditing = widget.focusNode.hasFocus;
      });
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

  void _updateTextDirection(String text) {
    if (text.isEmpty) {
      setState(() => _textDirection = TextDirection.ltr);
      return;
    }

    final cleanText = _stripMarkdown(text).trim();
    if (cleanText.isEmpty) {
      setState(() => _textDirection = TextDirection.ltr);
      return;
    }

    final firstChar = cleanText.runes.first;
    final isRTL = _isRTLCharacter(firstChar);
    final newDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    if (_textDirection != newDirection) {
      setState(() {
        _textDirection = newDirection;
      });
    }
  }

  String _stripMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'\*{1,3}'), '')
        .replaceAll(RegExp(r'`{1,3}'), '')
        .replaceAll(RegExp(r'~~'), '')
        .replaceAll(RegExp(r'<[^>]+>'), '');
  }

  bool _isRTLCharacter(int char) {
    return (char >= 0x0600 && char <= 0x06FF) ||
        (char >= 0x0750 && char <= 0x077F) ||
        (char >= 0xFB50 && char <= 0xFDFF) ||
        (char >= 0xFE70 && char <= 0xFEFF) ||
        (char >= 0x0590 && char <= 0x05FF);
  }

  String _getPlaceholderText(int level) {
    if (_textDirection == TextDirection.rtl) {
      return _getRTLPlaceholder(level);
    }
    return _getLTRPlaceholder(level);
  }

  String _getLTRPlaceholder(int level) {
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

  String _getRTLPlaceholder(int level) {
    switch (level) {
      case 1:
        return 'عنوان اصلی...';
      case 2:
        return 'عنوان بخش...';
      case 3:
        return 'عنوان زیربخش...';
      case 4:
        return 'عنوان پاراگراف...';
      case 5:
        return 'عنوان کوچک...';
      case 6:
        return 'عنوان ریز...';
      default:
        return 'متن عنوان...';
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isEditing || _controller.text.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(20),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppColors.accent.withAlpha(40),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.title, size: 10, color: AppColors.accent),
                        const SizedBox(width: 3),
                        Text(
                          'H${widget.block.level}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  _buildCompactLevelSelector(),

                  const Spacer(),

                  if (_controller.text.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withAlpha(50),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.divider.withAlpha(30),
                          width: 0.5,
                        ),
                      ),
                      child: Icon(
                        _textDirection == TextDirection.rtl
                            ? Icons.format_align_right
                            : Icons.format_align_left,
                        size: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),

          Directionality(
            textDirection: _textDirection,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 3,
                  height: _getHeadingFontSize(widget.block.level),
                  margin: const EdgeInsets.only(top: 2),
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

                const SizedBox(width: 8),

                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: widget.focusNode,
                    maxLines: null,
                    textDirection: _textDirection,
                    textAlign:
                        _textDirection == TextDirection.rtl
                            ? TextAlign.right
                            : TextAlign.left,
                    enableInteractiveSelection: true,
                    selectionControls: EmptyTextSelectionControls(),
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
                      letterSpacing: widget.block.level <= 2 ? -0.5 : 0.1,
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              height: 22,
              constraints: const BoxConstraints(minWidth: 36),
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
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color:
                        isSelected ? AppColors.accent : AppColors.textSecondary,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
