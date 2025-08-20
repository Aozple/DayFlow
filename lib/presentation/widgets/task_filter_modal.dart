import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../core/constants/app_colors.dart';

// This class holds the selected filter options for tasks.
class TaskFilterOptions {
  // Optional filter for the task's due date (today, this week, this month, or custom).
  final DateFilter? dateFilter;
  // Optional filter for the task's priority (1 to 5).
  final int? priorityFilter;
  // Optional filter for the task's completion status (true for completed, false for active).
  final bool? completedFilter;
  // A list of tags to filter tasks by.
  final List<String> tagFilters;
  // The sorting option to apply to the filtered tasks.
  final SortOption sortBy;

  TaskFilterOptions({
    this.dateFilter,
    this.priorityFilter,
    this.completedFilter,
    this.tagFilters = const [], // Default to an empty list.
    this.sortBy = SortOption.dateDesc, // Default to sorting by date descending.
  });
}

// Enum defining the possible date filter options.
enum DateFilter { today, thisWeek, thisMonth, custom }

// Enum defining the possible sorting options.
enum SortOption {
  dateDesc, // Newest first.
  dateAsc, // Oldest first.
  priorityDesc, // High priority first.
  priorityAsc, // Low priority first.
  alphabetical, // A-Z.
}

// This widget creates a modal bottom sheet for filtering tasks.
class TaskFilterModal extends StatefulWidget {
  // The initial filter options to pre-select in the modal.
  final TaskFilterOptions initialFilters;
  // A list of all available tags to display as filter options.
  final List<String> availableTags;

  const TaskFilterModal({
    super.key,
    required this.initialFilters,
    required this.availableTags,
  });

  @override
  State<TaskFilterModal> createState() => _TaskFilterModalState();
}

// The state class for our TaskFilterModal, managing the selected filters.
class _TaskFilterModalState extends State<TaskFilterModal> {
  late TaskFilterOptions _filters; // The currently selected filter options.

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters; // Initialize with the provided initial filters.
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75, // Take up 75% of the screen height.
      decoration: const BoxDecoration(
        color: AppColors.surface, // Background color.
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)), // Rounded top corners.
      ),
      child: Column(
        children: [
          // Header with "Cancel" and "Apply" buttons.
          _buildHeader(),

          // The main filter options area.
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Sections for different filter types.
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

  // Builds the header section of the modal with "Cancel" and "Apply" buttons.
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5), // Bottom border.
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context), // Close the modal.
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ),
          const Text(
            'Filter Tasks', // Title of the modal.
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              // Return the selected filters to the caller.
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

  // Builds the date filter section with options like "Today", "This Week", "This Month".
  Widget _buildDateFilter() {
    return _buildSection(
      title: 'Date',
      icon: CupertinoIcons.calendar, // Calendar icon.
      child: Wrap(
        spacing: 8, // Horizontal spacing between chips.
        runSpacing: 8, // Vertical spacing between rows of chips.
        children: [
          // Filter chip for "Today".
          _buildFilterChip(
            label: 'Today',
            isSelected: _filters.dateFilter == DateFilter.today, // Check if this filter is selected.
            onTap: () {
              setState(() {
                // Toggle the "Today" filter.
                _filters = TaskFilterOptions(
                  dateFilter:
                      _filters.dateFilter == DateFilter.today
                          ? null // Deselect if already selected.
                          : DateFilter.today, // Select if not selected.
                  priorityFilter: _filters.priorityFilter,
                  completedFilter: _filters.completedFilter,
                  tagFilters: _filters.tagFilters,
                  sortBy: _filters.sortBy,
                );
              });
            },
          ),
          // Filter chip for "This Week".
          _buildFilterChip(
            label: 'This Week',
            isSelected: _filters.dateFilter == DateFilter.thisWeek,
            onTap: () {
              setState(() {
                // Toggle the "This Week" filter.
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
          // Filter chip for "This Month".
          _buildFilterChip(
            label: 'This Month',
            isSelected: _filters.dateFilter == DateFilter.thisMonth,
            onTap: () {
              setState(() {
                // Toggle the "This Month" filter.
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

  // A reusable widget to build a section container with a title and icon.
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background, // Background color for the section.
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary), // Section icon.
              const SizedBox(width: 8),
              Text(
                title, // Section title.
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child, // The content of the section.
        ],
      ),
    );
  }

  // A reusable widget to build a filter chip (selectable button).
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap, // Call the provided function when tapped.
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), // Smooth animation.
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surfaceLight, // Accent color if selected.
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.divider,
          ),
        ),
        child: Text(
          label, // The chip's label.
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary, // White text if selected.
          ),
        ),
      ),
    );
  }

  // Builds the status filter section with options for "Active" and "Completed".
  Widget _buildStatusFilter() {
    return _buildSection(
      title: 'Status',
      icon: CupertinoIcons.check_mark_circled, // Checkmark icon.
      child: Row(
        children: [
          // Filter chip for "Active" tasks.
          Expanded(
            child: _buildFilterChip(
              label: 'Active',
              isSelected: _filters.completedFilter == false, // Check if "Active" is selected.
              onTap: () {
                setState(() {
                  // Toggle the "Active" filter.
                  _filters = TaskFilterOptions(
                    dateFilter: _filters.dateFilter,
                    priorityFilter: _filters.priorityFilter,
                    completedFilter:
                        _filters.completedFilter == false ? null : false, // Deselect if already selected.
                    tagFilters: _filters.tagFilters,
                    sortBy: _filters.sortBy,
                  );
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          // Filter chip for "Completed" tasks.
          Expanded(
            child: _buildFilterChip(
              label: 'Completed',
              isSelected: _filters.completedFilter == true, // Check if "Completed" is selected.
              onTap: () {
                setState(() {
                  // Toggle the "Completed" filter.
                  _filters = TaskFilterOptions(
                    dateFilter: _filters.dateFilter,
                    priorityFilter: _filters.priorityFilter,
                    completedFilter:
                        _filters.completedFilter == true ? null : true, // Deselect if already selected.
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

  // Builds the priority filter section with options for priority levels 1 to 5.
  Widget _buildPriorityFilter() {
    return _buildSection(
      title: 'Priority',
      icon: CupertinoIcons.flag, // Flag icon.
      child: Wrap(
        spacing: 8, // Horizontal spacing between chips.
        runSpacing: 8, // Vertical spacing between rows of chips.
        children: List.generate(5, (index) {
          final priority = index + 1; // Priority levels 1 to 5.
          return _buildFilterChip(
            label: 'P$priority', // "P1", "P2", etc.
            isSelected: _filters.priorityFilter == priority, // Check if this priority is selected.
            onTap: () {
              setState(() {
                // Toggle the selected priority filter.
                _filters = TaskFilterOptions(
                  dateFilter: _filters.dateFilter,
                  priorityFilter:
                      _filters.priorityFilter == priority ? null : priority, // Deselect if already selected.
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

  // Builds the tag filter section, allowing users to filter by available tags.
  Widget _buildTagFilter() {
    // If there are no tags available, don't show this section.
    if (widget.availableTags.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Tags',
      icon: CupertinoIcons.tag, // Tag icon.
      child: Wrap(
        spacing: 8, // Horizontal spacing between chips.
        runSpacing: 8, // Vertical spacing between rows of chips.
        children:
            widget.availableTags.map((tag) {
              final isSelected = _filters.tagFilters.contains(tag); // Check if this tag is selected.
              return _buildFilterChip(
                label: tag,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    final newTags = List<String>.from(_filters.tagFilters); // Copy existing tags.
                    if (isSelected) {
                      newTags.remove(tag); // Remove tag if already selected.
                    } else {
                      newTags.add(tag); // Add tag if not selected.
                    }

                    // Update the filter options with the new tag list.
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

  // Builds the sort options section, allowing users to sort tasks by date, priority, or alphabetically.
  Widget _buildSortOptions() {
    return _buildSection(
      title: 'Sort By',
      icon: CupertinoIcons.sort_down, // Sort icon.
      child: Column(
        children: [
          // Sort by "Newest First".
          _buildSortOption(
            'Newest First',
            SortOption.dateDesc,
            CupertinoIcons.clock_fill,
          ),
          // Sort by "Oldest First".
          _buildSortOption(
            'Oldest First',
            SortOption.dateAsc,
            CupertinoIcons.clock,
          ),
          // Sort by "High Priority First".
          _buildSortOption(
            'High Priority First',
            SortOption.priorityDesc,
            CupertinoIcons.flag_fill,
          ),
          // Sort by "Low Priority First".
          _buildSortOption(
            'Low Priority First',
            SortOption.priorityAsc,
            CupertinoIcons.flag,
          ),
          // Sort Alphabetically.
          _buildSortOption(
            'Alphabetical',
            SortOption.alphabetical,
            CupertinoIcons.textformat,
          ),
        ],
      ),
    );
  }

  // Helper widget to build a single sort option (radio button-like).
  Widget _buildSortOption(String label, SortOption option, IconData icon) {
    final isSelected = _filters.sortBy == option; // Check if this option is selected.

    return ListTile(
      onTap: () {
        setState(() {
          // Update the selected sort option.
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
        color: isSelected ? AppColors.accent : AppColors.textSecondary, // Accent color if selected.
      ),
      title: Text(
        label, // The sort option label.
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, // Bold if selected.
          color: isSelected ? AppColors.accent : AppColors.textPrimary,
        ),
      ),
      trailing:
          isSelected
              ? Icon(
                CupertinoIcons.checkmark, // Checkmark if selected.
                size: 18,
                color: AppColors.accent,
              )
              : null, // No checkmark if not selected.
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }
}
