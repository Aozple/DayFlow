import 'package:flutter/foundation.dart';
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
  void didUpdateWidget(_HeadingFieldWidget oldWidget) {
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced level selector with visual indicators
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                // Current level indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.accent.withAlpha(50),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'H${widget.block.level}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Level size preview
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    _getLevelDescription(widget.block.level),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),

                const Spacer(),

                // Level selector
                _buildLevelSelector(),
              ],
            ),
          ),

          // Heading text field with dynamic sizing
          TextField(
            controller: _controller,
            focusNode: widget.focusNode,
            maxLines: null,
            enableInteractiveSelection: true,
            selectionControls: _CustomTextSelectionControls(),
            decoration: const InputDecoration(
              hintText: 'Heading text...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
              hintStyle: TextStyle(color: Color(0xFF48484A)),
            ),
            style: TextStyle(
              fontSize: _getHeadingFontSize(widget.block.level),
              fontWeight: FontWeight.bold,
              height: 1.3,
              color: AppColors.textPrimary,
            ),
            onTap: _onSelectionChanged,
          ),
        ],
      ),
    );
  }

  // Build enhanced level selector with preview
  Widget _buildLevelSelector() {
    return PopupMenuButton<int>(
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight.withAlpha(50),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.tune, size: 16, color: AppColors.textTertiary),
      ),
      onSelected: (level) {
        widget.onChanged(widget.block.copyWith(level: level));
      },
      itemBuilder:
          (context) => List.generate(6, (index) {
            final level = index + 1;
            return PopupMenuItem(
              value: level,
              child: Row(
                children: [
                  Text(
                    'H$level',
                    style: TextStyle(
                      fontSize: _getHeadingFontSize(level) * 0.7,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getLevelDescription(level),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            );
          }),
    );
  }

  // Get description for heading levels
  String _getLevelDescription(int level) {
    switch (level) {
      case 1:
        return 'Very Large';
      case 2:
        return 'Large';
      case 3:
        return 'Medium';
      case 4:
        return 'Small';
      case 5:
        return 'Very Small';
      case 6:
        return 'Tiny';
      default:
        return 'Medium';
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
