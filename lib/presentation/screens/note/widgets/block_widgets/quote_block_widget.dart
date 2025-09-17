import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/note_block.dart';
import 'base_block_widget.dart';

class QuoteBlockWidget extends BaseBlockWidget {
  final QuoteBlock block;
  final Function(QuoteBlock) onChanged;

  QuoteBlockWidget({
    super.key,
    required this.block,
    required super.focusNode,
    required this.onChanged,
    required super.onSelectionChanged,
    required super.onTextChange,
  }) : super(blockId: block.id);

  @override
  Widget buildContent(BuildContext context) {
    return _QuoteFieldWidget(
      block: block,
      focusNode: focusNode,
      onChanged: onChanged,
      onSelectionChanged: onSelectionChanged,
      onTextChange: onTextChange,
    );
  }
}

class _QuoteFieldWidget extends StatefulWidget {
  final QuoteBlock block;
  final FocusNode focusNode;
  final Function(QuoteBlock) onChanged;
  final Function(TextSelection) onSelectionChanged;
  final Function(String, String) onTextChange;

  const _QuoteFieldWidget({
    required this.block,
    required this.focusNode,
    required this.onChanged,
    required this.onSelectionChanged,
    required this.onTextChange,
  });

  @override
  State<_QuoteFieldWidget> createState() => _QuoteFieldWidgetState();
}

class _QuoteFieldWidgetState extends State<_QuoteFieldWidget> {
  late TextEditingController _controller;
  late TextEditingController _authorController;
  bool _isDisposed = false;
  bool _isEditing = false;
  TextDirection _textDirection = TextDirection.ltr;
  Timer? _directionTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.text);
    _authorController = TextEditingController();
    _controller.addListener(_onTextChanged);
    _controller.addListener(_onSelectionChanged);

    // Listen to focus changes for editing state
    widget.focusNode.addListener(_onFocusChange);

    // Set initial text direction
    _updateTextDirection(widget.block.text);
  }

  @override
  void dispose() {
    _directionTimer?.cancel();
    _isDisposed = true;
    widget.focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _authorController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_QuoteFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.text != widget.block.text && !_isDisposed) {
      if (_controller.text != widget.block.text) {
        _controller.text = widget.block.text;
        _updateTextDirection(widget.block.text);
      }
    }
  }

  // Detect text direction based on first character
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

    // Only update if direction actually changed to prevent unnecessary rebuilds
    if (_textDirection != newDirection) {
      setState(() {
        _textDirection = newDirection;
      });
    }
  }

  // Strip markdown and formatting for direction detection
  String _stripMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'\*{1,3}'), '')
        .replaceAll(RegExp(r'`{1,3}'), '')
        .replaceAll(RegExp(r'~~'), '')
        .replaceAll(RegExp(r'<[^>]+>'), '');
  }

  // Check if character belongs to RTL script (Arabic/Persian/Hebrew)
  bool _isRTLCharacter(int char) {
    return (char >= 0x0600 && char <= 0x06FF) || // Arabic
        (char >= 0x0750 && char <= 0x077F) || // Arabic Supplement
        (char >= 0xFB50 && char <= 0xFDFF) || // Arabic Presentation Forms A
        (char >= 0xFE70 && char <= 0xFEFF) || // Arabic Presentation Forms B
        (char >= 0x0590 && char <= 0x05FF); // Hebrew
  }

  // Handle focus state changes
  void _onFocusChange() {
    if (!_isDisposed && mounted) {
      setState(() {
        _isEditing = widget.focusNode.hasFocus;
      });
    }
  }

  // Handle text content changes
  void _onTextChanged() {
    if (_isDisposed) return;

    // Update direction without interrupting typing
    _updateTextDirection(_controller.text);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        widget.onChanged(widget.block.copyWith(text: _controller.text));
        widget.onTextChange(_controller.text, widget.block.id);
      }
    });
  }

  // Handle text selection changes
  void _onSelectionChanged() {
    if (_isDisposed || !mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        widget.onSelectionChanged(_controller.selection);
      }
    });
  }

  // Get placeholder text based on current direction
  String _getPlaceholderText() {
    if (_textDirection == TextDirection.rtl) {
      return 'نقل قول اضافه کنید...';
    }
    return 'Add a quote...';
  }

  // Get author placeholder text based on current direction
  String _getAuthorPlaceholder() {
    if (_textDirection == TextDirection.rtl) {
      return 'نویسنده (اختیاری)';
    }
    return 'Author (optional)';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status indicators bar - shown when editing or has content
          if (_isEditing || _controller.text.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  // Quote type indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withAlpha(20),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.purple.withAlpha(40),
                        width: 0.5,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.format_quote,
                          size: 10,
                          color: Colors.purple,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Quote',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Text direction indicator
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

          // Main quote content area with fixed structure
          Directionality(
            textDirection: _textDirection,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quote bar - automatically appears on correct side
                Container(
                  width: 3,
                  height: 24,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                const SizedBox(width: 8),

                // Text content area
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main quote text field
                      TextField(
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
                          hintText: _getPlaceholderText(),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                          hintStyle: TextStyle(
                            color: AppColors.textTertiary.withAlpha(100),
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: AppColors.textPrimary,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.1,
                        ),
                        onTap: _onSelectionChanged,
                      ),

                      // Optional author field - only shown when quote has content
                      if (_controller.text.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              // Icon - always on the correct side based on direction
                              const Icon(
                                Icons.person_outline,
                                size: 14,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: 6),

                              // Text field
                              Expanded(
                                child: TextField(
                                  controller: _authorController,
                                  textDirection: _textDirection,
                                  textAlign:
                                      _textDirection == TextDirection.rtl
                                          ? TextAlign.right
                                          : TextAlign.left,
                                  selectionControls:
                                      EmptyTextSelectionControls(),
                                  decoration: InputDecoration(
                                    hintText: _getAuthorPlaceholder(),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                    hintStyle: TextStyle(
                                      color: AppColors.textTertiary.withAlpha(
                                        100,
                                      ),
                                      fontSize: 13,
                                    ),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    letterSpacing: 0.1,
                                  ),
                                  onChanged: (author) {
                                    // TODO: Store author in block metadata if needed
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
