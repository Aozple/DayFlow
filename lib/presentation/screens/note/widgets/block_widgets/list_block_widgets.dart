import 'package:flutter/material.dart';
import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/note_block.dart';
import 'base_block_widget.dart';

// Shared list item widget for better code reuse with RTL support
class _ListItemWidget extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final Widget prefix;
  final String hintText;
  final TextStyle? textStyle;
  final VoidCallback onRemove;
  final Function(TextSelection) onSelectionChanged;
  final bool showRemoveButton;
  final TextDirection textDirection;

  const _ListItemWidget({
    required this.index,
    required this.controller,
    required this.focusNode,
    required this.prefix,
    required this.hintText,
    this.textStyle,
    required this.onRemove,
    required this.onSelectionChanged,
    required this.showRemoveButton,
    required this.textDirection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              focusNode?.hasFocus == true
                  ? AppColors.accent.withAlpha(50)
                  : AppColors.divider.withAlpha(20),
          width: 0.5,
        ),
      ),
      child: Directionality(
        textDirection: textDirection,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prefix (bullet, number, or checkbox) - auto positioned by Directionality
            Container(
              width: 36,
              padding: const EdgeInsets.only(top: 14),
              alignment: Alignment.topCenter,
              child: prefix,
            ),

            // Text field
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: null,
                textDirection: textDirection,
                textAlign:
                    textDirection == TextDirection.rtl
                        ? TextAlign.right
                        : TextAlign.left,
                selectionControls: EmptyTextSelectionControls(),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(
                    color: AppColors.textTertiary.withAlpha(100),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(
                    top: 14,
                    bottom: 14,
                    right: 8,
                  ),
                  isDense: true,
                ),
                style:
                    textStyle ??
                    const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.1,
                    ),
                onTap: () => onSelectionChanged(controller.selection),
              ),
            ),

            // Remove button - auto positioned by Directionality
            if (showRemoveButton)
              Container(
                margin: const EdgeInsets.only(top: 8, right: 8),
                child: InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.surface.withAlpha(50),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Base class for all list widgets with RTL support
abstract class _BaseListWidget<T extends NoteBlock> extends StatefulWidget {
  final T block;
  final FocusNode focusNode;
  final Function(T) onChanged;
  final Function(TextSelection) onSelectionChanged;
  final Function(String, String) onTextChange;

  const _BaseListWidget({
    required this.block,
    required this.focusNode,
    required this.onChanged,
    required this.onSelectionChanged,
    required this.onTextChange,
  });
}

abstract class _BaseListState<T extends NoteBlock, W extends _BaseListWidget<T>>
    extends State<W> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  late List<TextDirection> _textDirections;
  bool _isDisposed = false;

  List<String> get items;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final itemsList = items.isEmpty ? [''] : items;

    _controllers =
        itemsList.map((item) => TextEditingController(text: item)).toList();
    _focusNodes = itemsList.map((_) => FocusNode()).toList();
    _textDirections =
        itemsList.map((item) => _detectTextDirection(item)).toList();

    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].addListener(() => _onItemChanged(i));
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(W oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (items.length != _controllers.length) {
      // Rebuild controllers if items count changed
      for (final controller in _controllers) {
        controller.dispose();
      }
      for (final focusNode in _focusNodes) {
        focusNode.dispose();
      }
      _initializeControllers();
    }
  }

  void _onItemChanged(int index) {
    if (_isDisposed || index >= items.length) return;

    final text = _controllers[index].text;
    _updateTextDirection(index, text);
    updateItem(index, text);
    widget.onTextChange(text, widget.block.id);
  }

  void _updateTextDirection(int index, String text) {
    if (index >= _textDirections.length) return;

    final newDirection = _detectTextDirection(text);
    if (_textDirections[index] != newDirection) {
      setState(() {
        _textDirections[index] = newDirection;
      });
    }
  }

  // Detect text direction based on first character
  TextDirection _detectTextDirection(String text) {
    if (text.isEmpty) return TextDirection.ltr;

    final cleanText = _stripMarkdown(text).trim();
    if (cleanText.isEmpty) return TextDirection.ltr;

    final firstChar = cleanText.runes.first;
    return _isRTLCharacter(firstChar) ? TextDirection.rtl : TextDirection.ltr;
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

  // Get bilingual hint text based on predominant direction
  String _getBilingualHintText() {
    // Check if any item has RTL content
    final hasRTLContent = _textDirections.any(
      (dir) => dir == TextDirection.rtl,
    );

    if (hasRTLContent) {
      return _getRTLHintText();
    }
    return _getLTRHintText();
  }

  String _getLTRHintText();
  String _getRTLHintText();

  void updateItem(int index, String text);
  void addItem();
  void removeItem(int index);
  Widget buildPrefix(int index);
  TextStyle? getTextStyle(int index) => null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // List type indicator with item count
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getListColor().withAlpha(20),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _getListColor().withAlpha(40),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getListIcon(), size: 10, color: _getListColor()),
                      const SizedBox(width: 3),
                      Text(
                        _getListTypeName(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: _getListColor(),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // List items with stable structure
          for (int i = 0; i < items.length; i++)
            _ListItemWidget(
              index: i,
              controller:
                  i < _controllers.length
                      ? _controllers[i]
                      : TextEditingController(),
              focusNode:
                  i == 0
                      ? widget.focusNode
                      : (i < _focusNodes.length ? _focusNodes[i] : null),
              prefix: buildPrefix(i),
              hintText: _getBilingualHintText(),
              textStyle: getTextStyle(i),
              onRemove: () => removeItem(i),
              onSelectionChanged: widget.onSelectionChanged,
              showRemoveButton: items.length > 1,
              textDirection:
                  i < _textDirections.length
                      ? _textDirections[i]
                      : TextDirection.ltr,
            ),

          // Add item button
          Container(
            margin: const EdgeInsets.only(top: 8),
            child: InkWell(
              onTap: addItem,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.divider.withAlpha(30),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      'Add item',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getListIcon() {
    if (widget is _BulletListWidget) return Icons.format_list_bulleted_rounded;
    if (widget is _NumberedListWidget)
      return Icons.format_list_numbered_rounded;
    if (widget is _TodoListWidget) return Icons.checklist_rounded;
    return Icons.list;
  }

  Color _getListColor() {
    if (widget is _BulletListWidget) return Colors.orange;
    if (widget is _NumberedListWidget) return Colors.blue;
    if (widget is _TodoListWidget) return Colors.green;
    return AppColors.accent;
  }

  String _getListTypeName() {
    if (widget is _BulletListWidget) return 'Bullet List';
    if (widget is _NumberedListWidget) return 'Numbered List';
    if (widget is _TodoListWidget) return 'Todo List';
    return 'List';
  }
}

// Bullet List Implementation
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

class _BulletListWidget extends _BaseListWidget<BulletListBlock> {
  const _BulletListWidget({
    required super.block,
    required super.focusNode,
    required super.onChanged,
    required super.onSelectionChanged,
    required super.onTextChange,
  });

  @override
  State<_BulletListWidget> createState() => _BulletListWidgetState();
}

class _BulletListWidgetState
    extends _BaseListState<BulletListBlock, _BulletListWidget> {
  @override
  List<String> get items => widget.block.items;

  @override
  String _getLTRHintText() => 'List item...';

  @override
  String _getRTLHintText() => 'مورد فهرست...';

  @override
  void updateItem(int index, String text) {
    final newItems = List<String>.from(widget.block.items);
    newItems[index] = text;
    widget.onChanged(widget.block.copyWith(items: newItems));
  }

  @override
  void addItem() {
    final newItems = List<String>.from(widget.block.items)..add('');
    widget.onChanged(widget.block.copyWith(items: newItems));

    // Focus new item after rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusNodes.isNotEmpty) {
        _focusNodes.last.requestFocus();
      }
    });
  }

  @override
  void removeItem(int index) {
    if (widget.block.items.length <= 1) return;
    final newItems = List<String>.from(widget.block.items)..removeAt(index);
    widget.onChanged(widget.block.copyWith(items: newItems));
  }

  @override
  Widget buildPrefix(int index) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Colors.orange,
        shape: BoxShape.circle,
      ),
    );
  }
}

// Numbered List Implementation
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

class _NumberedListWidget extends _BaseListWidget<NumberedListBlock> {
  const _NumberedListWidget({
    required super.block,
    required super.focusNode,
    required super.onChanged,
    required super.onSelectionChanged,
    required super.onTextChange,
  });

  @override
  State<_NumberedListWidget> createState() => _NumberedListWidgetState();
}

class _NumberedListWidgetState
    extends _BaseListState<NumberedListBlock, _NumberedListWidget> {
  @override
  List<String> get items => widget.block.items;

  @override
  String _getLTRHintText() => 'List item...';

  @override
  String _getRTLHintText() => 'مورد فهرست...';

  @override
  void updateItem(int index, String text) {
    final newItems = List<String>.from(widget.block.items);
    newItems[index] = text;
    widget.onChanged(widget.block.copyWith(items: newItems));
  }

  @override
  void addItem() {
    final newItems = List<String>.from(widget.block.items)..add('');
    widget.onChanged(widget.block.copyWith(items: newItems));

    // Focus new item after rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusNodes.isNotEmpty) {
        _focusNodes.last.requestFocus();
      }
    });
  }

  @override
  void removeItem(int index) {
    if (widget.block.items.length <= 1) return;
    final newItems = List<String>.from(widget.block.items)..removeAt(index);
    widget.onChanged(widget.block.copyWith(items: newItems));
  }

  @override
  Widget buildPrefix(int index) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(15),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue.withAlpha(40), width: 0.5),
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }
}

// Todo List Implementation
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

class _TodoListWidget extends _BaseListWidget<TodoListBlock> {
  const _TodoListWidget({
    required super.block,
    required super.focusNode,
    required super.onChanged,
    required super.onSelectionChanged,
    required super.onTextChange,
  });

  @override
  State<_TodoListWidget> createState() => _TodoListWidgetState();
}

class _TodoListWidgetState
    extends _BaseListState<TodoListBlock, _TodoListWidget> {
  @override
  List<String> get items => widget.block.items;

  @override
  String _getLTRHintText() => 'Todo item...';

  @override
  String _getRTLHintText() => 'کار انجام دادنی...';

  @override
  void updateItem(int index, String text) {
    final newItems = List<String>.from(widget.block.items);
    newItems[index] = text;
    widget.onChanged(widget.block.copyWith(items: newItems));
  }

  @override
  void addItem() {
    final newItems = List<String>.from(widget.block.items)..add('');
    final newChecked = List<bool>.from(widget.block.checked)..add(false);
    widget.onChanged(
      widget.block.copyWith(items: newItems, checked: newChecked),
    );

    // Focus new item after rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusNodes.isNotEmpty) {
        _focusNodes.last.requestFocus();
      }
    });
  }

  @override
  void removeItem(int index) {
    if (widget.block.items.length <= 1) return;

    final newItems = List<String>.from(widget.block.items)..removeAt(index);
    final newChecked = List<bool>.from(widget.block.checked);
    if (index < newChecked.length) {
      newChecked.removeAt(index);
    }

    widget.onChanged(
      widget.block.copyWith(items: newItems, checked: newChecked),
    );
  }

  void _toggleChecked(int index) {
    if (index >= widget.block.checked.length) return;

    final newChecked = List<bool>.from(widget.block.checked);
    newChecked[index] = !newChecked[index];
    widget.onChanged(widget.block.copyWith(checked: newChecked));
  }

  @override
  Widget buildPrefix(int index) {
    final isChecked =
        index < widget.block.checked.length && widget.block.checked[index];

    return GestureDetector(
      onTap: () => _toggleChecked(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          gradient:
              isChecked
                  ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.green, Colors.green.withAlpha(200)],
                  )
                  : null,
          color: isChecked ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isChecked ? Colors.green : AppColors.divider.withAlpha(100),
            width: isChecked ? 0 : 1.5,
          ),
          boxShadow:
              isChecked
                  ? [
                    BoxShadow(
                      color: Colors.green.withAlpha(30),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child:
            isChecked
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : null,
      ),
    );
  }

  @override
  TextStyle? getTextStyle(int index) {
    final isChecked =
        index < widget.block.checked.length && widget.block.checked[index];

    return TextStyle(
      fontSize: 16,
      height: 1.5,
      color:
          isChecked
              ? AppColors.textSecondary.withAlpha(150)
              : AppColors.textPrimary,
      decoration: isChecked ? TextDecoration.lineThrough : TextDecoration.none,
      decorationColor: AppColors.textTertiary,
      decorationThickness: 1.5,
      letterSpacing: 0.1,
    );
  }
}
