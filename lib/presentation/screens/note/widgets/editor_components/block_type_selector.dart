import 'package:dayflow/presentation/widgets/draggable_modal.dart';
import 'package:flutter/material.dart';
import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/note_block.dart';

class BlockTypeSelector extends StatelessWidget {
  final Function(BlockType) onBlockSelected;

  const BlockTypeSelector({super.key, required this.onBlockSelected});

  @override
  Widget build(BuildContext context) {
    return DraggableModal(
      title: 'Add Block',
      initialHeight: MediaQuery.of(context).size.height * 0.6,
      minHeight: 300,
      allowFullScreen: true,
      onClose: () => Navigator.pop(context),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCategorySection(context, 'Text', [
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

        _buildCategorySection(context, 'Lists', [
          const _BlockOption(
            BlockType.todoList,
            Icons.checklist,
            'Todo List',
            'Checkable task list',
          ),
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
        ]),

        const SizedBox(height: 24),

        _buildCategorySection(context, 'Special', [
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

        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
      ],
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String title,
    List<_BlockOption> options,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        ...options.map((option) => _buildBlockOption(context, option)),
      ],
    );
  }

  Widget _buildBlockOption(BuildContext context, _BlockOption option) {
    return Container(
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
    );
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
        return Colors.amber;
      case BlockType.picture:
        return Colors.teal;
    }
  }
}

class _BlockOption {
  final BlockType type;
  final IconData icon;
  final String title;
  final String description;

  const _BlockOption(this.type, this.icon, this.title, this.description);
}
