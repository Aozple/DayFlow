import 'package:flutter/material.dart';
import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/note_block.dart';
import 'base_block_widget.dart';
import 'markdown_text_widget.dart';

class TextBlockWidget extends BaseBlockWidget {
  final TextBlock block;
  final Function(TextBlock) onChanged;

  TextBlockWidget({
    super.key,
    required this.block,
    required super.focusNode,
    required this.onChanged,
    required super.onSelectionChanged,
    required super.onTextChange,
  }) : super(blockId: block.id);

  @override
  Widget buildContent(BuildContext context) {
    return _TextFieldWidget(
      block: block,
      focusNode: focusNode,
      onChanged: onChanged,
      onSelectionChanged: onSelectionChanged,
      onTextChange: onTextChange,
    );
  }
}

class _TextFieldWidget extends StatefulWidget {
  final TextBlock block;
  final FocusNode focusNode;
  final Function(TextBlock) onChanged;
  final Function(TextSelection) onSelectionChanged;
  final Function(String, String) onTextChange;

  const _TextFieldWidget({
    required this.block,
    required this.focusNode,
    required this.onChanged,
    required this.onSelectionChanged,
    required this.onTextChange,
  });

  @override
  State<_TextFieldWidget> createState() => _TextFieldWidgetState();
}

class _TextFieldWidgetState extends State<_TextFieldWidget> {
  late TextEditingController _controller;
  bool _isDisposed = false;
  bool _isEditing = false;
  bool _hasMarkdown = false;
  TextDirection _textDirection = TextDirection.ltr;
  bool _showFormatHint = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.text);
    _controller.addListener(_onTextChanged);
    _controller.addListener(_onSelectionChanged);

    // Listen to focus changes
    widget.focusNode.addListener(_onFocusChange);

    // Initial checks
    _checkForMarkdown();
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
  void didUpdateWidget(_TextFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.text != widget.block.text && !_isDisposed) {
      if (_controller.text != widget.block.text) {
        _controller.text = widget.block.text;
        _checkForMarkdown();
        _updateTextDirection(widget.block.text);
      }
    }
  }

  // Check if text contains markdown formatting
  void _checkForMarkdown() {
    final text = widget.block.text;
    setState(() {
      _hasMarkdown =
          text.contains('**') ||
          text.contains('*') ||
          text.contains('<u>') ||
          text.contains('~~') ||
          text.contains('`') ||
          text.contains('[') ||
          text.contains('](');
    });
  }

  // Smart RTL/LTR detection
  void _updateTextDirection(String text) {
    if (text.isEmpty) {
      setState(() => _textDirection = TextDirection.ltr);
      return;
    }

    // Get first non-whitespace, non-markdown character
    final cleanText = _stripMarkdown(text).trim();
    if (cleanText.isEmpty) {
      setState(() => _textDirection = TextDirection.ltr);
      return;
    }

    final firstChar = cleanText.runes.first;
    final isRTL = _isRTLCharacter(firstChar);

    setState(() {
      _textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;
    });
  }

  // Strip markdown for direction detection
  String _stripMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'\*{1,3}'), '')
        .replaceAll(RegExp(r'`{1,3}'), '')
        .replaceAll(RegExp(r'~~'), '')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll(
          RegExp(r'```math|```|KATEX_INLINE_OPEN|KATEX_INLINE_CLOSE'),
          '',
        );
  }

  // Check if character is RTL (Arabic/Persian/Hebrew)
  bool _isRTLCharacter(int char) {
    return (char >= 0x0600 && char <= 0x06FF) || // Arabic
        (char >= 0x0750 && char <= 0x077F) || // Arabic Supplement
        (char >= 0xFB50 && char <= 0xFDFF) || // Arabic Presentation Forms
        (char >= 0xFE70 && char <= 0xFEFF) || // Arabic Presentation Forms-B
        (char >= 0x0590 && char <= 0x05FF); // Hebrew
  }

  void _onFocusChange() {
    if (!_isDisposed && mounted) {
      setState(() {
        _isEditing = widget.focusNode.hasFocus;
        if (_isEditing) {
          _showFormatHint = true;
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => _showFormatHint = false);
          });
        }
      });
    }
  }

  void _onTextChanged() {
    if (_isDisposed) return;

    _checkForMarkdown();
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Format indicators bar
          if (_isEditing || _hasMarkdown || _controller.text.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  // Markdown indicator
                  if (_hasMarkdown)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent.withAlpha(20),
                            AppColors.accent.withAlpha(10),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.accent.withAlpha(40),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_fix_high,
                            size: 11,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Markdown',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Spacer(),

                  // Text direction indicator
                  if (_controller.text.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withAlpha(50),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.divider.withAlpha(30),
                          width: 0.5,
                        ),
                      ),
                      child: Icon(
                        _textDirection == TextDirection.rtl
                            ? Icons.format_align_right
                            : Icons.format_align_left,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),

                  // Format hint
                  if (_showFormatHint && _isEditing)
                    AnimatedOpacity(
                      opacity: _showFormatHint ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withAlpha(80),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '**bold** *italic* `code`',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Main content area
          Stack(
            children: [
              // Rendered markdown view when not editing
              if (!_isEditing && _hasMarkdown && widget.block.text.isNotEmpty)
                _buildRenderedText(),

              // Editable text field
              AnimatedOpacity(
                opacity:
                    (!_isEditing &&
                            _hasMarkdown &&
                            widget.block.text.isNotEmpty)
                        ? 0.0
                        : 1.0,
                duration: const Duration(milliseconds: 200),
                child: _buildEditableField(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build editable text field with RTL support
  Widget _buildEditableField() {
    return TextField(
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
    );
  }

  // Build rendered markdown text with RTL support
  Widget _buildRenderedText() {
    return GestureDetector(
      onTap: () {
        setState(() => _isEditing = true);
        widget.focusNode.requestFocus();
      },
      behavior: HitTestBehavior.translucent,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 26),
        padding: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.surface.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.divider.withAlpha(20),
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Directionality(
            textDirection: _textDirection,
            child: MarkdownTextWidget(
              text: widget.block.text,
              baseStyle: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: AppColors.textPrimary,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Get bilingual placeholder text
  String _getPlaceholderText() {
    if (_textDirection == TextDirection.rtl) {
      return 'اینجا تایپ کنید...';
    }
    return 'Type something...';
  }
}
