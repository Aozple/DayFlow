import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/habit_model.dart';
import 'package:dayflow/presentation/widgets/date_picker_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Compact habit end condition selection widget with minimal space usage.
///
/// Provides an efficient interface for setting habit termination conditions
/// including never-ending, date-based, and count-based endings with optimized
/// vertical space consumption while maintaining visual clarity.
class CreateHabitEndConditionSection extends StatefulWidget {
  final HabitEndCondition endCondition;
  final DateTime? endDate;
  final int? targetCount;
  final Function(HabitEndCondition) onEndConditionChanged;
  final Function(DateTime?) onEndDateChanged;
  final Function(int?) onTargetCountChanged;

  const CreateHabitEndConditionSection({
    super.key,
    required this.endCondition,
    required this.endDate,
    required this.targetCount,
    required this.onEndConditionChanged,
    required this.onEndDateChanged,
    required this.onTargetCountChanged,
  });

  @override
  State<CreateHabitEndConditionSection> createState() =>
      _CreateHabitEndConditionSectionState();
}

class _CreateHabitEndConditionSectionState
    extends State<CreateHabitEndConditionSection> {
  // Controller for target count input
  late TextEditingController _countController;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  /// Initialize text controller with current value
  void _initializeController() {
    _countController = TextEditingController(
      text: widget.targetCount?.toString() ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.surface.withAlpha(250)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(color: AppColors.divider.withAlpha(30), width: 0.5),
      ),
      child: Column(
        children: [
          _buildMainRow(),
          if (widget.endCondition != HabitEndCondition.never)
            _buildDetailsRow(),
        ],
      ),
    );
  }

  /// Build main row with icon, title, and condition options
  Widget _buildMainRow() {
    return Row(
      children: [
        _buildEndIcon(),
        const SizedBox(width: 12),
        _buildHeaderInfo(),
        const Spacer(),
        _buildConditionOptions(),
      ],
    );
  }

  /// Build end condition icon with current selection styling
  Widget _buildEndIcon() {
    final color = _getConditionColor(widget.endCondition);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withAlpha(220)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(30),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        CupertinoIcons.flag_fill,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  /// Build header information section
  Widget _buildHeaderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'End Condition',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        Text(
          _getConditionDescription(),
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  /// Build compact condition selection options
  Widget _buildConditionOptions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildConditionButton(
          condition: HabitEndCondition.never,
          icon: CupertinoIcons.infinite,
          label: 'Never',
        ),
        const SizedBox(width: 8),
        _buildConditionButton(
          condition: HabitEndCondition.onDate,
          icon: CupertinoIcons.calendar,
          label: 'Date',
        ),
        const SizedBox(width: 8),
        _buildConditionButton(
          condition: HabitEndCondition.afterCount,
          icon: CupertinoIcons.number_circle_fill,
          label: 'Count',
        ),
      ],
    );
  }

  /// Build individual condition selection button
  Widget _buildConditionButton({
    required HabitEndCondition condition,
    required IconData icon,
    required String label,
  }) {
    final isSelected = widget.endCondition == condition;
    final color = _getConditionColor(condition);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onEndConditionChanged(condition);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors:
                    isSelected
                        ? [color.withAlpha(25), color.withAlpha(15)]
                        : [
                          AppColors.background,
                          AppColors.background.withAlpha(200),
                        ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    isSelected
                        ? color.withAlpha(60)
                        : AppColors.divider.withAlpha(40),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow:
                  isSelected
                      ? [
                        BoxShadow(
                          color: color.withAlpha(20),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                      : null,
            ),
            child: Icon(
              icon,
              color: isSelected ? color : AppColors.textSecondary,
              size: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: isSelected ? color : AppColors.textSecondary,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  /// Build details row for specific condition configurations
  Widget _buildDetailsRow() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getConditionColor(widget.endCondition).withAlpha(8),
            _getConditionColor(widget.endCondition).withAlpha(5),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getConditionColor(widget.endCondition).withAlpha(30),
          width: 1,
        ),
      ),
      child: _buildConditionSpecificContent(),
    );
  }

  /// Build condition-specific content based on selection
  Widget _buildConditionSpecificContent() {
    switch (widget.endCondition) {
      case HabitEndCondition.onDate:
        return _buildDateSelector();
      case HabitEndCondition.afterCount:
        return _buildCountSelector();
      case HabitEndCondition.never:
      case HabitEndCondition.manual:
        return const SizedBox.shrink();
    }
  }

  /// Build compact date selector
  Widget _buildDateSelector() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.info.withAlpha(20),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            CupertinoIcons.calendar,
            size: 16,
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'End on:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            height: 1.0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => _showDatePicker(context),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.divider.withAlpha(50),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.calendar,
                    color:
                        widget.endDate != null
                            ? AppColors.info
                            : AppColors.textSecondary,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.endDate != null
                          ? DateFormat('MMM d, yyyy').format(widget.endDate!)
                          : 'Select date',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                            widget.endDate != null
                                ? AppColors.info
                                : AppColors.textSecondary,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build compact count selector
  Widget _buildCountSelector() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.warning.withAlpha(20),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            CupertinoIcons.number_circle_fill,
            size: 16,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'After',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            height: 1.0,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 50,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.divider.withAlpha(50),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _countController,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.0,
            ),
            decoration: const InputDecoration(
              hintText: '21',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              isDense: true,
            ),
            onChanged: (value) {
              widget.onTargetCountChanged(
                value.isEmpty ? null : int.tryParse(value),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'completions',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            height: 1.0,
          ),
        ),
      ],
    );
  }

  /// Show date picker modal for end date selection
  void _showDatePicker(BuildContext context) async {
    final selectedDate = await DatePickerModal.show(
      context: context,
      selectedDate:
          widget.endDate ?? DateTime.now().add(const Duration(days: 30)),
      title: 'End Date',
      minDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (selectedDate != null) {
      widget.onEndDateChanged(selectedDate);
    }
  }

  /// Get color for specific end condition type
  Color _getConditionColor(HabitEndCondition condition) {
    switch (condition) {
      case HabitEndCondition.never:
        return AppColors.success;
      case HabitEndCondition.onDate:
        return AppColors.info;
      case HabitEndCondition.afterCount:
        return AppColors.warning;
      case HabitEndCondition.manual:
        return AppColors.accent;
    }
  }

  /// Get description text for current condition
  String _getConditionDescription() {
    switch (widget.endCondition) {
      case HabitEndCondition.never:
        return 'Continue indefinitely';
      case HabitEndCondition.onDate:
        return widget.endDate != null
            ? 'Ends ${DateFormat('MMM d').format(widget.endDate!)}'
            : 'Set end date';
      case HabitEndCondition.afterCount:
        return widget.targetCount != null
            ? 'Ends after ${widget.targetCount} times'
            : 'Set completion count';
      case HabitEndCondition.manual:
        return 'Manual termination';
    }
  }
}
