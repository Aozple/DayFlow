import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dayflow/core/constants/app_colors.dart';
import '../models/search_result.dart';
import 'search_result_item.dart';

class SearchCategorySection extends StatefulWidget {
  final SearchResultType type;
  final List<SearchResult> results;
  final bool isExpanded;
  final String searchQuery;
  final VoidCallback onToggleExpanded;
  final Function(SearchResult) onResultTap;

  const SearchCategorySection({
    super.key,
    required this.type,
    required this.results,
    required this.isExpanded,
    required this.searchQuery,
    required this.onToggleExpanded,
    required this.onResultTap,
  });

  @override
  State<SearchCategorySection> createState() => _SearchCategorySectionState();
}

class _SearchCategorySectionState extends State<SearchCategorySection>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _iconRotation;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _iconRotation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.easeOut),
    );
    
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOut,
    );

    if (widget.isExpanded) {
      _expandController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SearchCategorySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExpanded != widget.isExpanded) {
      if (widget.isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withAlpha(30), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onToggleExpanded();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _getCategoryColor().withAlpha(8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getCategoryColor(),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _getCategoryColor().withAlpha(30),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                _getCategoryIcon(),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getCategoryTitle(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.isExpanded 
                        ? 'Tap to collapse'
                        : '${widget.results.length} ${widget.results.length == 1 ? 'item' : 'items'}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.isExpanded 
                          ? AppColors.textSecondary
                          : _getCategoryColor(),
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: _iconRotation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _iconRotation.value * 3.14159,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.chevron_down,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (!widget.isExpanded) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          Container(
            height: 1,
            margin: const EdgeInsets.only(bottom: 20),
            color: AppColors.divider.withAlpha(30),
          ),
          ...widget.results.asMap().entries.map((entry) {
            final index = entry.key;
            final result = entry.value;
            return Column(
              children: [
                SearchResultItem(
                  result: result,
                  searchQuery: widget.searchQuery,
                  onTap: () => widget.onResultTap(result),
                ),
                if (index < widget.results.length - 1)
                  const SizedBox(height: 16),
              ],
            );
          }),
        ],
      ),
    );
  }

  String _getCategoryTitle() {
    switch (widget.type) {
      case SearchResultType.task:
        return 'Tasks';
      case SearchResultType.note:
        return 'Notes';
      case SearchResultType.habit:
        return 'Habits';
    }
  }

  IconData _getCategoryIcon() {
    switch (widget.type) {
      case SearchResultType.task:
        return CupertinoIcons.checkmark_circle_fill;
      case SearchResultType.note:
        return CupertinoIcons.doc_text_fill;
      case SearchResultType.habit:
        return CupertinoIcons.repeat;
    }
  }

  Color _getCategoryColor() {
    switch (widget.type) {
      case SearchResultType.task:
        return Theme.of(context).colorScheme.primary;
      case SearchResultType.note:
        return AppColors.info;
      case SearchResultType.habit:
        return AppColors.success;
    }
  }
}