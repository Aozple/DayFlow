import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.text);
    _controller.addListener(_onTextChanged);
    _controller.addListener(_onSelectionChanged);

    // Listen to focus changes for better UX
    widget.focusNode.addListener(_onFocusChange);

    // Check if text contains markdown
    _checkForMarkdown();
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
      }
    }
  }

  // Check if text contains markdown formatting
  void _checkForMarkdown() {
    final text = widget.block.text;
    _hasMarkdown =
        text.contains('**') ||
        text.contains('*') ||
        text.contains('<u>') ||
        text.contains('~~') ||
        text.contains('`');
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

    _checkForMarkdown();

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Stack(
        children: [
          // Rendered markdown view when not editing
          if (!_isEditing && _hasMarkdown && widget.block.text.isNotEmpty)
            _buildRenderedText(),

          // Editable text field
          Opacity(
            opacity:
                (!_isEditing && _hasMarkdown && widget.block.text.isNotEmpty)
                    ? 0.0
                    : 1.0,
            child: _buildEditableField(),
          ),
        ],
      ),
    );
  }

  // Build editable text field
  Widget _buildEditableField() {
    return TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      maxLines: null,
      enableInteractiveSelection: true,
      selectionControls: _CustomTextSelectionControls(),
      decoration: const InputDecoration(
        hintText: 'Type something ...',
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
        hintStyle: TextStyle(color: Color(0xFF48484A), fontSize: 16),
      ),
      style: const TextStyle(
        fontSize: 16,
        height: 1.6,
        color: Color(0xFFFFFFFF),
      ),
      onTap: _onSelectionChanged,
    );
  }

  // Build rendered markdown text
  Widget _buildRenderedText() {
    return GestureDetector(
      onTap: () {
        // Switch to edit mode when tapped
        setState(() {
          _isEditing = true;
        });
        widget.focusNode.requestFocus();
      },
      behavior: HitTestBehavior.translucent,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 24),
        child: MarkdownTextWidget(
          text: widget.block.text,
          baseStyle: const TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Color(0xFFFFFFFF),
          ),
        ),
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
