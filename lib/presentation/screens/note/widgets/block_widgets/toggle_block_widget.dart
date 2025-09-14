import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/note_block.dart';
import 'base_block_widget.dart';

class ToggleBlockWidget extends BaseBlockWidget {
  final ToggleBlock block;
  final Function(ToggleBlock) onChanged;

  ToggleBlockWidget({
    super.key,
    required this.block,
    required super.focusNode,
    required this.onChanged,
    required super.onSelectionChanged,
    required super.onTextChange,
  }) : super(blockId: block.id);

  @override
  Widget buildContent(BuildContext context) {
    return _ToggleFieldWidget(
      block: block,
      focusNode: focusNode,
      onChanged: onChanged,
      onSelectionChanged: onSelectionChanged,
      onTextChange: onTextChange,
    );
  }
}

class _ToggleFieldWidget extends StatefulWidget {
  final ToggleBlock block;
  final FocusNode focusNode;
  final Function(ToggleBlock) onChanged;
  final Function(TextSelection) onSelectionChanged;
  final Function(String, String) onTextChange;

  const _ToggleFieldWidget({
    required this.block,
    required this.focusNode,
    required this.onChanged,
    required this.onSelectionChanged,
    required this.onTextChange,
  });

  @override
  State<_ToggleFieldWidget> createState() => _ToggleFieldWidgetState();
}

class _ToggleFieldWidgetState extends State<_ToggleFieldWidget>
    with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;
  bool _isDisposed = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.block.title);
    _titleController.addListener(_onTitleChanged);
    _titleController.addListener(_onSelectionChanged);

    _isExpanded = widget.block.isExpanded;

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 0.25, // 90 degrees
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _titleController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_ToggleFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.title != widget.block.title && !_isDisposed) {
      if (_titleController.text != widget.block.title) {
        _titleController.text = widget.block.title;
      }
    }
    if (oldWidget.block.isExpanded != widget.block.isExpanded) {
      _isExpanded = widget.block.isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  void _onTitleChanged() {
    if (_isDisposed) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        widget.onChanged(widget.block.copyWith(title: _titleController.text));
        widget.onTextChange(_titleController.text, widget.block.id);
      }
    });
  }

  void _onSelectionChanged() {
    if (_isDisposed || !mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        widget.onSelectionChanged(_titleController.selection);
      }
    });
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }

    widget.onChanged(widget.block.copyWith(isExpanded: _isExpanded));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withAlpha(30), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle header
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withAlpha(30),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(12),
                  bottom: Radius.circular(_isExpanded ? 0 : 12),
                ),
              ),
              child: Row(
                children: [
                  // Rotating arrow icon
                  RotationTransition(
                    turns: _rotateAnimation,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_right,
                        size: 18,
                        color: AppColors.accent,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Title field
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Prevent toggle when clicking on text field
                        widget.focusNode.requestFocus();
                        _onSelectionChanged();
                      },
                      child: AbsorbPointer(
                        absorbing: false,
                        child: TextField(
                          controller: _titleController,
                          focusNode: widget.focusNode,
                          maxLines: 1,
                          enableInteractiveSelection: true,
                          selectionControls: _CustomTextSelectionControls(),
                          decoration: const InputDecoration(
                            hintText: 'Toggle title...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                            hintStyle: TextStyle(
                              color: Color(0xFF48484A),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFFFFFF),
                          ),
                          onTap: () {
                            _onSelectionChanged();
                          },
                        ),
                      ),
                    ),
                  ),

                  // Child count indicator
                  if (widget.block.children.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.divider.withAlpha(50),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${widget.block.children.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Expandable content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.divider.withAlpha(30),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Child blocks (simplified for now)
                  if (widget.block.children.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.layers_clear,
                              size: 32,
                              color: AppColors.textTertiary.withAlpha(100),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'No content yet',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () {
                                // Add child block functionality
                                _addChildBlock();
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add content'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    // Display child blocks
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          ...widget.block.children.map(
                            (child) => _buildChildBlock(child),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _addChildBlock,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add block'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build child block widget (simplified version)
  Widget _buildChildBlock(NoteBlock child) {
    if (child is TextBlock) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background.withAlpha(50),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider.withAlpha(20), width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: TextEditingController(text: child.text),
                onChanged: (value) {
                  _updateChildBlock(child.id, child.copyWith(text: value));
                },
                decoration: const InputDecoration(
                  hintText: 'Type something...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _removeChildBlock(child.id),
              icon: const Icon(Icons.close, size: 16),
              color: AppColors.textTertiary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
          ],
        ),
      );
    }

    // For other block types, show a placeholder
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background.withAlpha(50),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${child.type.name} block',
        style: const TextStyle(fontSize: 14, color: AppColors.textTertiary),
      ),
    );
  }

  // Add new child block
  void _addChildBlock() {
    final newChild = TextBlock(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: '',
    );

    final newChildren = List<NoteBlock>.from(widget.block.children)
      ..add(newChild);
    widget.onChanged(widget.block.copyWith(children: newChildren));
  }

  // Update child block
  void _updateChildBlock(String childId, NoteBlock updatedChild) {
    final newChildren =
        widget.block.children.map((child) {
          return child.id == childId ? updatedChild : child;
        }).toList();

    widget.onChanged(widget.block.copyWith(children: newChildren));
  }

  // Remove child block
  void _removeChildBlock(String childId) {
    final newChildren =
        widget.block.children.where((child) => child.id != childId).toList();

    widget.onChanged(widget.block.copyWith(children: newChildren));
  }
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
