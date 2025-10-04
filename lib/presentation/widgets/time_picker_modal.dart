import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/presentation/widgets/draggable_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TimePickerModal extends StatefulWidget {
  final TimeOfDay? selectedTime;
  final Function(TimeOfDay) onTimeSelected;
  final String title;
  final bool allowClearTime;

  const TimePickerModal({
    super.key,
    this.selectedTime,
    required this.onTimeSelected,
    this.title = 'Select Time',
    this.allowClearTime = false,
  });

  static Future<TimeOfDay?> show({
    required BuildContext context,
    TimeOfDay? selectedTime,
    String title = 'Select Time',
    bool allowClearTime = false,
  }) {
    return showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => TimePickerModal(
            selectedTime: selectedTime,
            title: title,
            allowClearTime: allowClearTime,
            onTimeSelected: (time) => Navigator.pop(context, time),
          ),
    );
  }

  @override
  State<TimePickerModal> createState() => _TimePickerModalState();
}

class _TimePickerModalState extends State<TimePickerModal> {
  late TimeOfDay _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = widget.selectedTime ?? TimeOfDay.now();
  }

  void _handleTimeChange(DateTime dateTime) {
    HapticFeedback.selectionClick();
    setState(() => _currentTime = TimeOfDay.fromDateTime(dateTime));
  }

  void _handleConfirm() {
    HapticFeedback.mediumImpact();
    widget.onTimeSelected(_currentTime);
  }

  void _selectQuickTime(TimeOfDay time) {
    HapticFeedback.lightImpact();
    setState(() => _currentTime = time);
  }

  bool get _hasChanges => _currentTime != widget.selectedTime;

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableModal(
      title: widget.title,
      initialHeight: 380,
      minHeight: 350,
      leftAction: widget.allowClearTime ? _buildClearButton() : null,
      rightAction: _buildDoneButton(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          children: [
            _buildTimeDisplay(),
            const SizedBox(height: 16),
            _buildTimePicker(),
            const SizedBox(height: 16),
            _buildQuickOptions(),
          ],
        ),
      ),
    );
  }

  Widget _buildClearButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => Navigator.pop(context, null),
      child: const Text(
        'Clear',
        style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildDoneButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _hasChanges ? _handleConfirm : null,
      child: Text(
        'Done',
        style: TextStyle(
          color: _hasChanges ? Theme.of(context).colorScheme.primary : AppColors.textTertiary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTimeDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _formatTime(_currentTime),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.time,
          use24hFormat: true,
          initialDateTime: DateTime(
            2024,
            1,
            1,
            _currentTime.hour,
            _currentTime.minute,
          ),
          onDateTimeChanged: _handleTimeChange,
        ),
      ),
    );
  }

  Widget _buildQuickOptions() {
    final quickTimes = [
      const TimeOfDay(hour: 9, minute: 0),
      const TimeOfDay(hour: 12, minute: 0),
      const TimeOfDay(hour: 15, minute: 0),
      const TimeOfDay(hour: 18, minute: 0),
      const TimeOfDay(hour: 21, minute: 0),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: quickTimes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final time = quickTimes[index];
          final isSelected = _currentTime == time;

          return GestureDetector(
            onTap: () => _selectQuickTime(time),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).colorScheme.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.primary
                          : AppColors.divider.withAlpha(50),
                ),
              ),
              child: Text(
                _formatTime(time),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
