import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/habit_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  late TextEditingController _monthDayController;
  late TextEditingController _customIntervalController;

  static const List<FrequencyOption> _frequencies = [
    FrequencyOption(HabitFrequency.daily, 'Daily', CupertinoIcons.sun_max_fill),
    FrequencyOption(HabitFrequency.weekly, 'Weekly', CupertinoIcons.calendar),
    FrequencyOption(
      HabitFrequency.monthly,
      'Monthly',
      CupertinoIcons.calendar_circle,
    ),
    FrequencyOption(HabitFrequency.custom, 'Custom', CupertinoIcons.gear),
  ];

  @override
  void initState() {
    super.initState();
    _monthDayController = TextEditingController(
      text: widget.monthDay.toString(),
    );
    _customIntervalController = TextEditingController(
      text: widget.customInterval.toString(),
    );
  }

  @override
  void dispose() {
    _monthDayController.dispose();
    _customIntervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withAlpha(30), width: 0.5),
      ),
      child: Column(
        children: [
          _buildMainSection(),
          if (widget.frequency != HabitFrequency.daily) _buildDetailSection(),
        ],
      ),
    );
  }

  Widget _buildMainSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  CupertinoIcons.repeat,
                  color: AppColors.accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Repeat Pattern',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getDescription(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildVisualSummary(),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _frequencies.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final freq = _frequencies[index];
                return _buildFrequencyChip(freq);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withAlpha(30), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getFrequencyIcon(), size: 14, color: AppColors.accent),
              const SizedBox(width: 6),
              Text(
                _getSummaryText(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          if (widget.frequency == HabitFrequency.weekly &&
              widget.selectedWeekdays.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildMiniWeekView(),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniWeekView() {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (index) {
        final isSelected = widget.selectedWeekdays.contains(index + 1);
        return Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? AppColors.accent
                    : AppColors.textTertiary.withAlpha(30),
            borderRadius: BorderRadius.circular(3),
          ),
          alignment: Alignment.center,
          child: Text(
            days[index],
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textTertiary,
            ),
          ),
        );
      }),
    );
  }

  IconData _getFrequencyIcon() {
    switch (widget.frequency) {
      case HabitFrequency.daily:
        return CupertinoIcons.sun_max_fill;
      case HabitFrequency.weekly:
        return CupertinoIcons.calendar;
      case HabitFrequency.monthly:
        return CupertinoIcons.calendar_badge_plus;
      case HabitFrequency.custom:
        return CupertinoIcons.timer;
    }
  }

  String _getSummaryText() {
    switch (widget.frequency) {
      case HabitFrequency.daily:
        return 'Every day';
      case HabitFrequency.weekly:
        final count = widget.selectedWeekdays.length;
        if (count == 0) return 'Not set';
        if (count == 7) return 'Every day';
        return '$count×/week';
      case HabitFrequency.monthly:
        return 'Day ${widget.monthDay}';
      case HabitFrequency.custom:
        return '${widget.customInterval}d cycle';
    }
  }

  Widget _buildFrequencyChip(FrequencyOption option) {
    final isSelected = widget.frequency == option.frequency;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onFrequencyChanged(option.frequency);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected ? AppColors.accent : AppColors.divider.withAlpha(50),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              option.icon,
              size: 15,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              option.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent.withAlpha(5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withAlpha(30), width: 1),
      ),
      child: _buildFrequencyDetails(),
    );
  }

  Widget _buildFrequencyDetails() {
    switch (widget.frequency) {
      case HabitFrequency.weekly:
        return _buildWeekdaySelector();
      case HabitFrequency.monthly:
        return _buildMonthDayInput();
      case HabitFrequency.custom:
        return _buildCustomIntervalInput();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWeekdaySelector() {
    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      children: [
        Row(
          children: [
            Icon(CupertinoIcons.calendar, size: 16, color: AppColors.accent),
            const SizedBox(width: 8),
            const Text(
              'Select days',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final dayValue = index + 1;
            final isSelected = widget.selectedWeekdays.contains(dayValue);

            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                final newWeekdays = List<int>.from(widget.selectedWeekdays);
                if (isSelected) {
                  newWeekdays.remove(dayValue);
                } else {
                  newWeekdays.add(dayValue);
                }
                widget.onWeekdaysChanged(newWeekdays..sort());
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        isSelected
                            ? AppColors.accent
                            : AppColors.divider.withAlpha(50),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  weekdays[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMonthDayInput() {
    return Row(
      children: [
        Icon(
          CupertinoIcons.calendar_badge_plus,
          size: 16,
          color: AppColors.accent,
        ),
        const SizedBox(width: 8),
        const Text(
          'On day',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 60,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.divider.withAlpha(50),
              width: 1,
            ),
          ),
          child: CupertinoTextField(
            controller: _monthDayController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: const BoxDecoration(),
            placeholder: '1-31',
            placeholderStyle: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary.withAlpha(150),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            onChanged: (value) {
              final day = int.tryParse(value) ?? 1;
              widget.onMonthDayChanged(day.clamp(1, 31));
            },
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'of each month',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildCustomIntervalInput() {
    return Row(
      children: [
        Icon(CupertinoIcons.timer, size: 16, color: AppColors.accent),
        const SizedBox(width: 8),
        const Text(
          'Every',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 60,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.divider.withAlpha(50),
              width: 1,
            ),
          ),
          child: CupertinoTextField(
            controller: _customIntervalController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: const BoxDecoration(),
            placeholder: '2-365',
            placeholderStyle: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary.withAlpha(150),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            onChanged: (value) {
              final interval = int.tryParse(value) ?? 2;
              widget.onCustomIntervalChanged(interval.clamp(2, 365));
            },
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'days',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  String _getDescription() {
    switch (widget.frequency) {
      case HabitFrequency.daily:
        return 'Every day';
      case HabitFrequency.weekly:
        final count = widget.selectedWeekdays.length;
        return count == 0
            ? 'No days selected'
            : '$count day${count > 1 ? 's' : ''} per week';
      case HabitFrequency.monthly:
        return 'Day ${widget.monthDay} of each month';
      case HabitFrequency.custom:
        return 'Every ${widget.customInterval} days';
    }
  }
}

class FrequencyOption {
  final HabitFrequency frequency;
  final String label;
  final IconData icon;

  const FrequencyOption(this.frequency, this.label, this.icon);
}
