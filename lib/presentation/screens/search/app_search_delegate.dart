import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:dayflow/core/constants/app_colors.dart';
import 'widgets/search_results_view.dart';

class AppSearchDelegate extends SearchDelegate<void> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  AppSearchDelegate()
    : super(
        searchFieldLabel: 'Search tasks, habits, notes...',
        keyboardType: TextInputType.text,
      );

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: AppColors.textSecondary),
        border: InputBorder.none,
      ),
      textTheme: Theme.of(context).textTheme.copyWith(
        titleLarge: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget buildLeading(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => close(context, null),
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider.withAlpha(50), width: 1),
        ),
        child: const Icon(
          CupertinoIcons.back,
          color: AppColors.textPrimary,
          size: 18,
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
          child: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.divider.withAlpha(50),
                width: 1,
              ),
            ),
            child: const Icon(
              CupertinoIcons.clear_circled_solid,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ),
        ),
    ];
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SearchResultsView(searchQuery: query),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SearchResultsView(searchQuery: query),
    );
  }

  @override
  PreferredSizeWidget? buildBottom(BuildContext context) => null;

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: buildLeading(context),
        actions: buildActions(context),
        title: _buildCustomSearchField(context),
        titleSpacing: 0,
        bottom: buildBottom(context),
      ),
      body: query.isEmpty ? buildSuggestions(context) : buildResults(context),
    );
  }

  Widget _buildCustomSearchField(BuildContext context) {
    if (_controller.text != query) {
      _controller.text = query;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              _focusNode.hasFocus
                  ? AppColors.accent.withAlpha(60)
                  : AppColors.divider.withAlpha(50),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 12, right: 8),
            child: Icon(
              CupertinoIcons.search,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search tasks, notes, habits...',
                hintStyle: TextStyle(
                  color: AppColors.textTertiary.withAlpha(150),
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                query = value;
              },
              onSubmitted: (_) => showResults(context),
            ),
          ),
        ],
      ),
    );
  }
}
