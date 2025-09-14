import 'package:flutter/foundation.dart';
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

  // Callout types with their properties
  final Map<String, _CalloutType> _calloutTypes = {
    'info': const _CalloutType(
      'info',
      'Information',
      Icons.info_outline,
      Colors.blue,
    ),
    'warning': const _CalloutType(
      'warning',
      'Warning',
      Icons.warning_amber_outlined,
      Colors.orange,
    ),
    'error': const _CalloutType(
      'error',
      'Error',
      Icons.error_outline,
      Colors.red,
    ),
    'success': const _CalloutType(
      'success',
      'Success',
      Icons.check_circle_outline,
      Colors.green,
    ),
    'tip': const _CalloutType(
      'tip',
      'Tip',
      Icons.lightbulb_outline,
      Colors.purple,
    ),
    'note': const _CalloutType(
      'note',
      'Note',
      Icons.note_outlined,
      Colors.grey,
    ),
  };

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
  void didUpdateWidget(_CalloutFieldWidget oldWidget) {
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
    final calloutType =
        _calloutTypes[widget.block.calloutType] ?? _calloutTypes['info']!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: calloutType.color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: calloutType.color.withAlpha(50), width: 1.5),
      ),
      child: Column(
        children: [
          // Header with type selector
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: calloutType.color.withAlpha(10),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(
                  color: calloutType.color.withAlpha(30),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: calloutType.color.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    calloutType.icon,
                    size: 20,
                    color: calloutType.color,
                  ),
                ),

                const SizedBox(width: 12),

                // Type selector
                Expanded(
                  child: PopupMenuButton<String>(
                    initialValue: widget.block.calloutType,
                    onSelected: (value) {
                      widget.onChanged(
                        widget.block.copyWith(calloutType: value),
                      );
                    },
                    itemBuilder:
                        (context) =>
                            _calloutTypes.entries.map((entry) {
                              final type = entry.value;
                              return PopupMenuItem(
                                value: entry.key,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: type.color.withAlpha(20),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        type.icon,
                                        size: 16,
                                        color: type.color,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      type.name,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight:
                                            widget.block.calloutType ==
                                                    entry.key
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                    child: Row(
                      children: [
                        Text(
                          calloutType.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: calloutType.color,
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 20,
                          color: calloutType.color,
                        ),
                      ],
                    ),
                  ),
                ),

                // Optional emoji selector
                IconButton(
                  onPressed: () => _showEmojiPicker(),
                  icon: const Icon(Icons.emoji_emotions_outlined),
                  iconSize: 20,
                  color: AppColors.textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  tooltip: 'Add emoji',
                ),
              ],
            ),
          ),

          // Content area
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              focusNode: widget.focusNode,
              maxLines: null,
              enableInteractiveSelection: true,
              selectionControls: _CustomTextSelectionControls(),
              decoration: const InputDecoration(
                hintText: 'Add your message...',
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
            ),
          ),
        ],
      ),
    );
  }

  // Show emoji picker (simplified)
  void _showEmojiPicker() {
    final emojis = ['💡', '⚠️', '❌', '✅', '📌', '🔥', '⭐', '🚀', '💭', '📝'];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choose an emoji',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children:
                      emojis
                          .map(
                            (emoji) => GestureDetector(
                              onTap: () {
                                // Insert emoji at cursor position
                                final selection = _controller.selection;
                                final newText = _controller.text.replaceRange(
                                  selection.start,
                                  selection.end,
                                  emoji,
                                );
                                _controller.text = newText;
                                _controller.selection = TextSelection.collapsed(
                                  offset: selection.start + emoji.length,
                                );
                                Navigator.pop(context);
                              },
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
              ],
            ),
          ),
    );
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

// Custom selection controls
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
