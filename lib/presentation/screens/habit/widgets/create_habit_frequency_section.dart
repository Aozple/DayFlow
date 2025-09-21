import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/habit_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Compact habit frequency selection widget with minimal space usage.
///
/// Provides an efficient interface for selecting habit frequency patterns
/// including daily, weekly, monthly, and custom intervals with optimized
/// vertical space consumption while maintaining visual appeal.
class CreateHabitFrequencySection extends StatefulWidget {
  final HabitFrequency frequency;
  final List<int> selectedWeekdays;
  final int monthDay;
  final int customInterval;
  final Function(HabitFrequency) onFrequencyChanged;
  final Function(List<int>) onWeekdaysChanged;
  final Function(int) onMonthDayChanged;
  final Function(int) onCustomIntervalChanged;

  const CreateHabitFrequencySection({
    super.key,
    required this.frequency,
    required this.selectedWeekdays,
    required this.monthDay,
    required this.customInterval,
    required this.onFrequencyChanged,
    required this.onWeekdaysChanged,
    required this.onMonthDayChanged,
    required this.onCustomIntervalChanged,
  });

  @override
  State<CreateHabitFrequencySection> createState() =>
      _CreateHabitFrequencySectionState();
}

class _CreateHabitFrequencySectionState
    extends State<CreateHabitFrequencySection> {
  // Controllers for input fields
  late TextEditingController _monthDayController;
  late TextEditingController _customIntervalController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void dispose() {
    _monthDayController.dispose();
    _customIntervalController.dispose();
    super.dispose();
  }

  /// Initialize text controllers with current values
  void _initializeControllers() {
    _monthDayController = TextEditingController(
      text: widget.monthDay.toString(),
    );
    _customIntervalController = TextEditingController(
      text: widget.customInterval.toString(),
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
          if (widget.frequency != HabitFrequency.daily) _buildDetailsRow(),
        ],
      ),
    );
  }

  /// Build main row with icon, title, and frequency options
  Widget _buildMainRow() {
    return Row(
      children: [
        _buildHeaderIcon(),
        const SizedBox(width: 12),
        _buildHeaderInfo(),
        const Spacer(),
        _buildFrequencyOptions(),
      ],
    );
  }

  /// Build header icon with current frequency styling
  Widget _buildHeaderIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, AppColors.accent.withAlpha(220)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withAlpha(30),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(CupertinoIcons.repeat, color: Colors.white, size: 18),
    );
  }

  /// Build header information section
  Widget _buildHeaderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Repeat Pattern',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        Text(
          _getFrequencyDescription(),
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

  /// Build compact frequency selection options
  Widget _buildFrequencyOptions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFrequencyButton(
          frequency: HabitFrequency.daily,
          icon: CupertinoIcons.sun_max_fill,
          label: 'Daily',
        ),
        const SizedBox(width: 8),
        _buildFrequencyButton(
          frequency: HabitFrequency.weekly,
          icon: CupertinoIcons.calendar,
          label: 'Weekly',
        ),
        const SizedBox(width: 8),
        _buildFrequencyButton(
          frequency: HabitFrequency.monthly,
          icon: CupertinoIcons.calendar_circle_fill,
          label: 'Monthly',
        ),
        const SizedBox(width: 8),
        _buildFrequencyButton(
          frequency: HabitFrequency.custom,
          icon: CupertinoIcons.gear_alt_fill,
          label: 'Custom',
        ),
      ],
    );
  }

  /// Build individual frequency selection button
  Widget _buildFrequencyButton({
    required HabitFrequency frequency,
    required IconData icon,
    required String label,
  }) {
    final isSelected = widget.frequency == frequency;
    final color = _getFrequencyColor(frequency);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onFrequencyChanged(frequency);
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

  /// Build details row for specific frequency configurations
  Widget _buildDetailsRow() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getFrequencyColor(widget.frequency).withAlpha(8),
            _getFrequencyColor(widget.frequency).withAlpha(5),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getFrequencyColor(widget.frequency).withAlpha(30),
          width: 1,
        ),
      ),
      child: _buildFrequencySpecificContent(),
    );
  }

  /// Build frequency-specific content based on selection
  Widget _buildFrequencySpecificContent() {
    switch (widget.frequency) {
      case HabitFrequency.weekly:
        return _buildWeekdaySelector();
      case HabitFrequency.monthly:
        return _buildMonthDaySelector();
      case HabitFrequency.custom:
        return _buildCustomIntervalSelector();
      case HabitFrequency.daily:
        return const SizedBox.shrink();
    }
  }

  /// Build compact weekday selector
  Widget _buildWeekdaySelector() {
    final List<Map<String, dynamic>> weekdays = [
      {'day': 'M', 'value': 1},
      {'day': 'T', 'value': 2},
      {'day': 'W', 'value': 3},
      {'day': 'T', 'value': 4},
      {'day': 'F', 'value': 5},
      {'day': 'S', 'value': 6},
      {'day': 'S', 'value': 7},
    ];

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.success.withAlpha(20),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            CupertinoIcons.calendar_today,
            size: 16,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Days:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            height: 1.0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:
                weekdays.map((day) {
                  final isSelected = widget.selectedWeekdays.contains(
                    day['value'],
                  );
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      final newWeekdays = List<int>.from(
                        widget.selectedWeekdays,
                      );
                      if (isSelected) {
                        newWeekdays.remove(day['value']);
                      } else {
                        newWeekdays.add(day['value']);
                      }
                      widget.onWeekdaysChanged(newWeekdays..sort());
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.success : AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color:
                              isSelected
                                  ? AppColors.success
                                  : AppColors.divider.withAlpha(50),
                          width: 1,
                        ),
                        boxShadow:
                            isSelected
                                ? [
                                  BoxShadow(
                                    color: AppColors.success.withAlpha(30),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                                : null,
                      ),
                      child: Center(
                        child: Text(
                          day['day'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color:
                                isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  /// Build compact month day selector
  Widget _buildMonthDaySelector() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.info.withAlpha(20),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            CupertinoIcons.calendar_badge_plus,
            size: 16,
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'On day',
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
            controller: _monthDayController,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _MonthDayInputFormatter(),
            ],
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.0,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              isDense: true,
            ),
            onChanged: (value) {
              final day = int.tryParse(value) ?? 1;
              widget.onMonthDayChanged(day.clamp(1, 31));
            },
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'of each month',
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

  /// Build compact custom interval selector
  Widget _buildCustomIntervalSelector() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.warning.withAlpha(20),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            CupertinoIcons.timer,
            size: 16,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Every',
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
            controller: _customIntervalController,
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
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              isDense: true,
            ),
            onChanged: (value) {
              final interval = int.tryParse(value) ?? 2;
              widget.onCustomIntervalChanged(interval.clamp(1, 365));
            },
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'days',
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

  /// Get color for specific frequency type
  Color _getFrequencyColor(HabitFrequency frequency) {
    switch (frequency) {
      case HabitFrequency.daily:
        return AppColors.accent;
      case HabitFrequency.weekly:
        return AppColors.success;
      case HabitFrequency.monthly:
        return AppColors.info;
      case HabitFrequency.custom:
        return AppColors.warning;
    }
  }

  /// Get description text for current frequency
  String _getFrequencyDescription() {
    switch (widget.frequency) {
      case HabitFrequency.daily:
        return 'Every day';
      case HabitFrequency.weekly:
        return '${widget.selectedWeekdays.length} days per week';
      case HabitFrequency.monthly:
        return 'Day ${widget.monthDay} of each month';
      case HabitFrequency.custom:
        return 'Every ${widget.customInterval} days';
    }
  }
}

/// Custom input formatter for month days (1-31)
class _MonthDayInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final value = int.tryParse(newValue.text);
    if (value == null) return oldValue;

    if (value < 1 || value > 31) return oldValue;

    return newValue;
  }
}
