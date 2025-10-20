import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/habit_model.dart';
import 'package:dayflow/presentation/blocs/habits/habit_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dayflow/presentation/blocs/settings/settings_bloc.dart';
import 'home_date_item.dart';
import 'home_week_navigation.dart';

class HomeDateSelector extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const HomeDateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<HomeDateSelector> createState() => _HomeDateSelectorState();
}

class _HomeDateSelectorState extends State<HomeDateSelector> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1);
  }

  @override
  void didUpdateWidget(covariant HomeDateSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSameWeek(oldWidget.selectedDate, widget.selectedDate) &&
        _pageController.hasClients) {
      _pageController.jumpToPage(1);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        final isSaturdayFirst =
            settingsState is SettingsLoaded
                ? settingsState.isSaturdayFirst
                : false;

        return BlocBuilder<TaskBloc, TaskState>(
          builder: (context, taskState) {
            return BlocBuilder<HabitBloc, HabitState>(
              builder: (context, habitState) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.divider.withAlpha(50),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      HomeWeekNavigation(
                        selectedDate: widget.selectedDate,
                        isSaturdayFirst: isSaturdayFirst,
                        onWeekChanged: widget.onDateSelected,
                      ),
                      Container(
                        height: 72,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight.withAlpha(100),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.divider.withAlpha(100),
                            width: 0.5,
                          ),
                        ),
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is ScrollEndNotification) {
                              _handleWeekSwipe();
                            }
                            return true;
                          },
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: 3,
                            itemBuilder: (context, pageIndex) {
                              return _buildWeekView(
                                pageIndex: pageIndex,
                                isSaturdayFirst: isSaturdayFirst,
                                taskState: taskState,
                                habitState: habitState,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildWeekView({
    required int pageIndex,
    required bool isSaturdayFirst,
    required TaskState taskState,
    required HabitState habitState,
  }) {
    final baseWeekStart = _getWeekStart(widget.selectedDate, isSaturdayFirst);
    final weekStartForPage = baseWeekStart.add(
      Duration(days: (pageIndex - 1) * 7),
    );
    final counts = _buildCountsForWeek(weekStartForPage, taskState, habitState);

    return Column(
      children: [
        SizedBox(
          height: 13,
          child: Row(
            children: List.generate(7, (dayIndex) {
              final count = counts[dayIndex] ?? 0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Center(
                    child:
                        (count > 0)
                            ? _CountIndicator(count: count)
                            : const SizedBox.shrink(),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: Row(
            children: List.generate(7, (dayIndex) {
              final date = weekStartForPage.add(Duration(days: dayIndex));
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2.0,
                    vertical: 2.0,
                  ),
                  child: HomeDateItem(
                    date: date,
                    selectedDate: widget.selectedDate,
                    isSaturdayFirst: isSaturdayFirst,
                    onTap: () => widget.onDateSelected(date),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  void _handleWeekSwipe() {
    final currentPage = _pageController.page?.round() ?? 1;
    if (currentPage == 1) return;

    final direction = currentPage == 2 ? 1 : -1;
    final newDate = widget.selectedDate.add(Duration(days: 7 * direction));

    HapticFeedback.selectionClick();
    widget.onDateSelected(newDate);
  }

  Map<int, int> _buildCountsForWeek(
    DateTime weekStart,
    TaskState taskState,
    HabitState habitState,
  ) {
    final counts = {for (var i = 0; i < 7; i++) i: 0};
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final end = start.add(const Duration(days: 6));

    if (taskState is TaskLoaded) {
      for (final t in taskState.tasks) {
        if (t.isDeleted || t.dueDate == null) continue;
        final d = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
        if (!d.isBefore(start) && !d.isAfter(end)) {
          final off = d.difference(start).inDays;
          if (off >= 0 && off < 7) counts[off] = (counts[off] ?? 0) + 1;
        }
      }
    }

    if (habitState is HabitLoaded) {
      for (int i = 0; i < 7; i++) {
        final d = start.add(Duration(days: i));
        for (final h in habitState.habits) {
          if (h.isDeleted) continue;
          if (_habitShownOnDate(h, d)) {
            counts[i] = (counts[i] ?? 0) + 1;
          }
        }
      }
    }
    return counts;
  }

  bool _habitShownOnDate(HabitModel habit, DateTime date) {
    final startDateOnly = DateTime(
      habit.startDate.year,
      habit.startDate.month,
      habit.startDate.day,
    );
    final selectedDateOnly = DateTime(date.year, date.month, date.day);
    if (selectedDateOnly.isBefore(startDateOnly)) return false;

    switch (habit.endCondition) {
      case HabitEndCondition.onDate:
        if (habit.endDate != null) {
          final endDateOnly = DateTime(
            habit.endDate!.year,
            habit.endDate!.month,
            habit.endDate!.day,
          );
          if (selectedDateOnly.isAfter(endDateOnly)) return false;
        }
        break;
      case HabitEndCondition.afterCount:
      case HabitEndCondition.never:
      case HabitEndCondition.manual:
        break;
    }

    switch (habit.frequency) {
      case HabitFrequency.daily:
        return true;
      case HabitFrequency.weekly:
        return habit.weekdays?.contains(selectedDateOnly.weekday) ?? false;
      case HabitFrequency.monthly:
        final targetDay = habit.monthDay ?? 1;
        final lastDayOfMonth =
            DateTime(selectedDateOnly.year, selectedDateOnly.month + 1, 0).day;
        return selectedDateOnly.day ==
            (targetDay > lastDayOfMonth ? lastDayOfMonth : targetDay);
      case HabitFrequency.custom:
        if (habit.customInterval == null) return false;
        final daysDifference =
            selectedDateOnly.difference(startDateOnly).inDays;
        return daysDifference >= 0 &&
            daysDifference % habit.customInterval! == 0;
    }
  }

  DateTime _getWeekStart(DateTime date, bool isSaturdayFirst) {
    if (isSaturdayFirst) {
      final daysToSubtract = (date.weekday % 7) + 1;
      return date.subtract(Duration(days: daysToSubtract % 7));
    }
    return date.subtract(Duration(days: date.weekday - 1));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSameWeek(DateTime a, DateTime b) {
    final startA = _getWeekStart(a, false);
    final startB = _getWeekStart(b, false);
    return _isSameDay(startA, startB);
  }
}

class _CountIndicator extends StatelessWidget {
  final int count;
  const _CountIndicator({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 13,
      constraints: const BoxConstraints(minWidth: 12),
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.0,
        ),
      ),
    );
  }
}
