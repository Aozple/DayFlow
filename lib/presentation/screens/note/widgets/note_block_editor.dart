import 'package:dayflow/presentation/screens/note/widgets/block_widgets/callout_block_widget.dart';
import 'package:dayflow/presentation/screens/note/widgets/block_widgets/code_block_widget.dart';
import 'package:dayflow/presentation/screens/note/widgets/block_widgets/quote_block_widget.dart';
import 'package:dayflow/presentation/screens/note/widgets/block_widgets/toggle_block_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/note_block.dart';

// Import our components
import 'editor_components/editor_header.dart';
import 'editor_components/formatting_toolbar.dart';
import 'editor_components/block_type_selector.dart';
import 'editor_components/block_actions_menu.dart';
import 'block_widgets/text_block_widget.dart';
import 'block_widgets/heading_block_widget.dart';
import 'block_widgets/list_block_widgets.dart';
import 'editor_utils.dart';

class NoteBlockEditor extends StatefulWidget {
  final List<NoteBlock> initialBlocks;
  final Function(List<NoteBlock>) onBlocksChanged;
  final FocusNode? focusNode;

  const NoteBlockEditor({
    super.key,
    required this.initialBlocks,
    required this.onBlocksChanged,
    this.focusNode,
  });

  @override
  State<NoteBlockEditor> createState() => _NoteBlockEditorState();
}

class _NoteBlockEditorState extends State<NoteBlockEditor>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late List<NoteBlock> _blocks;
  late ScrollController _scrollController;
  final FocusNode _editorFocusNode = FocusNode();
  final Map<String, FocusNode> _blockFocusNodes = {};

  // Animation controllers for smooth transitions
  late AnimationController _toolbarAnimationController;
  late AnimationController _addButtonAnimationController;

  // Keyboard height tracking
  double _keyboardHeight = 0;

  // Formatting toolbar state management
  bool _showFormattingToolbar = false;
  TextSelection _currentSelection = const TextSelection.collapsed(offset: -1);
  String _currentBlockId = '';
  Offset _toolbarPosition = Offset.zero;
  String _selectedText = '';

  // Block actions state
  bool _showBlockActions = false;
  int _selectedBlockIndex = -1;

  @override
  void initState() {
    super.initState();
    _blocks = List.from(widget.initialBlocks);
    _scrollController = ScrollController();

    // Add keyboard observer
    WidgetsBinding.instance.addObserver(this);

    // Setup animations for UI elements
    _toolbarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _addButtonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Create focus nodes for each block
    for (final block in _blocks) {
      _blockFocusNodes[block.id] = FocusNode();
    }

    // Start with empty text block if no content
    if (_blocks.isEmpty) {
      _addTextBlock();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _editorFocusNode.dispose();
    _toolbarAnimationController.dispose();
    _addButtonAnimationController.dispose();
    for (final node in _blockFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  // Handle keyboard height changes
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    final view = View.of(context);
    final bottomInset = view.viewInsets.bottom / view.devicePixelRatio;

    if (bottomInset != _keyboardHeight) {
      setState(() {
        _keyboardHeight = bottomInset;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.background),
      child: Column(
        children: [
          // Top header with controls
          EditorHeader(onAddBlock: _showBlockTypeSelector),

          // Main editing area
          Expanded(
            child: Stack(
              children: [
                // List of blocks
                _buildBlocksList(),

                // Formatting toolbar that appears on text selection
                if (_showFormattingToolbar) _buildAnimatedToolbar(),

                // Block actions menu
                if (_showBlockActions)
                  BlockActionsMenu(
                    onConvert:
                        (type) => _convertBlock(_selectedBlockIndex, type),
                    onDuplicate: () => _duplicateBlock(_selectedBlockIndex),
                    onDelete: () => _deleteBlock(_selectedBlockIndex),
                    onChangeColor: () => _showColorPicker(_selectedBlockIndex),
                    onHide: () => setState(() => _showBlockActions = false),
                  ),

                // Floating add button
                _buildFloatingAddButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build the main list of blocks with drag and drop
  Widget _buildBlocksList() {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      child: ReorderableListView.builder(
        scrollController: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: _blocks.length,
        proxyDecorator: (child, index, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                shadowColor: AppColors.accent.withAlpha(50),
                child: child,
              );
            },
            child: child,
          );
        },
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final item = _blocks.removeAt(oldIndex);
            _blocks.insert(newIndex, item);
            _notifyBlocksChanged();
          });
          HapticFeedback.mediumImpact();
        },
        itemBuilder: (context, index) {
          return _buildBlockItem(_blocks[index], index);
        },
      ),
    );
  }

  // Build individual block item with better design
  Widget _buildBlockItem(NoteBlock block, int index) {
    return Container(
      key: ValueKey(block.id),
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _blockFocusNodes[block.id]?.requestFocus();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    _isBlockFocused(block.id)
                        ? AppColors.accent.withAlpha(100)
                        : AppColors.divider.withAlpha(20),
                width: _isBlockFocused(block.id) ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced drag handle that actually works
                _buildDragHandle(block, index),

                // Main block content
                Expanded(child: _buildBlockContent(block, index)),

                // Quick action buttons
                _buildQuickActions(index),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Enhanced drag handle with block type visual indicator
  Widget _buildDragHandle(NoteBlock block, int index) {
    return ReorderableDragStartListener(
      index: index,
      child: Container(
        width: 48,
        padding: const EdgeInsets.only(left: 12, top: 16, bottom: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Visual indicator for block type
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _getBlockTypeColor(block.type).withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _getBlockTypeIcon(block.type),
                size: 14,
                color: _getBlockTypeColor(block.type),
              ),
            ),
            const SizedBox(height: 8),
            // Drag handle icon
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.divider.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.drag_handle,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Quick action buttons on the right of each block
  Widget _buildQuickActions(int index) {
    return Container(
      width: 36,
      padding: const EdgeInsets.only(right: 8, top: 12),
      child: Column(
        children: [
          // Convert block type button
          IconButton(
            onPressed: () => _showConvertMenu(index),
            icon: const Icon(Icons.transform, size: 16),
            color: AppColors.textTertiary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
          const SizedBox(height: 4),
          // More options button
          IconButton(
            onPressed: () => _showBlockActionsMenuAt(index),
            icon: const Icon(Icons.more_vert, size: 16),
            color: AppColors.textTertiary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }

  // Animated formatting toolbar
  Widget _buildAnimatedToolbar() {
    return AnimatedBuilder(
      animation: _toolbarAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _toolbarAnimationController.value,
          child: Opacity(
            opacity: _toolbarAnimationController.value,
            child: FormattingToolbar(
              position: _toolbarPosition,
              selectedText: _selectedText,
              onFormat: _applyFormatting,
              onHide: _hideFormattingToolbar,
            ),
          ),
        );
      },
    );
  }

  // Floating add button with animation
  Widget _buildFloatingAddButton() {
    return Positioned(
      right: 20,
      bottom: 20 + _keyboardHeight, // Adjust for keyboard
      child: AnimatedBuilder(
        animation: _addButtonAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.8 + (_addButtonAnimationController.value * 0.2),
            child: FloatingActionButton(
              onPressed: _showBlockTypeSelector,
              backgroundColor: AppColors.accent,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  // Check if a block is currently focused
  bool _isBlockFocused(String blockId) {
    return _blockFocusNodes[blockId]?.hasFocus ?? false;
  }

  // Get color for different block types
  Color _getBlockTypeColor(BlockType type) {
    switch (type) {
      case BlockType.text:
        return AppColors.textSecondary;
      case BlockType.heading:
        return AppColors.accent;
      case BlockType.bulletList:
        return Colors.orange;
      case BlockType.numberedList:
        return Colors.blue;
      case BlockType.todoList:
        return Colors.green;
      case BlockType.quote:
        return Colors.purple;
      case BlockType.code:
        return Colors.red;
      case BlockType.toggle:
        return Colors.indigo;
      case BlockType.callout:
        return Colors.yellow;
    }
  }

  // Get icon for different block types
  IconData _getBlockTypeIcon(BlockType type) {
    switch (type) {
      case BlockType.text:
        return Icons.text_fields;
      case BlockType.heading:
        return Icons.title;
      case BlockType.bulletList:
        return Icons.format_list_bulleted;
      case BlockType.numberedList:
        return Icons.format_list_numbered;
      case BlockType.todoList:
        return Icons.checklist;
      case BlockType.quote:
        return Icons.format_quote;
      case BlockType.code:
        return Icons.code;
      case BlockType.toggle:
        return Icons.keyboard_arrow_right;
      case BlockType.callout:
        return Icons.info;
    }
  }

  // Build the content for each block type
  Widget _buildBlockContent(NoteBlock block, int index) {
    switch (block.type) {
      case BlockType.text:
        return TextBlockWidget(
          block: block as TextBlock,
          focusNode: _blockFocusNodes[block.id]!,
          onChanged: (newBlock) => _updateBlock(index, newBlock),
          onSelectionChanged:
              (selection) => _handleTextSelectionChanged(selection, block.id),
          onTextChange: (text, blockId) => _handleTextChange(text, blockId),
        );

      case BlockType.heading:
        return HeadingBlockWidget(
          block: block as HeadingBlock,
          focusNode: _blockFocusNodes[block.id]!,
          onChanged: (newBlock) => _updateBlock(index, newBlock),
          onSelectionChanged:
              (selection) => _handleTextSelectionChanged(selection, block.id),
          onTextChange: (text, blockId) => _handleTextChange(text, blockId),
        );

      case BlockType.bulletList:
        return BulletListBlockWidget(
          block: block as BulletListBlock,
          focusNode: _blockFocusNodes[block.id]!,
          onChanged: (newBlock) => _updateBlock(index, newBlock),
          onSelectionChanged:
              (selection) => _handleTextSelectionChanged(selection, block.id),
          onTextChange: (text, blockId) => _handleTextChange(text, blockId),
        );

      case BlockType.numberedList:
        return NumberedListBlockWidget(
          block: block as NumberedListBlock,
          focusNode: _blockFocusNodes[block.id]!,
          onChanged: (newBlock) => _updateBlock(index, newBlock),
          onSelectionChanged:
              (selection) => _handleTextSelectionChanged(selection, block.id),
          onTextChange: (text, blockId) => _handleTextChange(text, blockId),
        );

      case BlockType.todoList:
        return TodoListBlockWidget(
          block: block as TodoListBlock,
          focusNode: _blockFocusNodes[block.id]!,
          onChanged: (newBlock) => _updateBlock(index, newBlock),
          onSelectionChanged:
              (selection) => _handleTextSelectionChanged(selection, block.id),
          onTextChange: (text, blockId) => _handleTextChange(text, blockId),
        );

      case BlockType.quote:
        return QuoteBlockWidget(
          block: block as QuoteBlock,
          focusNode: _blockFocusNodes[block.id]!,
          onChanged: (newBlock) => _updateBlock(index, newBlock),
          onSelectionChanged:
              (selection) => _handleTextSelectionChanged(selection, block.id),
          onTextChange: (text, blockId) => _handleTextChange(text, blockId),
        );

      case BlockType.code:
        return CodeBlockWidget(
          block: block as CodeBlock,
          focusNode: _blockFocusNodes[block.id]!,
          onChanged: (newBlock) => _updateBlock(index, newBlock),
          onSelectionChanged:
              (selection) => _handleTextSelectionChanged(selection, block.id),
          onTextChange: (text, blockId) => _handleTextChange(text, blockId),
        );

      case BlockType.toggle:
        return ToggleBlockWidget(
          block: block as ToggleBlock,
          focusNode: _blockFocusNodes[block.id]!,
          onChanged: (newBlock) => _updateBlock(index, newBlock),
          onSelectionChanged:
              (selection) => _handleTextSelectionChanged(selection, block.id),
          onTextChange: (text, blockId) => _handleTextChange(text, blockId),
        );

      case BlockType.callout:
        return CalloutBlockWidget(
          block: block as CalloutBlock,
          focusNode: _blockFocusNodes[block.id]!,
          onChanged: (newBlock) => _updateBlock(index, newBlock),
          onSelectionChanged:
              (selection) => _handleTextSelectionChanged(selection, block.id),
          onTextChange: (text, blockId) => _handleTextChange(text, blockId),
        );
    }
  }

  // Handle text changes
  void _handleTextChange(String text, String blockId) {}

  // Show block actions menu at specific position
  void _showBlockActionsMenuAt(int index) {
    setState(() {
      _selectedBlockIndex = index;
      _showBlockActions = true;
    });
  }

  // Show convert block type menu
  void _showConvertMenu(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildConvertMenu(index),
    );
  }

  // Build convert menu with proper sizing to prevent overflow
  Widget _buildConvertMenu(int index) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.divider, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Convert Block',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          // Scrollable content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                ...BlockType.values.map(
                  (type) => _buildConvertOption(type, index),
                ),
              ],
            ),
          ),

          // Bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  // Enhanced convert option with better design
  Widget _buildConvertOption(BlockType type, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            _convertBlock(index, type);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.divider.withAlpha(30),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Icon with colored background
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getBlockTypeColor(type).withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getBlockTypeIcon(type),
                    size: 20,
                    color: _getBlockTypeColor(type),
                  ),
                ),

                const SizedBox(width: 16),

                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getBlockTypeName(type),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getBlockTypeDescription(type),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Arrow icon
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Get description for block types
  String _getBlockTypeDescription(BlockType type) {
    switch (type) {
      case BlockType.text:
        return 'Plain text paragraph';
      case BlockType.heading:
        return 'Large section heading';
      case BlockType.bulletList:
        return 'Unordered list with bullets';
      case BlockType.numberedList:
        return 'Ordered list with numbers';
      case BlockType.todoList:
        return 'Checkable task list';
      case BlockType.quote:
        return 'Quotation or citation';
      case BlockType.code:
        return 'Code snippet with syntax';
      case BlockType.toggle:
        return 'Collapsible content section';
      case BlockType.callout:
        return 'Highlighted information box';
    }
  }

  // Get human readable name for block types
  String _getBlockTypeName(BlockType type) {
    switch (type) {
      case BlockType.text:
        return 'Text';
      case BlockType.heading:
        return 'Heading';
      case BlockType.bulletList:
        return 'Bullet List';
      case BlockType.numberedList:
        return 'Numbered List';
      case BlockType.todoList:
        return 'Todo List';
      case BlockType.quote:
        return 'Quote';
      case BlockType.code:
        return 'Code';
      case BlockType.toggle:
        return 'Toggle';
      case BlockType.callout:
        return 'Callout';
    }
  }

  // Convert a block from one type to another - Fixed null check error
  void _convertBlock(int index, BlockType newType) {
    if (index < 0 || index >= _blocks.length) return;

    final currentBlock = _blocks[index];
    NoteBlock newBlock;

    // Extract text content from current block safely
    String textContent = '';

    // Safe extraction based on block type
    if (currentBlock is TextBlock) {
      textContent = currentBlock.text;
    } else if (currentBlock is HeadingBlock) {
      textContent = currentBlock.text;
    } else if (currentBlock is BulletListBlock) {
      textContent =
          currentBlock.items.isNotEmpty ? currentBlock.items.first : '';
    } else if (currentBlock is NumberedListBlock) {
      textContent =
          currentBlock.items.isNotEmpty ? currentBlock.items.first : '';
    } else if (currentBlock is TodoListBlock) {
      textContent =
          currentBlock.items.isNotEmpty ? currentBlock.items.first : '';
    } else if (currentBlock is QuoteBlock) {
      textContent = currentBlock.text;
    } else if (currentBlock is CodeBlock) {
      textContent = currentBlock.code;
    }

    // Create new block of desired type with preserved content
    switch (newType) {
      case BlockType.text:
        newBlock = TextBlock(id: currentBlock.id, text: textContent);
        break;
      case BlockType.heading:
        newBlock = HeadingBlock(
          id: currentBlock.id,
          text: textContent,
          level: 1,
        );
        break;
      case BlockType.bulletList:
        newBlock = BulletListBlock(
          id: currentBlock.id,
          items: textContent.isEmpty ? [''] : [textContent],
        );
        break;
      case BlockType.numberedList:
        newBlock = NumberedListBlock(
          id: currentBlock.id,
          items: textContent.isEmpty ? [''] : [textContent],
        );
        break;
      case BlockType.todoList:
        newBlock = TodoListBlock(
          id: currentBlock.id,
          items: textContent.isEmpty ? [''] : [textContent],
          checked: const [false],
        );
        break;
      case BlockType.quote:
        newBlock = QuoteBlock(id: currentBlock.id, text: textContent);
        break;
      case BlockType.code:
        newBlock = CodeBlock(id: currentBlock.id, code: textContent);
        break;
      case BlockType.toggle:
        newBlock = ToggleBlock(
          id: currentBlock.id,
          title: textContent.isEmpty ? 'Toggle' : textContent,
          children: const [],
        );
        break;
      case BlockType.callout:
        newBlock = CalloutBlock(
          id: currentBlock.id,
          text: textContent,
          calloutType: 'info',
        );
        break;
    }

    // Update the block
    _updateBlock(index, newBlock);
    HapticFeedback.lightImpact();
  }

  // Show color picker for block (placeholder)
  void _showColorPicker(int index) {
    // TODO: Implement color picker
    setState(() => _showBlockActions = false);
  }

  // Handle text selection changes
  void _handleTextSelectionChanged(TextSelection selection, String blockId) {
    setState(() {
      _currentSelection = selection;
      _currentBlockId = blockId;

      if (!selection.isCollapsed) {
        final blockIndex = _blocks.indexWhere((b) => b.id == blockId);
        if (blockIndex != -1) {
          final block = _blocks[blockIndex];
          if (block is TextBlock) {
            _selectedText = block.text.substring(
              selection.start,
              selection.end,
            );
          }
        }

        _showFormattingToolbar = true;
        _toolbarPosition = _calculateToolbarPosition(selection);
        _toolbarAnimationController.forward();
      } else {
        _hideFormattingToolbar();
      }
    });
  }

  // Hide formatting toolbar with animation
  void _hideFormattingToolbar() {
    _toolbarAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showFormattingToolbar = false;
          _selectedText = '';
        });
      }
    });
  }

  // Calculate position for formatting toolbar
  Offset _calculateToolbarPosition(TextSelection selection) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Offset((screenWidth * 0.5) - 125, 150);
  }

  // Show block type selector modal
  void _showBlockTypeSelector() {
    _addButtonAnimationController.forward();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BlockTypeSelector(onBlockSelected: _addBlockOfType),
    ).then((_) {
      _addButtonAnimationController.reverse();
    });
  }

  // Add new block of specified type
  void _addBlockOfType(BlockType type) {
    final newBlock = EditorUtils.createBlockOfType(type);
    setState(() {
      _blocks.add(newBlock);
      _blockFocusNodes[newBlock.id] = FocusNode();
    });
    _notifyBlocksChanged();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _blockFocusNodes[newBlock.id]?.requestFocus();
      _scrollToBottom();
    });
  }

  // Add default text block
  void _addTextBlock() {
    _addBlockOfType(BlockType.text);
  }

  // Update a block at specific index
  void _updateBlock(int index, NoteBlock newBlock) {
    setState(() => _blocks[index] = newBlock);
    _notifyBlocksChanged();
  }

  // Duplicate a block
  void _duplicateBlock(int index) {
    final block = _blocks[index];
    final duplicatedBlock = EditorUtils.duplicateBlock(block);

    setState(() {
      _blocks.insert(index + 1, duplicatedBlock);
      _blockFocusNodes[duplicatedBlock.id] = FocusNode();
      _showBlockActions = false;
    });
    _notifyBlocksChanged();
    HapticFeedback.lightImpact();
  }

  // Delete a block
  void _deleteBlock(int index) {
    setState(() {
      _blockFocusNodes[_blocks[index].id]?.dispose();
      _blockFocusNodes.remove(_blocks[index].id);
      _blocks.removeAt(index);
      _showBlockActions = false;

      if (_blocks.isEmpty) {
        _addTextBlock();
      }
    });
    _notifyBlocksChanged();
    HapticFeedback.lightImpact();
  }

  // Apply text formatting
  void _applyFormatting(String format) {
    if (_currentSelection.isCollapsed && format != 'delete') return;

    final blockIndex = _blocks.indexWhere((b) => b.id == _currentBlockId);
    if (blockIndex == -1) return;

    final block = _blocks[blockIndex];
    if (block is TextBlock) {
      String newText;

      if (format == 'delete') {
        newText = block.text.replaceRange(
          _currentSelection.start,
          _currentSelection.end,
          '',
        );
      } else {
        newText = EditorUtils.applyTextFormatting(
          block.text,
          _currentSelection,
          format,
        );
      }

      _updateBlock(blockIndex, block.copyWith(text: newText));
    }
  }

  // Notify parent about blocks changes
  void _notifyBlocksChanged() {
    widget.onBlocksChanged(_blocks);
  }

  // Scroll to bottom of the list
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
