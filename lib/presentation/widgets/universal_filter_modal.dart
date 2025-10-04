import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/habit_model.dart';
import 'draggable_modal.dart';

class UniversalFilterOptions {
  final bool showTasks;
  final bool showHabits;
  final bool showNotes;

  final List<String> tagFilters;
  final TimeRangeFilter? timeRange;
  final SortBy sortBy;
  final bool sortAscending;

  final List<int> priorities;
  final bool? isCompleted;

  final List<HabitFrequency> frequencies;
  final bool? isActive;
  final int? minStreak;

  const UniversalFilterOptions({
    this.showTasks = true,
    this.showHabits = true,
    this.showNotes = true,
    this.tagFilters = const [],
    this.timeRange,
    this.sortBy = SortBy.date,
    this.sortAscending = false,
    this.priorities = const [],
    this.isCompleted,
    this.frequencies = const [],
    this.isActive,
    this.minStreak,
  });

  bool get hasActiveFilters {
    return tagFilters.isNotEmpty ||
        priorities.isNotEmpty ||
        isCompleted != null ||
        frequencies.isNotEmpty ||
        isActive != null ||
        minStreak != null ||
        timeRange != null ||
        !showTasks ||
        !showHabits ||
        !showNotes ||
        sortBy != SortBy.date ||
        sortAscending != false;
  }

  factory UniversalFilterOptions.copyWith({
    required UniversalFilterOptions old,
    bool? showTasks,
    bool? showHabits,
    bool? showNotes,
    List<String>? tagFilters,
    bool clearTags = false,
    TimeRangeFilter? timeRange,
    bool clearTimeRange = false,
    SortBy? sortBy,
    bool? sortAscending,
    List<int>? priorities,
    bool clearPriorities = false,
    bool? isCompleted,
    bool clearCompleted = false,
    List<HabitFrequency>? frequencies,
    bool clearFrequencies = false,
    bool? isActive,
    bool clearActive = false,
    int? minStreak,
    bool clearStreak = false,
  }) {
    return UniversalFilterOptions(
      showTasks: showTasks ?? old.showTasks,
      showHabits: showHabits ?? old.showHabits,
      showNotes: showNotes ?? old.showNotes,
      tagFilters: clearTags ? [] : (tagFilters ?? old.tagFilters),
      timeRange: clearTimeRange ? null : (timeRange ?? old.timeRange),
      sortBy: sortBy ?? old.sortBy,
      sortAscending: sortAscending ?? old.sortAscending,
      priorities: clearPriorities ? [] : (priorities ?? old.priorities),
      isCompleted: clearCompleted ? null : (isCompleted ?? old.isCompleted),
      frequencies: clearFrequencies ? [] : (frequencies ?? old.frequencies),
      isActive: clearActive ? null : (isActive ?? old.isActive),
      minStreak: clearStreak ? null : (minStreak ?? old.minStreak),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UniversalFilterOptions &&
        other.showTasks == showTasks &&
        other.showHabits == showHabits &&
        other.showNotes == showNotes &&
        listEquals(other.tagFilters, tagFilters) &&
        other.timeRange == timeRange &&
        other.sortBy == sortBy &&
        other.sortAscending == sortAscending &&
        listEquals(other.priorities, priorities) &&
        other.isCompleted == isCompleted &&
        listEquals(other.frequencies, frequencies) &&
        other.isActive == isActive &&
        other.minStreak == minStreak;
  }

  @override
  int get hashCode => Object.hash(
    showTasks,
    showHabits,
    showNotes,
    Object.hashAll(tagFilters),
    timeRange,
    sortBy,
    sortAscending,
    Object.hashAll(priorities),
    isCompleted,
    Object.hashAll(frequencies),
    isActive,
    minStreak,
  );

  bool listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

enum TimeRangeFilter {
  thisWeek,
  nextWeek,
  lastWeek,
  thisMonth,
  nextMonth,
  lastMonth,
}

enum SortBy { date, alphabetical, priority, streak }

class UniversalFilterModal extends StatefulWidget {
  final UniversalFilterOptions initialFilters;
  final List<String> availableTags;

  const UniversalFilterModal({
    super.key,
    required this.initialFilters,
    required this.availableTags,
  });

  @override
  State<UniversalFilterModal> createState() => _UniversalFilterModalState();
}

class _UniversalFilterModalState extends State<UniversalFilterModal> {
  late UniversalFilterOptions _filters;
  late UniversalFilterOptions _lastAppliedFilters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
    _lastAppliedFilters = widget.initialFilters;
  }

  void _updateFilters(UniversalFilterOptions newFilters) {
    HapticFeedback.selectionClick();
    setState(() {
      _filters = newFilters;
    });
  }

  void _resetAll() {
    HapticFeedback.mediumImpact();
    setState(() {
      _filters = const UniversalFilterOptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final showTaskFilters = _filters.showTasks || _filters.showNotes;
    final showHabitFilters = _filters.showHabits;

    return DraggableModal(
      title: 'Filter & Sort',
      initialHeight: 500,
      minHeight: 350,
      rightAction: _buildApplyButton(),
      leftAction: _buildClearAllButton(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContentTypeSection(),

            if (widget.availableTags.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildTagsSection(),
            ],
            const SizedBox(height: 16),
            _buildTimeRangeSection(),

            if (showTaskFilters) ...[
              const SizedBox(height: 16),
              _buildTaskStatusSection(),
              const SizedBox(height: 16),
              _buildPrioritySection(),
            ],

            if (showHabitFilters) ...[
              const SizedBox(height: 16),
              _buildHabitStatusSection(),
              const SizedBox(height: 16),
              _buildFrequencySection(),
              const SizedBox(height: 16),
              _buildStreakSection(),
            ],

            const SizedBox(height: 16),
            _buildSortSection(),
            const SizedBox(height: 72),
          ],
        ),
      ),
    );
  }

  Widget _buildClearAllButton() {
    final hasFilters = _filters.hasActiveFilters;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: hasFilters ? _resetAll : null,
      child: Text(
        'Reset',
        style: TextStyle(
          color:
              hasFilters
                  ? CupertinoColors.destructiveRed
                  : AppColors.textTertiary,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildApplyButton() {
    final hasChanged = _filters != _lastAppliedFilters;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed:
          hasChanged
              ? () {
                _lastAppliedFilters = _filters;
                Navigator.pop(context, _filters);
              }
              : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: hasChanged ? Theme.of(context).colorScheme.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasChanged ? Theme.of(context).colorScheme.primary : AppColors.divider,
            width: 1,
          ),
        ),
        child: Text(
          'Apply',
          style: TextStyle(
            color: hasChanged ? Colors.white : AppColors.textTertiary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    VoidCallback? onClear,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        if (onClear != null)
          GestureDetector(
            onTap: onClear,
            child: Text(
              'Clear',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContentTypeSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: CupertinoIcons.square_grid_2x2,
            title: 'Show Content',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildToggleButton(
                  'Tasks',
                  _filters.showTasks,
                  () => _updateFilters(
                    UniversalFilterOptions.copyWith(
                      old: _filters,
                      showTasks: !_filters.showTasks,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildToggleButton(
                  'Habits',
                  _filters.showHabits,
                  () => _updateFilters(
                    UniversalFilterOptions.copyWith(
                      old: _filters,
                      showHabits: !_filters.showHabits,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildToggleButton(
                  'Notes',
                  _filters.showNotes,
                  () => _updateFilters(
                    UniversalFilterOptions.copyWith(
                      old: _filters,
                      showNotes: !_filters.showNotes,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    final hasSelection = _filters.tagFilters.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: CupertinoIcons.tag,
            title: 'Tags',
            onClear:
                hasSelection
                    ? () => _updateFilters(
                      UniversalFilterOptions.copyWith(
                        old: _filters,
                        clearTags: true,
                      ),
                    )
                    : null,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                widget.availableTags.map((tag) {
                  final isSelected = _filters.tagFilters.contains(tag);
                  return _buildChip(tag, isSelected, () {
                    final newTags = List<String>.from(_filters.tagFilters);
                    if (isSelected) {
                      newTags.remove(tag);
                    } else {
                      newTags.add(tag);
                    }
                    _updateFilters(
                      UniversalFilterOptions.copyWith(
                        old: _filters,
                        tagFilters: newTags,
                      ),
                    );
                  });
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskStatusSection() {
    final hasSelection = _filters.isCompleted != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: CupertinoIcons.checkmark_circle,
            title: 'Task Status',
            onClear:
                hasSelection
                    ? () => _updateFilters(
                      UniversalFilterOptions.copyWith(
                        old: _filters,
                        clearCompleted: true,
                      ),
                    )
                    : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildChip(
                  'Active',
                  _filters.isCompleted == false,
                  () => _updateFilters(
                    UniversalFilterOptions.copyWith(
                      old: _filters,
                      isCompleted: _filters.isCompleted == false ? null : false,
                      clearCompleted: _filters.isCompleted == false,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildChip(
                  'Completed',
                  _filters.isCompleted == true,
                  () => _updateFilters(
                    UniversalFilterOptions.copyWith(
                      old: _filters,
                      isCompleted: _filters.isCompleted == true ? null : true,
                      clearCompleted: _filters.isCompleted == true,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHabitStatusSection() {
    final hasSelection = _filters.isActive != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: CupertinoIcons.power,
            title: 'Habit Status',
            onClear:
                hasSelection
                    ? () => _updateFilters(
                      UniversalFilterOptions.copyWith(
                        old: _filters,
                        clearActive: true,
                      ),
                    )
                    : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildChip(
                  'Active',
                  _filters.isActive == true,
                  () => _updateFilters(
                    UniversalFilterOptions.copyWith(
                      old: _filters,
                      isActive: _filters.isActive == true ? null : true,
                      clearActive: _filters.isActive == true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildChip(
                  'Inactive',
                  _filters.isActive == false,
                  () => _updateFilters(
                    UniversalFilterOptions.copyWith(
                      old: _filters,
                      isActive: _filters.isActive == false ? null : false,
                      clearActive: _filters.isActive == false,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritySection() {
    final hasSelection = _filters.priorities.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: CupertinoIcons.flag,
            title: 'Priority',
            onClear:
                hasSelection
                    ? () => _updateFilters(
                      UniversalFilterOptions.copyWith(
                        old: _filters,
                        clearPriorities: true,
                      ),
                    )
                    : null,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(5, (index) {
              final priority = index + 1;
              final isSelected = _filters.priorities.contains(priority);
              return _buildChip('P$priority', isSelected, () {
                final newPriorities = List<int>.from(_filters.priorities);
                if (isSelected) {
                  newPriorities.remove(priority);
                } else {
                  newPriorities.add(priority);
                }
                _updateFilters(
                  UniversalFilterOptions.copyWith(
                    old: _filters,
                    priorities: newPriorities,
                  ),
                );
              });
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencySection() {
    final hasSelection = _filters.frequencies.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: CupertinoIcons.repeat,
            title: 'Frequency',
            onClear:
                hasSelection
                    ? () => _updateFilters(
                      UniversalFilterOptions.copyWith(
                        old: _filters,
                        clearFrequencies: true,
                      ),
                    )
                    : null,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                HabitFrequency.values.map((frequency) {
                  final isSelected = _filters.frequencies.contains(frequency);
                  return _buildChip(
                    _getFrequencyLabel(frequency),
                    isSelected,
                    () {
                      final newFrequencies = List<HabitFrequency>.from(
                        _filters.frequencies,
                      );
                      if (isSelected) {
                        newFrequencies.remove(frequency);
                      } else {
                        newFrequencies.add(frequency);
                      }
                      _updateFilters(
                        UniversalFilterOptions.copyWith(
                          old: _filters,
                          frequencies: newFrequencies,
                        ),
                      );
                    },
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSection() {
    final hasSelection = _filters.timeRange != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: CupertinoIcons.calendar,
            title: 'Time Range',
            onClear:
                hasSelection
                    ? () => _updateFilters(
                      UniversalFilterOptions.copyWith(
                        old: _filters,
                        clearTimeRange: true,
                      ),
                    )
                    : null,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                TimeRangeFilter.values.map((range) {
                  final isSelected = _filters.timeRange == range;
                  return _buildChip(
                    _getTimeRangeLabel(range),
                    isSelected,
                    () => _updateFilters(
                      UniversalFilterOptions.copyWith(
                        old: _filters,
                        timeRange: isSelected ? null : range,
                        clearTimeRange: isSelected,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakSection() {
    final hasSelection = _filters.minStreak != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: CupertinoIcons.flame,
            title: 'Minimum Streak',
            onClear:
                hasSelection
                    ? () => _updateFilters(
                      UniversalFilterOptions.copyWith(
                        old: _filters,
                        clearStreak: true,
                      ),
                    )
                    : null,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                [3, 7, 14, 30, 90].map((streak) {
                  final isSelected = _filters.minStreak == streak;
                  return _buildChip(
                    '$streak+ days',
                    isSelected,
                    () => _updateFilters(
                      UniversalFilterOptions.copyWith(
                        old: _filters,
                        minStreak: isSelected ? null : streak,
                        clearStreak: isSelected,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSortSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(icon: CupertinoIcons.sort_down, title: 'Sort'),
          const SizedBox(height: 12),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                SortBy.values.map((sortBy) {
                  final isSelected = _filters.sortBy == sortBy;
                  return _buildChip(
                    _getSortLabel(sortBy),
                    isSelected,
                    () => _updateFilters(
                      UniversalFilterOptions.copyWith(
                        old: _filters,
                        sortBy: sortBy,
                      ),
                    ),
                  );
                }).toList(),
          ),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider.withAlpha(40)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap:
                        () => _updateFilters(
                          UniversalFilterOptions.copyWith(
                            old: _filters,
                            sortAscending: true,
                          ),
                        ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            _filters.sortAscending
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.arrow_up,
                            size: 14,
                            color:
                                _filters.sortAscending
                                    ? Colors.white
                                    : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ascending',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color:
                                  _filters.sortAscending
                                      ? Colors.white
                                      : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap:
                        () => _updateFilters(
                          UniversalFilterOptions.copyWith(
                            old: _filters,
                            sortAscending: false,
                          ),
                        ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            !_filters.sortAscending
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.arrow_down,
                            size: 14,
                            color:
                                !_filters.sortAscending
                                    ? Colors.white
                                    : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Descending',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color:
                                  !_filters.sortAscending
                                      ? Colors.white
                                      : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected ? Theme.of(context).colorScheme.primary : AppColors.divider.withAlpha(60),
            width: 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary.withAlpha(20)
                  : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color:
                isSelected ? Theme.of(context).colorScheme.primary : AppColors.divider.withAlpha(60),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Theme.of(context).colorScheme.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  String _getFrequencyLabel(HabitFrequency frequency) {
    switch (frequency) {
      case HabitFrequency.daily:
        return 'Daily';
      case HabitFrequency.weekly:
        return 'Weekly';
      case HabitFrequency.monthly:
        return 'Monthly';
      case HabitFrequency.custom:
        return 'Custom';
    }
  }

  String _getTimeRangeLabel(TimeRangeFilter range) {
    switch (range) {
      case TimeRangeFilter.thisWeek:
        return 'This Week';
      case TimeRangeFilter.nextWeek:
        return 'Next Week';
      case TimeRangeFilter.lastWeek:
        return 'Last Week';
      case TimeRangeFilter.thisMonth:
        return 'This Month';
      case TimeRangeFilter.nextMonth:
        return 'Next Month';
      case TimeRangeFilter.lastMonth:
        return 'Last Month';
    }
  }

  String _getSortLabel(SortBy sortBy) {
    switch (sortBy) {
      case SortBy.date:
        return 'Date';
      case SortBy.alphabetical:
        return 'Name';
      case SortBy.priority:
        return 'Priority';
      case SortBy.streak:
        return 'Streak';
    }
  }
}
