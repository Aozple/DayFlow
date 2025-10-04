import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/presentation/widgets/draggable_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DatePickerModal extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final String title;
  final DateTime? minDate;
  final DateTime? maxDate;

  const DatePickerModal({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.title = 'Select Date',
    this.minDate,
    this.maxDate,
  });

  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime selectedDate,
    String title = 'Select Date',
    DateTime? minDate,
    DateTime? maxDate,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => DatePickerModal(
            selectedDate: selectedDate,
            title: title,
            minDate: minDate,
            maxDate: maxDate,
            onDateSelected: (date) => Navigator.pop(context, date),
          ),
    );
  }

  @override
  State<DatePickerModal> createState() => _DatePickerModalState();
}

class _DatePickerModalState extends State<DatePickerModal> {
  late DateTime _currentDate;
  late DateTime _effectiveMinDate;
  late DateTime _effectiveMaxDate;

  @override
  void initState() {
    super.initState();
    _setupDates();
  }

  void _setupDates() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _effectiveMinDate =
        widget.minDate != null
            ? _normalizeToMidnight(widget.minDate!)
            : today.subtract(const Duration(days: 1));

    _effectiveMaxDate =
        widget.maxDate != null
            ? _normalizeToMidnight(widget.maxDate!)
            : today.add(const Duration(days: 365 * 2));

    _currentDate = _normalizeToMidnight(widget.selectedDate);

    if (_currentDate.isBefore(_effectiveMinDate)) {
      _currentDate = _effectiveMinDate;
    } else if (_currentDate.isAfter(_effectiveMaxDate)) {
      _currentDate = _effectiveMaxDate;
    }
  }

  DateTime _normalizeToMidnight(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _handleDateChange(DateTime date) {
    HapticFeedback.selectionClick();
    setState(() => _currentDate = _normalizeToMidnight(date));
  }

  void _handleConfirm() {
    HapticFeedback.mediumImpact();
    widget.onDateSelected(_currentDate);
  }

  void _selectQuickDate(DateTime date) {
    HapticFeedback.lightImpact();
    setState(() => _currentDate = _normalizeToMidnight(date));
  }

  bool get _hasChanges => !_isSameDay(_currentDate, widget.selectedDate);

  bool _isSameDay(DateTime a, DateTime b) {
    final normalizedA = DateTime(a.year, a.month, a.day);
    final normalizedB = DateTime(b.year, b.month, b.day);

    return normalizedA.isAtSameMomentAs(normalizedB);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    if (_isSameDay(date, today)) return 'Today';
    if (_isSameDay(date, tomorrow)) return 'Tomorrow';
    if (_isSameDay(date, yesterday)) return 'Yesterday';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableModal(
      title: widget.title,
      initialHeight: 380,
      minHeight: 350,
      rightAction: _buildDoneButton(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          children: [
            _buildDateDisplay(),
            const SizedBox(height: 16),
            _buildDatePicker(),
            const SizedBox(height: 16),
            _buildQuickOptions(),
          ],
        ),
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

  Widget _buildDateDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _formatDate(_currentDate),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          initialDateTime: _currentDate,
          minimumDate: _effectiveMinDate,
          maximumDate: _effectiveMaxDate,
          onDateTimeChanged: _handleDateChange,
        ),
      ),
    );
  }

  Widget _buildQuickOptions() {
    final now = DateTime.now();

    final todayDate = DateTime(now.year, now.month, now.day);
    final tomorrowDate = DateTime(now.year, now.month, now.day + 1);
    final nextWeekDate = DateTime(now.year, now.month, now.day + 7);

    final quickDates = <(DateTime, String)>[];

    if (!todayDate.isBefore(_effectiveMinDate) &&
        !todayDate.isAfter(_effectiveMaxDate)) {
      quickDates.add((todayDate, 'Today'));
    }

    if (!tomorrowDate.isBefore(_effectiveMinDate) &&
        !tomorrowDate.isAfter(_effectiveMaxDate)) {
      quickDates.add((tomorrowDate, 'Tomorrow'));
    }

    if (!nextWeekDate.isBefore(_effectiveMinDate) &&
        !nextWeekDate.isAfter(_effectiveMaxDate)) {
      quickDates.add((nextWeekDate, 'Next Week'));
    }

    if (quickDates.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: quickDates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (date, label) = quickDates[index];
          final isSelected = _isSameDay(_currentDate, date);

          return GestureDetector(
            onTap: () => _selectQuickDate(date),
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
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
