import 'package:flutter/material.dart';
import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/note_block.dart';

class BlockActionsMenu extends StatelessWidget {
  final Function(BlockType) onConvert;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onChangeColor;
  final VoidCallback onHide;

  const BlockActionsMenu({
    super.key,
    required this.onConvert,
    required this.onDuplicate,
    required this.onDelete,
    required this.onChangeColor,
    required this.onHide,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Overlay to detect taps outside
        Positioned.fill(
          child: GestureDetector(
            onTap: onHide,
            child: Container(color: Colors.transparent),
          ),
        ),

        // Menu content
        Positioned(
          right: 16,
          top: 60,
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(16),
            color: AppColors.surface,
            child: Container(
              width: 200,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.divider.withAlpha(50),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        const Text(
                          'Block Actions',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: onHide,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.divider.withAlpha(50),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: AppColors.divider),

                  const SizedBox(height: 8),

                  // Action items
                  _buildActionItem(
                    Icons.transform,
                    'Convert Type',
                    () => _showConvertSubmenu(context),
                    description: 'Change block type',
                  ),

                  _buildActionItem(Icons.content_copy, 'Duplicate', () {
                    onDuplicate();
                    onHide();
                  }, description: 'Copy this block'),

                  _buildActionItem(
                    Icons.palette_outlined,
                    'Style',
                    () {
                      onChangeColor();
                      onHide();
                    },
                    description: 'Change appearance',
                  ),

                  const SizedBox(height: 8),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 8),

                  // Destructive action
                  _buildActionItem(
                    Icons.delete_outline,
                    'Delete',
                    () {
                      onDelete();
                      onHide();
                    },
                    description: 'Remove this block',
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Enhanced action item with description
  Widget _buildActionItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    String? description,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color:
                        isDestructive
                            ? Colors.red.withAlpha(20)
                            : AppColors.accent.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: isDestructive ? Colors.red : AppColors.accent,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color:
                              isDestructive
                                  ? Colors.red
                                  : AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: TextStyle(
                            color:
                                isDestructive
                                    ? Colors.red.withAlpha(150)
                                    : AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Show convert block type submenu with better layout
  void _showConvertSubmenu(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.divider,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Convert to...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.textSecondary,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Text blocks section
                        _buildTypeSection('Text Blocks', [
                          BlockType.text,
                          BlockType.heading,
                        ]),

                        const SizedBox(height: 20),

                        // List blocks section
                        _buildTypeSection('Lists', [
                          BlockType.bulletList,
                          BlockType.numberedList,
                          BlockType.todoList,
                        ]),

                        const SizedBox(height: 20),

                        // Special blocks section
                        _buildTypeSection('Special', [
                          BlockType.quote,
                          BlockType.code,
                          BlockType.callout,
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    ).then((_) => onHide());
  }

  // Build section with multiple block types
  Widget _buildTypeSection(String title, List<BlockType> types) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ...types.map((type) => _buildTypeOption(type)),
      ],
    );
  }

  // Build individual type option
  Widget _buildTypeOption(BlockType type) {
    return Builder(
      builder:
          (context) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  onConvert(type);
                  onHide();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
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
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _getBlockTypeColor(type).withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getBlockTypeIcon(type),
                          size: 18,
                          color: _getBlockTypeColor(type),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          _getBlockTypeName(type),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  // Helper methods for block type info
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
}
