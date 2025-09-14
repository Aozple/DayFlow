import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/note_block.dart';
import 'base_block_widget.dart';

// Bullet List Block Widget
class BulletListBlockWidget extends BaseBlockWidget {
  final BulletListBlock block;
  final Function(BulletListBlock) onChanged;

  BulletListBlockWidget({
    super.key,
    required this.block,
    required super.focusNode,
    required this.onChanged,
    required super.onSelectionChanged,
    required super.onTextChange,
  }) : super(blockId: block.id);

  @override
  Widget buildContent(BuildContext context) {
    return _BulletListWidget(
      block: block,
      focusNode: focusNode,
      onChanged: onChanged,
      onSelectionChanged: onSelectionChanged,
      onTextChange: onTextChange,
    );
  }
}

// Numbered List Block Widget
class NumberedListBlockWidget extends BaseBlockWidget {
  final NumberedListBlock block;
  final Function(NumberedListBlock) onChanged;

  NumberedListBlockWidget({
    super.key,
    required this.block,
    required super.focusNode,
    required this.onChanged,
    required super.onSelectionChanged,
    required super.onTextChange,
  }) : super(blockId: block.id);

  @override
  Widget buildContent(BuildContext context) {
    return _NumberedListWidget(
      block: block,
      focusNode: focusNode,
      onChanged: onChanged,
      onSelectionChanged: onSelectionChanged,
      onTextChange: onTextChange,
    );
  }
}

// Todo List Block Widget
class TodoListBlockWidget extends BaseBlockWidget {
  final TodoListBlock block;
  final Function(TodoListBlock) onChanged;

  TodoListBlockWidget({
    super.key,
    required this.block,
    required super.focusNode,
    required this.onChanged,
    required super.onSelectionChanged,
    required super.onTextChange,
  }) : super(blockId: block.id);

  @override
  Widget buildContent(BuildContext context) {
    return _TodoListWidget(
      block: block,
      focusNode: focusNode,
      onChanged: onChanged,
      onSelectionChanged: onSelectionChanged,
      onTextChange: onTextChange,
    );
  }
}

// Bullet List Implementation
class _BulletListWidget extends StatefulWidget {
  final BulletListBlock block;
  final FocusNode focusNode;
  final Function(BulletListBlock) onChanged;
  final Function(TextSelection) onSelectionChanged;
  final Function(String, String) onTextChange;

  const _BulletListWidget({
    required this.block,
    required this.focusNode,
    required this.onChanged,
    required this.onSelectionChanged,
    required this.onTextChange,
  });

  @override
  State<_BulletListWidget> createState() => _BulletListWidgetState();
}

class _BulletListWidgetState extends State<_BulletListWidget> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Ensure we have valid items
    final items = widget.block.items.isEmpty ? [''] : widget.block.items;

    _controllers =
        items.map((item) => TextEditingController(text: item)).toList();
    _focusNodes = items.map((_) => FocusNode()).toList();

    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].addListener(() => _onItemChanged(i));
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(_BulletListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.items.length != widget.block.items.length) {
      // Items count changed, rebuild controllers
      for (final controller in _controllers) {
        controller.dispose();
      }
      for (final focusNode in _focusNodes) {
        focusNode.dispose();
      }
      _initializeControllers();
      setState(() {});
    }
  }

  void _onItemChanged(int index) {
    if (index >= widget.block.items.length) return;

    final newItems = List<String>.from(widget.block.items);
    if (index < newItems.length) {
      newItems[index] = _controllers[index].text;
      widget.onChanged(widget.block.copyWith(items: newItems));
      widget.onTextChange(_controllers[index].text, widget.block.id);
    }
  }

  void _addItem() {
    final newItems = List<String>.from(widget.block.items);
    newItems.add('');
    widget.onChanged(widget.block.copyWith(items: newItems));
  }

  void _removeItem(int index) {
    if (widget.block.items.length <= 1) return;
    final newItems = List<String>.from(widget.block.items);
    if (index < newItems.length) {
      newItems.removeAt(index);
      widget.onChanged(widget.block.copyWith(items: newItems));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // List items
          for (int i = 0; i < widget.block.items.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bullet point
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(top: 12),
                    child: const Text(
                      '•',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Text field
                  Expanded(
                    child: TextField(
                      controller:
                          i < _controllers.length ? _controllers[i] : null,
                      focusNode:
                          i == 0
                              ? widget.focusNode
                              : (i < _focusNodes.length
                                  ? _focusNodes[i]
                                  : null),
                      maxLines: null,
                      enableInteractiveSelection: true,
                      selectionControls: _CustomTextSelectionControls(),
                      decoration: const InputDecoration(
                        hintText: 'List item...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                        isDense: true,
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: AppColors.textPrimary,
                      ),
                      onTap: () {
                        if (i < _controllers.length) {
                          widget.onSelectionChanged(_controllers[i].selection);
                        }
                      },
                    ),
                  ),

                  // Remove button (only show if more than 1 item)
                  if (widget.block.items.length > 1)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      child: IconButton(
                        onPressed: () => _removeItem(i),
                        icon: const Icon(Icons.close, size: 16),
                        color: AppColors.textTertiary,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Add item button
          Container(
            margin: const EdgeInsets.only(top: 8, left: 32),
            child: TextButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add item'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textTertiary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Numbered List Implementation
class _NumberedListWidget extends StatefulWidget {
  final NumberedListBlock block;
  final FocusNode focusNode;
  final Function(NumberedListBlock) onChanged;
  final Function(TextSelection) onSelectionChanged;
  final Function(String, String) onTextChange;

  const _NumberedListWidget({
    required this.block,
    required this.focusNode,
    required this.onChanged,
    required this.onSelectionChanged,
    required this.onTextChange,
  });

  @override
  State<_NumberedListWidget> createState() => _NumberedListWidgetState();
}

class _NumberedListWidgetState extends State<_NumberedListWidget> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final items = widget.block.items.isEmpty ? [''] : widget.block.items;

    _controllers =
        items.map((item) => TextEditingController(text: item)).toList();
    _focusNodes = items.map((_) => FocusNode()).toList();

    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].addListener(() => _onItemChanged(i));
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(_NumberedListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.items.length != widget.block.items.length) {
      for (final controller in _controllers) {
        controller.dispose();
      }
      for (final focusNode in _focusNodes) {
        focusNode.dispose();
      }
      _initializeControllers();
      setState(() {});
    }
  }

  void _onItemChanged(int index) {
    if (index >= widget.block.items.length) return;

    final newItems = List<String>.from(widget.block.items);
    if (index < newItems.length) {
      newItems[index] = _controllers[index].text;
      widget.onChanged(widget.block.copyWith(items: newItems));
      widget.onTextChange(_controllers[index].text, widget.block.id);
    }
  }

  void _addItem() {
    final newItems = List<String>.from(widget.block.items);
    newItems.add('');
    widget.onChanged(widget.block.copyWith(items: newItems));
  }

  void _removeItem(int index) {
    if (widget.block.items.length <= 1) return;
    final newItems = List<String>.from(widget.block.items);
    if (index < newItems.length) {
      newItems.removeAt(index);
      widget.onChanged(widget.block.copyWith(items: newItems));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < widget.block.items.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Number
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(top: 12),
                    child: Text(
                      '${i + 1}.',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: TextField(
                      controller:
                          i < _controllers.length ? _controllers[i] : null,
                      focusNode:
                          i == 0
                              ? widget.focusNode
                              : (i < _focusNodes.length
                                  ? _focusNodes[i]
                                  : null),
                      maxLines: null,
                      enableInteractiveSelection: true,
                      selectionControls: _CustomTextSelectionControls(),
                      decoration: const InputDecoration(
                        hintText: 'List item...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                        isDense: true,
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: AppColors.textPrimary,
                      ),
                      onTap: () {
                        if (i < _controllers.length) {
                          widget.onSelectionChanged(_controllers[i].selection);
                        }
                      },
                    ),
                  ),

                  if (widget.block.items.length > 1)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      child: IconButton(
                        onPressed: () => _removeItem(i),
                        icon: const Icon(Icons.close, size: 16),
                        color: AppColors.textTertiary,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          Container(
            margin: const EdgeInsets.only(top: 8, left: 32),
            child: TextButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add item'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textTertiary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Todo List Implementation - Fixed the range error
class _TodoListWidget extends StatefulWidget {
  final TodoListBlock block;
  final FocusNode focusNode;
  final Function(TodoListBlock) onChanged;
  final Function(TextSelection) onSelectionChanged;
  final Function(String, String) onTextChange;

  const _TodoListWidget({
    required this.block,
    required this.focusNode,
    required this.onChanged,
    required this.onSelectionChanged,
    required this.onTextChange,
  });

  @override
  State<_TodoListWidget> createState() => _TodoListWidgetState();
}

class _TodoListWidgetState extends State<_TodoListWidget> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Ensure items and checked arrays are properly sized
    final items = widget.block.items.isEmpty ? [''] : widget.block.items;
    final checked =
        widget.block.checked.isEmpty
            ? List.filled(items.length, false)
            : widget.block.checked;

    // Fix checked array length if needed
    final fixedChecked = List<bool>.filled(items.length, false);
    for (int i = 0; i < checked.length && i < items.length; i++) {
      fixedChecked[i] = checked[i];
    }

    // Update block if arrays were fixed
    if (checked.length != items.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onChanged(
          widget.block.copyWith(items: items, checked: fixedChecked),
        );
      });
    }

    _controllers =
        items.map((item) => TextEditingController(text: item)).toList();
    _focusNodes = items.map((_) => FocusNode()).toList();

    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].addListener(() => _onItemChanged(i));
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(_TodoListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.items.length != widget.block.items.length ||
        oldWidget.block.checked.length != widget.block.checked.length) {
      for (final controller in _controllers) {
        controller.dispose();
      }
      for (final focusNode in _focusNodes) {
        focusNode.dispose();
      }
      _initializeControllers();
      setState(() {});
    }
  }

  void _onItemChanged(int index) {
    if (index >= widget.block.items.length) return;

    final newItems = List<String>.from(widget.block.items);
    if (index < newItems.length) {
      newItems[index] = _controllers[index].text;
      widget.onChanged(widget.block.copyWith(items: newItems));
      widget.onTextChange(_controllers[index].text, widget.block.id);
    }
  }

  void _toggleChecked(int index) {
    if (index >= widget.block.checked.length) return;

    final newChecked = List<bool>.from(widget.block.checked);
    if (index < newChecked.length) {
      newChecked[index] = !newChecked[index];
      widget.onChanged(widget.block.copyWith(checked: newChecked));
    }
  }

  void _addItem() {
    final newItems = List<String>.from(widget.block.items);
    newItems.add('');
    final newChecked = List<bool>.from(widget.block.checked);
    newChecked.add(false);
    widget.onChanged(
      widget.block.copyWith(items: newItems, checked: newChecked),
    );
  }

  void _removeItem(int index) {
    if (widget.block.items.length <= 1) return;

    final newItems = List<String>.from(widget.block.items);
    final newChecked = List<bool>.from(widget.block.checked);

    if (index < newItems.length) {
      newItems.removeAt(index);
    }
    if (index < newChecked.length) {
      newChecked.removeAt(index);
    }

    widget.onChanged(
      widget.block.copyWith(items: newItems, checked: newChecked),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ensure we have valid data
    final itemCount = widget.block.items.length;
    final checkedCount = widget.block.checked.length;
    // final safeCount = itemCount < checkedCount ? itemCount : checkedCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < itemCount; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox
                  GestureDetector(
                    onTap: () => _toggleChecked(i),
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, right: 8),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              (i < checkedCount && widget.block.checked[i])
                                  ? AppColors.accent
                                  : AppColors.divider,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        color:
                            (i < checkedCount && widget.block.checked[i])
                                ? AppColors.accent
                                : Colors.transparent,
                      ),
                      child:
                          (i < checkedCount && widget.block.checked[i])
                              ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              )
                              : null,
                    ),
                  ),

                  Expanded(
                    child: TextField(
                      controller:
                          i < _controllers.length ? _controllers[i] : null,
                      focusNode:
                          i == 0
                              ? widget.focusNode
                              : (i < _focusNodes.length
                                  ? _focusNodes[i]
                                  : null),
                      maxLines: null,
                      enableInteractiveSelection: true,
                      selectionControls: _CustomTextSelectionControls(),
                      decoration: const InputDecoration(
                        hintText: 'Todo item...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                        isDense: true,
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color:
                            (i < checkedCount && widget.block.checked[i])
                                ? AppColors.textTertiary
                                : AppColors.textPrimary,
                        decoration:
                            (i < checkedCount && widget.block.checked[i])
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                      ),
                      onTap: () {
                        if (i < _controllers.length) {
                          widget.onSelectionChanged(_controllers[i].selection);
                        }
                      },
                    ),
                  ),

                  if (widget.block.items.length > 1)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      child: IconButton(
                        onPressed: () => _removeItem(i),
                        icon: const Icon(Icons.close, size: 16),
                        color: AppColors.textTertiary,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          Container(
            margin: const EdgeInsets.only(top: 8, left: 28),
            child: TextButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add item'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textTertiary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
