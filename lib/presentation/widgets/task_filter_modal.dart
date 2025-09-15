import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../core/constants/app_colors.dart';

// Task filter options data model
class TaskFilterOptions {
  final DateFilter? dateFilter;
  final int? priorityFilter;
  final bool? completedFilter;
  final List<String> tagFilters;
  final SortOption sortBy;

  TaskFilterOptions({
    this.dateFilter,
    this.priorityFilter,
    this.completedFilter,
    this.tagFilters = const [],
    this.sortBy = SortOption.dateDesc,
  });
}

// Date filter options
enum DateFilter { today, thisWeek, thisMonth, custom }

// Sort options
enum SortOption { dateDesc, dateAsc, priorityDesc, priorityAsc, alphabetical }

// Modal for filtering and sorting tasks
class TaskFilterModal extends StatefulWidget {
  final TaskFilterOptions initialFilters;
  final List<String> availableTags;

  const TaskFilterModal({
    super.key,
    required this.initialFilters,
    required this.availableTags,
  });

  @override
  State<TaskFilterModal> createState() => _TaskFilterModalState();
}

class _TaskFilterModalState extends State<TaskFilterModal> {
  late TaskFilterOptions _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header with actions
          _buildHeader(),

          // Filter options
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildDateFilter(),
                const SizedBox(height: 20),
                _buildStatusFilter(),
                const SizedBox(height: 20),
                _buildPriorityFilter(),
                const SizedBox(height: 20),
                _buildTagFilter(),
                const SizedBox(height: 20),
                _buildSortOptions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Header with Cancel and Apply buttons
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ),
          const Text(
            'Filter Tasks',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              Navigator.pop(context, _filters);
            },
            child: Text(
              'Apply',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Date filter options
  Widget _buildDateFilter() {
    return _buildSection(
      title: 'Date',
      icon: CupertinoIcons.calendar,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // Today filter
          _buildFilterChip(
            label: 'Today',
            isSelected: _filters.dateFilter == DateFilter.today,
            onTap: () {
              setState(() {
                _filters = TaskFilterOptions(
                  dateFilter:
                      _filters.dateFilter == DateFilter.today
                          ? null
                          : DateFilter.today,
                  priorityFilter: _filters.priorityFilter,
                  completedFilter: _filters.completedFilter,
                  tagFilters: _filters.tagFilters,
                  sortBy: _filters.sortBy,
                );
              });
            },
          ),
          // This Week filter
          _buildFilterChip(
            label: 'This Week',
            isSelected: _filters.dateFilter == DateFilter.thisWeek,
            onTap: () {
              setState(() {
                _filters = TaskFilterOptions(
                  dateFilter:
                      _filters.dateFilter == DateFilter.thisWeek
                          ? null
                          : DateFilter.thisWeek,
                  priorityFilter: _filters.priorityFilter,
                  completedFilter: _filters.completedFilter,
                  tagFilters: _filters.tagFilters,
                  sortBy: _filters.sortBy,
                );
              });
            },
          ),
          // This Month filter
          _buildFilterChip(
            label: 'This Month',
            isSelected: _filters.dateFilter == DateFilter.thisMonth,
            onTap: () {
              setState(() {
                _filters = TaskFilterOptions(
                  dateFilter:
                      _filters.dateFilter == DateFilter.thisMonth
                          ? null
                          : DateFilter.thisMonth,
                  priorityFilter: _filters.priorityFilter,
                  completedFilter: _filters.completedFilter,
                  tagFilters: _filters.tagFilters,
                  sortBy: _filters.sortBy,
                );
              });
            },
          ),
        ],
      ),
    );
  }

  // Section container with title and icon
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // Selectable filter chip
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  // Status filter (Active/Completed)
  Widget _buildStatusFilter() {
    return _buildSection(
      title: 'Status',
      icon: CupertinoIcons.check_mark_circled,
      child: Row(
        children: [
          // Active filter
          Expanded(
            child: _buildFilterChip(
              label: 'Active',
              isSelected: _filters.completedFilter == false,
              onTap: () {
                setState(() {
                  _filters = TaskFilterOptions(
                    dateFilter: _filters.dateFilter,
                    priorityFilter: _filters.priorityFilter,
                    completedFilter:
                        _filters.completedFilter == false ? null : false,
                    tagFilters: _filters.tagFilters,
                    sortBy: _filters.sortBy,
                  );
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          // Completed filter
          Expanded(
            child: _buildFilterChip(
              label: 'Completed',
              isSelected: _filters.completedFilter == true,
              onTap: () {
                setState(() {
                  _filters = TaskFilterOptions(
                    dateFilter: _filters.dateFilter,
                    priorityFilter: _filters.priorityFilter,
                    completedFilter:
                        _filters.completedFilter == true ? null : true,
                    tagFilters: _filters.tagFilters,
                    sortBy: _filters.sortBy,
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // Priority filter (P1-P5)
  Widget _buildPriorityFilter() {
    return _buildSection(
      title: 'Priority',
      icon: CupertinoIcons.flag,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(5, (index) {
          final priority = index + 1;
          return _buildFilterChip(
            label: 'P$priority',
            isSelected: _filters.priorityFilter == priority,
            onTap: () {
              setState(() {
                _filters = TaskFilterOptions(
                  dateFilter: _filters.dateFilter,
                  priorityFilter:
                      _filters.priorityFilter == priority ? null : priority,
                  completedFilter: _filters.completedFilter,
                  tagFilters: _filters.tagFilters,
                  sortBy: _filters.sortBy,
                );
              });
            },
          );
        }),
      ),
    );
  }

  // Tag filter
  Widget _buildTagFilter() {
    if (widget.availableTags.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Tags',
      icon: CupertinoIcons.tag,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            widget.availableTags.map((tag) {
              final isSelected = _filters.tagFilters.contains(tag);
              return _buildFilterChip(
                label: tag,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    final newTags = List<String>.from(_filters.tagFilters);
                    if (isSelected) {
                      newTags.remove(tag);
                    } else {
                      newTags.add(tag);
                    }

                    _filters = TaskFilterOptions(
                      dateFilter: _filters.dateFilter,
                      priorityFilter: _filters.priorityFilter,
                      completedFilter: _filters.completedFilter,
                      tagFilters: newTags,
                      sortBy: _filters.sortBy,
                    );
                  });
                },
              );
            }).toList(),
      ),
    );
  }

  // Sort options
  Widget _buildSortOptions() {
    return _buildSection(
      title: 'Sort By',
      icon: CupertinoIcons.sort_down,
      child: Column(
        children: [
          _buildSortOption(
            'Newest First',
            SortOption.dateDesc,
            CupertinoIcons.clock_fill,
          ),
          _buildSortOption(
            'Oldest First',
            SortOption.dateAsc,
            CupertinoIcons.clock,
          ),
          _buildSortOption(
            'High Priority First',
            SortOption.priorityDesc,
            CupertinoIcons.flag_fill,
          ),
          _buildSortOption(
            'Low Priority First',
            SortOption.priorityAsc,
            CupertinoIcons.flag,
          ),
          _buildSortOption(
            'Alphabetical',
            SortOption.alphabetical,
            CupertinoIcons.textformat,
          ),
        ],
      ),
    );
  }

  // Single sort option
  Widget _buildSortOption(String label, SortOption option, IconData icon) {
    final isSelected = _filters.sortBy == option;

    return ListTile(
      onTap: () {
        setState(() {
          _filters = TaskFilterOptions(
            dateFilter: _filters.dateFilter,
            priorityFilter: _filters.priorityFilter,
            completedFilter: _filters.completedFilter,
            tagFilters: _filters.tagFilters,
            sortBy: option,
          );
        });
      },
      leading: Icon(
        icon,
        size: 20,
        color: isSelected ? AppColors.accent : AppColors.textSecondary,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? AppColors.accent : AppColors.textPrimary,
        ),
      ),
      trailing:
          isSelected
              ? Icon(
                CupertinoIcons.checkmark,
                size: 18,
                color: AppColors.accent,
              )
              : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }
}
