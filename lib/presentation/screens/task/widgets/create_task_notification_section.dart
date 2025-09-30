import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:dayflow/core/constants/app_colors.dart';

class CreateTaskNotificationSection extends StatelessWidget {
  final bool hasNotification;
  final int? minutesBefore;
  final bool hasDate;
  final Function(bool) onNotificationToggle;
  final Function(int?) onMinutesChanged;

  static const List<TimingOption> _timings = [
    TimingOption(0, 'At time'),
    TimingOption(5, '5 min'),
    TimingOption(10, '10 min'),
    TimingOption(15, '15 min'),
    TimingOption(30, '30 min'),
    TimingOption(60, '1 hour'),
  ];

  const CreateTaskNotificationSection({
    super.key,
    required this.hasNotification,
    this.minutesBefore,
    required this.hasDate,
    required this.onNotificationToggle,
    required this.onMinutesChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasDate) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withAlpha(30), width: 0.5),
      ),
      child: Column(
        children: [
          _buildToggleSection(),
          if (hasNotification) _buildTimingSection(),
        ],
      ),
    );
  }

  Widget _buildToggleSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  hasNotification
                      ? AppColors.accent.withAlpha(20)
                      : AppColors.textSecondary.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              hasNotification ? CupertinoIcons.bell_fill : CupertinoIcons.bell,
              color:
                  hasNotification ? AppColors.accent : AppColors.textSecondary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reminder',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusText(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Transform.scale(
            scale: 0.9,
            child: CupertinoSwitch(
              value: hasNotification,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                onNotificationToggle(value);
              },
              activeTrackColor: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.accent.withAlpha(5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withAlpha(30), width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.clock, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              const Text(
                'Notify me',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                _formatMinutes(minutesBefore ?? 0),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _timings.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == _timings.length) {
                  return _buildCustomOption();
                }
                final timing = _timings[index];
                return _buildTimingChip(timing.minutes, timing.label);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingChip(int minutes, String label) {
    final isSelected = minutesBefore == minutes;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onMinutesChanged(minutes);
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
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomOption() {
    final isCustom =
        minutesBefore != null &&
        !_timings.any((t) => t.minutes == minutesBefore);

    return _CustomTimingInput(
      currentMinutes: minutesBefore ?? 0,
      isSelected: isCustom,
      onChanged: (value) => onMinutesChanged(value),
    );
  }

  String _getStatusText() {
    if (!hasNotification) return 'Notifications disabled';
    if (minutesBefore == null || minutesBefore == 0) {
      return 'Notify at scheduled time';
    }
    return 'Notify ${_formatMinutes(minutesBefore!)} before';
  }

  String _formatMinutes(int minutes) {
    for (final t in _timings) {
      if (t.minutes == minutes) return t.label;
    }

    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    }
    return '${minutes}m';
  }
}

class TimingOption {
  final int minutes;
  final String label;
  const TimingOption(this.minutes, this.label);
}

class _CustomTimingInput extends StatefulWidget {
  final int currentMinutes;
  final bool isSelected;
  final Function(int) onChanged;

  const _CustomTimingInput({
    required this.currentMinutes,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  State<_CustomTimingInput> createState() => _CustomTimingInputState();
}

class _CustomTimingInputState extends State<_CustomTimingInput> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.isSelected ? widget.currentMinutes.toString() : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() => _isEditing = true);
    _focusNode.requestFocus();
  }

  void _submitValue() {
    final value = int.tryParse(_controller.text);
    if (value != null && value >= 0 && value <= 1440) {
      widget.onChanged(value);
      _focusNode.unfocus();
      setState(() => _isEditing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return Container(
        width: 80,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.info.withAlpha(20),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.info, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: CupertinoTextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                decoration: const BoxDecoration(),
                placeholder: 'min',
                placeholderStyle: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary.withAlpha(150),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                onSubmitted: (_) => _submitValue(),
              ),
            ),
            GestureDetector(
              onTap: _submitValue,
              child: const Icon(
                CupertinoIcons.checkmark,
                size: 14,
                color: AppColors.info,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _startEditing,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 36,
        decoration: BoxDecoration(
          color:
              widget.isSelected
                  ? AppColors.info.withAlpha(20)
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                widget.isSelected
                    ? AppColors.info
                    : AppColors.divider.withAlpha(50),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.pencil,
              size: 12,
              color:
                  widget.isSelected ? AppColors.info : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              widget.isSelected ? '${widget.currentMinutes}m' : 'Custom',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    widget.isSelected
                        ? AppColors.info
                        : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
