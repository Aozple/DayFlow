import 'package:flutter/material.dart';
import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/note_block.dart';

class BlockTypeSelector extends StatelessWidget {
  final Function(BlockType) onBlockSelected;

  const BlockTypeSelector({super.key, required this.onBlockSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75, // Limit height
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.divider, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Add Block',
                  style: TextStyle(
                    fontSize: 20,
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
              padding: const EdgeInsets.all(20),
              children: [
                // Text blocks section
                _buildCategorySection('Text', [
                  const _BlockOption(
                    BlockType.text,
                    Icons.text_fields,
                    'Text',
                    'Plain text paragraph',
                  ),
                  const _BlockOption(
                    BlockType.heading,
                    Icons.title,
                    'Heading',
                    'Large section heading',
                  ),
                ]),

                const SizedBox(height: 24),

                // List blocks section
                _buildCategorySection('Lists', [
                  const _BlockOption(
                    BlockType.bulletList,
                    Icons.format_list_bulleted,
                    'Bullet List',
                    'Unordered list',
                  ),
                  const _BlockOption(
                    BlockType.numberedList,
                    Icons.format_list_numbered,
                    'Numbered List',
                    'Ordered list',
                  ),
                  const _BlockOption(
                    BlockType.todoList,
                    Icons.checklist,
                    'Todo List',
                    'Checkable task list',
                  ),
                ]),

                const SizedBox(height: 24),

                // Special blocks section
                _buildCategorySection('Special', [
                  const _BlockOption(
                    BlockType.quote,
                    Icons.format_quote,
                    'Quote',
                    'Quotation or citation',
                  ),
                  const _BlockOption(
                    BlockType.code,
                    Icons.code,
                    'Code',
                    'Code snippet',
                  ),
                  const _BlockOption(
                    BlockType.toggle,
                    Icons.keyboard_arrow_right,
                    'Toggle',
                    'Collapsible content',
                  ),
                  const _BlockOption(
                    BlockType.callout,
                    Icons.info,
                    'Callout',
                    'Highlighted information',
                  ),
                ]),
              ],
            ),
          ),

          // Bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  // Build category section with title and options
  Widget _buildCategorySection(String title, List<_BlockOption> options) {
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
        ...options.map((option) => _buildBlockOption(option)),
      ],
    );
  }

  // Build individual block option
  Widget _buildBlockOption(_BlockOption option) {
    return Builder(
      builder:
          (context) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  onBlockSelected(option.type);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight.withAlpha(50),
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
                          color: _getBlockTypeColor(option.type).withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          option.icon,
                          size: 20,
                          color: _getBlockTypeColor(option.type),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              option.description,
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

                      // Arrow
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
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
      case BlockType.callout:
        return Colors.yellow;
      default:
        return AppColors.textSecondary;
    }
  }
}

// Helper class for block options
class _BlockOption {
  final BlockType type;
  final IconData icon;
  final String title;
  final String description;

  const _BlockOption(this.type, this.icon, this.title, this.description);
}
