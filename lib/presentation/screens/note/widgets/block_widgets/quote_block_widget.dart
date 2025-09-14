import 'package:flutter/foundation.dart';
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
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.text);
    _controller.addListener(_onTextChanged);
    _controller.addListener(_onSelectionChanged);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_QuoteFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.text != widget.block.text && !_isDisposed) {
      if (_controller.text != widget.block.text) {
        _controller.text = widget.block.text;
      }
    }
  }

  void _onTextChanged() {
    if (_isDisposed) return;

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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quote decoration bar
          Container(
            width: 4,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Quote content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quote icon
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Icon(
                    Icons.format_quote,
                    size: 24,
                    color: AppColors.accent.withAlpha(150),
                  ),
                ),

                // Quote text field
                TextField(
                  controller: _controller,
                  focusNode: widget.focusNode,
                  maxLines: null,
                  enableInteractiveSelection: true,
                  selectionControls: _CustomTextSelectionControls(),
                  decoration: const InputDecoration(
                    hintText: 'Add a quote...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    hintStyle: TextStyle(
                      color: Color(0xFF48484A),
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Color(0xFFFFFFFF),
                    fontStyle: FontStyle.italic,
                  ),
                  onTap: _onSelectionChanged,
                ),

                // Optional author field
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Author (optional)',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                            hintStyle: TextStyle(
                              color: Color(0xFF48484A),
                              fontSize: 14,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          onChanged: (author) {
                            // Store author in block metadata if needed
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
    );
  }
}

// Custom selection controls to hide system menu
class _CustomTextSelectionControls extends MaterialTextSelectionControls {
  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ValueListenable<ClipboardStatus>? clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) {
    return const SizedBox.shrink();
  }
}
