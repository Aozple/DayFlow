import 'dart:math' as math;
import 'package:dayflow/presentation/screens/note/widgets/block_widgets/callout_block_widget.dart';
import 'package:dayflow/presentation/screens/note/widgets/block_widgets/code_block_widget.dart';
import 'package:dayflow/presentation/screens/note/widgets/block_widgets/picture_block_widget.dart';
import 'package:dayflow/presentation/screens/note/widgets/block_widgets/quote_block_widget.dart';
import 'package:dayflow/presentation/screens/note/widgets/block_widgets/toggle_block_widget.dart';
import 'package:dayflow/presentation/widgets/draggable_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/note_block.dart';
import 'editor_components/formatting_toolbar.dart';
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

  // Keyboard height tracking
  double _keyboardHeight = 0;

  // Formatting toolbar state management
  bool _showFormattingToolbar = false;
  TextSelection _currentSelection = const TextSelection.collapsed(offset: -1);
  String _currentBlockId = '';
  Offset _toolbarPosition = Offset.zero;
  String _selectedText = '';

  // Block action menu state
  int _hoveredInsertIndex = -1;

  // FAB menu state
  bool _isFabOpen = false;
  OverlayEntry? _fabOverlayEntry;
  final GlobalKey _fabKey = GlobalKey();
  late AnimationController _fabRotationController;
  late AnimationController _fabExpandController;
  late Animation<double> _fabExpandAnimation;

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

    // Create focus nodes for each block
    for (final block in _blocks) {
      _blockFocusNodes[block.id] = FocusNode();
    }

    // Start with empty text block if no content
    if (_blocks.isEmpty) {
      _addTextBlock();
    }

    // Setup FAB animations
    _fabRotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _fabExpandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Create smooth expansion curve
    _fabExpandAnimation = CurvedAnimation(
      parent: _fabExpandController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _editorFocusNode.dispose();
    _toolbarAnimationController.dispose();
    _removeFabOverlay();
    _fabRotationController.dispose();
    _fabExpandController.dispose();
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
          // Main editing area
          Expanded(
            child: Stack(
              children: [
                // List of blocks with insertion points
                _buildBlocksList(),

                // Formatting toolbar that appears on text selection
                if (_showFormattingToolbar) _buildAnimatedToolbar(),

                // Floating add button
                _buildFloatingAddButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build the main list of blocks with insertion points
  Widget _buildBlocksList() {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      child: ReorderableListView.builder(
        scrollController: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        itemCount: _blocks.length + 1, // +1 for final add button
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
          // Don't allow reordering the add button
          if (oldIndex >= _blocks.length || newIndex >= _blocks.length) return;

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
          // Last item is the add button
          if (index == _blocks.length) {
            return _buildAddBlockButton();
          }

          return Column(
            key: ValueKey('column_${_blocks[index].id}'),
            children: [
              // Insertion point above each block (except first)
              if (index > 0) _buildInsertionPoint(index),

              // The actual block
              _buildBlockItem(_blocks[index], index),
            ],
          );
        },
      ),
    );
  }

  // Build insertion point between blocks
  Widget _buildInsertionPoint(int insertIndex) {
    final isHovered = _hoveredInsertIndex == insertIndex;

    return GestureDetector(
      onTap: () => _showInsertBlockMenu(insertIndex),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredInsertIndex = insertIndex),
        onExit: (_) => setState(() => _hoveredInsertIndex = -1),
        child: Container(
          height: 24,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: isHovered ? 3 : 1,
              width: double.infinity,
              decoration: BoxDecoration(
                color:
                    isHovered
                        ? AppColors.accent.withAlpha(100)
                        : AppColors.divider.withAlpha(30),
                borderRadius: BorderRadius.circular(2),
              ),
              child:
                  isHovered
                      ? Center(
                        child: Container(
                          width: 32,
                          height: 18,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      )
                      : null,
            ),
          ),
        ),
      ),
    );
  }

  // Build individual block with simplified UI
  Widget _buildBlockItem(NoteBlock block, int index) {
    return Container(
      key: ValueKey(block.id),
      margin: const EdgeInsets.only(bottom: 4),
      child: Stack(
        children: [
          // Main block content
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _blockFocusNodes[block.id]?.requestFocus();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color:
                      _isBlockFocused(block.id)
                          ? AppColors.accent.withAlpha(8)
                          : AppColors.surface.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        _isBlockFocused(block.id)
                            ? AppColors.accent.withAlpha(50)
                            : AppColors.divider.withAlpha(50),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    // Simple drag handle - only visible when focused
                    if (_isBlockFocused(block.id))
                      Container(
                        height: 24,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight.withAlpha(20),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            ReorderableDragStartListener(
                              index: index,
                              child: Icon(
                                Icons.drag_indicator,
                                size: 16,
                                color: AppColors.textSecondary.withAlpha(150),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getBlockTypeColor(
                                  block.type,
                                ).withAlpha(20),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getBlockTypeName(block.type),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _getBlockTypeColor(block.type),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Block content
                    _buildBlockContent(block, index),
                  ],
                ),
              ),
            ),
          ),

          // Action menu button - top right corner
          Positioned(
            top: 8,
            right: 8,
            child: _buildBlockActionButton(block, index),
          ),
        ],
      ),
    );
  }

  // Build simple action button for each block
  Widget _buildBlockActionButton(NoteBlock block, int index) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showBlockActionMenu(block, index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surface.withAlpha(200),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.divider.withAlpha(50),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.more_vert,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // Build add block button at the bottom
  Widget _buildAddBlockButton() {
    return Container(
      key: const ValueKey('add_block_button'),
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showInsertBlockMenu(_blocks.length),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.divider.withAlpha(30),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 20,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  'Add Block',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Floating add button
  Widget _buildFloatingAddButton() {
    return Positioned(
      right: 20,
      bottom: 48 + _keyboardHeight,
      child: FloatingActionButton(
        key: _fabKey,
        heroTag: 'main_add_fab',
        onPressed: _toggleFabMenu,
        backgroundColor: AppColors.accent,
        elevation: _isFabOpen ? 8 : 4,
        child: AnimatedBuilder(
          animation: _fabRotationController,
          builder: (context, child) {
            // Rotate icon when menu opens
            return Transform.rotate(
              angle: _fabRotationController.value * 0.125 * 2 * math.pi,
              child: Icon(
                _isFabOpen ? Icons.close : Icons.add,
                color: Colors.white,
                size: 28,
              ),
            );
          },
        ),
      ),
    );
  }

  // Toggle FAB menu state
  void _toggleFabMenu() {
    setState(() {
      _isFabOpen = !_isFabOpen;
      if (_isFabOpen) {
        // Opening sequence
        _fabRotationController.forward();
        _insertFabOverlay();
        _fabExpandController.forward();
        HapticFeedback.lightImpact();
      } else {
        // Closing sequence
        _fabRotationController.reverse();
        _fabExpandController.reverse().then((_) {
          _removeFabOverlay();
        });
      }
    });
  }

  // Create overlay with menu options
  void _insertFabOverlay() {
    // Get FAB position for proper placement
    final RenderBox? renderBox =
        _fabKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final fabPosition = renderBox.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;

    _fabOverlayEntry = OverlayEntry(
      builder:
          (context) => Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                // Background overlay to capture taps
                Positioned.fill(
                  child: GestureDetector(
                    onTapDown: (_) {
                      if (_isFabOpen) _toggleFabMenu();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(color: Colors.transparent),
                  ),
                ),

                // Text button with animation
                AnimatedBuilder(
                  animation: _fabExpandAnimation,
                  builder: (context, child) {
                    final animValue = _fabExpandAnimation.value.clamp(0.0, 1.0);
                    return Positioned(
                      right: screenWidth - fabPosition.dx - 54,
                      top: fabPosition.dy - (70 * animValue),
                      child: Opacity(
                        opacity: animValue,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Label with delayed appearance
                            if (animValue > 0.5)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(25),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Text',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                            // Text button
                            SizedBox(
                              width: 56,
                              height: 56,
                              child: FloatingActionButton(
                                heroTag: 'text_fab_overlay',
                                onPressed: () {
                                  _toggleFabMenu();
                                  _addBlockOfType(BlockType.text);
                                },
                                backgroundColor: AppColors.accent,
                                elevation: 4,
                                child: const Icon(
                                  Icons.text_fields,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Todo button with animation
                AnimatedBuilder(
                  animation: _fabExpandAnimation,
                  builder: (context, child) {
                    final animValue = _fabExpandAnimation.value.clamp(0.0, 1.0);
                    return Positioned(
                      right: screenWidth - fabPosition.dx - 54,
                      top: fabPosition.dy - (140 * animValue),
                      child: Opacity(
                        opacity: animValue,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Label with delayed appearance
                            if (animValue > 0.5)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(25),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Todo',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                            // Todo button
                            SizedBox(
                              width: 56,
                              height: 56,
                              child: FloatingActionButton(
                                heroTag: 'todo_fab_overlay',
                                onPressed: () {
                                  _toggleFabMenu();
                                  _addBlockOfType(BlockType.todoList);
                                },
                                backgroundColor: Colors.green,
                                elevation: 4,
                                child: const Icon(
                                  Icons.checklist,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Heading button with animation
                AnimatedBuilder(
                  animation: _fabExpandAnimation,
                  builder: (context, child) {
                    final animValue = _fabExpandAnimation.value.clamp(0.0, 1.0);
                    return Positioned(
                      right: screenWidth - fabPosition.dx - 54,
                      top: fabPosition.dy - (210 * animValue),
                      child: Opacity(
                        opacity: animValue,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Label with delayed appearance
                            if (animValue > 0.5)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(25),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Heading',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                            // Heading button
                            SizedBox(
                              width: 56,
                              height: 56,
                              child: FloatingActionButton(
                                heroTag: 'heading_fab_overlay',
                                onPressed: () {
                                  _toggleFabMenu();
                                  _addBlockOfType(BlockType.heading);
                                },
                                backgroundColor: AppColors.accent,
                                elevation: 4,
                                child: const Icon(
                                  Icons.title,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // List button with animation
                AnimatedBuilder(
                  animation: _fabExpandAnimation,
                  builder: (context, child) {
                    final animValue = _fabExpandAnimation.value.clamp(0.0, 1.0);
                    return Positioned(
                      right: screenWidth - fabPosition.dx - 54,
                      top: fabPosition.dy - (280 * animValue),
                      child: Opacity(
                        opacity: animValue,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Label with delayed appearance
                            if (animValue > 0.5)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(25),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'List',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                            // List button
                            SizedBox(
                              width: 56,
                              height: 56,
                              child: FloatingActionButton(
                                heroTag: 'list_fab_overlay',
                                onPressed: () {
                                  _toggleFabMenu();
                                  _addBlockOfType(BlockType.bulletList);
                                },
                                backgroundColor: Colors.orange,
                                elevation: 4,
                                child: const Icon(
                                  Icons.format_list_bulleted,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // More button with animation
                AnimatedBuilder(
                  animation: _fabExpandAnimation,
                  builder: (context, child) {
                    final animValue = _fabExpandAnimation.value.clamp(0.0, 1.0);
                    return Positioned(
                      right: screenWidth - fabPosition.dx - 54,
                      top: fabPosition.dy - (350 * animValue),
                      child: Opacity(
                        opacity: animValue,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Label with delayed appearance
                            if (animValue > 0.5)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(25),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'More',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                            // More button
                            SizedBox(
                              width: 56,
                              height: 56,
                              child: FloatingActionButton(
                                heroTag: 'more_fab_overlay',
                                onPressed: () {
                                  _toggleFabMenu();
                                  _showBlockTypeSelector();
                                },
                                backgroundColor: AppColors.textSecondary,
                                elevation: 4,
                                child: const Icon(
                                  Icons.more_horiz,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
    );

    // Add overlay to widget tree
    Overlay.of(context).insert(_fabOverlayEntry!);
  }

  // Remove overlay
  void _removeFabOverlay() {
    _fabOverlayEntry?.remove();
    _fabOverlayEntry = null;
  }

  // Show block action menu with simplified options
  void _showBlockActionMenu(NoteBlock block, int index) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: const Text('Block Actions'),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _showConvertMenu(index);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.transform, color: AppColors.accent),
                    const SizedBox(width: 8),
                    const Text('Convert Type'),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _duplicateBlock(index);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.content_copy, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Duplicate'),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteBlock(index);
                },
                isDestructiveAction: true,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
    );
  }

  // Show insert block menu at specific position
  void _showInsertBlockMenu(int insertIndex) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => DraggableModal(
            title: 'Add Block',
            initialHeight: MediaQuery.of(context).size.height * 0.6,
            minHeight: 300,
            allowFullScreen: true,
            child: _buildBlockTypeSelector(insertIndex),
          ),
    );
  }

  // Show block type selector modal
  void _showBlockTypeSelector() {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => DraggableModal(
            title: 'Add Block',
            initialHeight: MediaQuery.of(context).size.height * 0.6,
            minHeight: 300,
            allowFullScreen: true,
            child: _buildBlockTypeSelector(_blocks.length),
          ),
    );
  }

  // Build block type selector for insertion
  Widget _buildBlockTypeSelector(int insertIndex) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children:
          BlockType.values.map((type) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _insertBlockAt(insertIndex, type);
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
          }).toList(),
    );
  }

  // Animated formatting toolbar
  Widget _buildAnimatedToolbar() {
    return Positioned(
      left: _toolbarPosition.dx.clamp(
        10.0,
        MediaQuery.of(context).size.width - 280,
      ),
      top: _toolbarPosition.dy - 70,
      child: AnimatedBuilder(
        animation: _toolbarAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _toolbarAnimationController.value,
            child: Opacity(
              opacity: _toolbarAnimationController.value,
              child: FormattingToolbar(
                selectedText: _selectedText,
                onFormat: _applyFormatting,
                onHide: _hideFormattingToolbar,
              ),
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
      case BlockType.picture:
        return Colors.teal;
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
      case BlockType.picture:
        return Icons.image;
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

      case BlockType.picture:
        return PictureBlockWidget(
          block: block as PictureBlock,
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

  // Show convert block type menu
  void _showConvertMenu(int index) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => DraggableModal(
            title: 'Convert Block',
            initialHeight: MediaQuery.of(context).size.height * 0.6,
            minHeight: 300,
            allowFullScreen: true,
            child: _buildConvertMenuContent(index),
          ),
    );
  }

  // Build convert menu content
  Widget _buildConvertMenuContent(int index) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children:
          BlockType.values.map((type) {
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
          }).toList(),
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
      case BlockType.picture:
        return 'Image with caption';
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
      case BlockType.picture:
        return 'Picture';
    }
  }

  // Insert block at specific position
  void _insertBlockAt(int index, BlockType type) {
    final newBlock = EditorUtils.createBlockOfType(type);
    setState(() {
      _blocks.insert(index, newBlock);
      _blockFocusNodes[newBlock.id] = FocusNode();
    });
    _notifyBlocksChanged();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _blockFocusNodes[newBlock.id]?.requestFocus();
    });
  }

  // Convert a block from one type to another
  void _convertBlock(int index, BlockType newType) {
    if (index < 0 || index >= _blocks.length) return;

    final currentBlock = _blocks[index];
    NoteBlock newBlock;

    // Extract text content from current block safely
    String textContent = '';

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
      case BlockType.picture:
        newBlock = PictureBlock(id: currentBlock.id);
        break;
    }

    _updateBlock(index, newBlock);
    HapticFeedback.lightImpact();
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

  // Add new block of specified type at the end
  void _addBlockOfType(BlockType type) {
    _insertBlockAt(_blocks.length, type);
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
}
