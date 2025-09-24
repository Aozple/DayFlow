import 'package:dayflow/data/models/habit_model.dart';
import 'package:dayflow/data/models/habit_instance_model.dart';
import 'package:dayflow/presentation/blocs/habits/habit_bloc.dart';
import 'package:dayflow/presentation/blocs/settings/settings_bloc.dart';
import 'package:dayflow/presentation/screens/habit/widgets/create_habit_header.dart';
import 'package:dayflow/presentation/screens/habit/widgets/create_habit_main_content.dart';
import 'package:dayflow/presentation/screens/habit/widgets/create_habit_frequency_section.dart';
import 'package:dayflow/presentation/screens/habit/widgets/create_habit_type_section.dart';
import 'package:dayflow/presentation/screens/habit/widgets/create_habit_flexible_time_section.dart';
import 'package:dayflow/presentation/screens/habit/widgets/create_habit_end_condition_section.dart';
import 'package:dayflow/presentation/screens/habit/widgets/create_habit_notification_section.dart';
import 'package:dayflow/presentation/screens/home/widgets/blocks/home_habit_block.dart';
import 'package:dayflow/presentation/widgets/date_picker_modal.dart';
import 'package:dayflow/presentation/widgets/status_bar_padding.dart';
import 'package:dayflow/presentation/widgets/color_picker_modal.dart';
import 'package:dayflow/presentation/widgets/time_picker_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:dayflow/core/constants/app_colors.dart';

/// Comprehensive habit creation and editing screen
class CreateHabitScreen extends StatefulWidget {
  final HabitModel? habitToEdit;
  final int? prefilledHour;

  const CreateHabitScreen({super.key, this.habitToEdit, this.prefilledHour});

  @override
  State<CreateHabitScreen> createState() => _CreateHabitScreenState();
}

class _CreateHabitScreenState extends State<CreateHabitScreen> {
  // Controllers
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagsController;
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();

  // Form state
  late HabitFrequency _frequency;
  late List<int> _selectedWeekdays;
  late int _monthDay;
  late int _customInterval;
  late TimeOfDay _preferredTime;
  late bool _isFlexibleTime;
  late HabitEndCondition _endCondition;
  late DateTime _startDate;
  late DateTime? _endDate;
  late int? _targetCount;
  late HabitType _habitType;
  late int? _targetValue;
  late String? _unit;
  late String _selectedColor;
  late bool _hasNotification;
  late int _notificationMinutesBefore;

  // Constants
  static const _defaultWeekdays = [1, 2, 3, 4, 5];
  static const _defaultCustomInterval = 2;
  static const _sectionSpacing = SizedBox(height: 8);
  static const _keyboardClearance = SizedBox(height: 100);

  bool get isEditMode => widget.habitToEdit != null;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeFormValues();
    if (!isEditMode) _requestTitleFocus();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    final habit = widget.habitToEdit;
    _titleController = TextEditingController(text: habit?.title ?? '');
    _descriptionController = TextEditingController(
      text: habit?.description ?? '',
    );
    _tagsController = TextEditingController(text: habit?.tags.join(', ') ?? '');
  }

  void _initializeFormValues() {
    final habit = widget.habitToEdit;

    // Get default settings from BLoC
    final settingsState = context.read<SettingsBloc>().state;

    // Initialize frequency settings
    _frequency = habit?.frequency ?? HabitFrequency.daily;
    _selectedWeekdays = habit?.weekdays ?? _defaultWeekdays;
    _monthDay = habit?.monthDay ?? DateTime.now().day;
    _customInterval = habit?.customInterval ?? _defaultCustomInterval;

    // Initialize time settings
    _initializeTimeSettings(habit);
    _startDate = habit?.startDate ?? DateTime.now();

    // Initialize other settings
    _endCondition = habit?.endCondition ?? HabitEndCondition.never;
    _endDate = habit?.endDate;
    _targetCount = habit?.targetCount;
    _habitType = habit?.habitType ?? HabitType.simple;
    _targetValue = habit?.targetValue;
    _unit = habit?.unit;
    _selectedColor = habit?.color ?? AppColors.toHex(AppColors.userColors[0]);
    if (settingsState is SettingsLoaded) {
      _hasNotification =
          habit?.hasNotification ??
          settingsState.settings.defaultNotificationEnabled;
      _notificationMinutesBefore =
          habit?.notificationMinutesBefore ??
          settingsState.settings.defaultNotificationMinutesBefore;
    } else {
      _hasNotification = habit?.hasNotification ?? false;
      _notificationMinutesBefore = habit?.notificationMinutesBefore ?? 0;
    }
  }

  void _initializeTimeSettings(HabitModel? habit) {
    if (habit != null) {
      // Editing existing habit
      _isFlexibleTime =
          habit.preferredTime == null ||
          (habit.preferredTime!.hour == 0 && habit.preferredTime!.minute == 0);
      _preferredTime =
          habit.preferredTime ?? const TimeOfDay(hour: 0, minute: 0);
    } else if (widget.prefilledHour != null) {
      // New habit with prefilled hour
      _isFlexibleTime = false;
      _preferredTime = TimeOfDay(hour: widget.prefilledHour!, minute: 0);
    } else {
      // New habit without prefilled hour - default to current time
      _isFlexibleTime = false;
      _preferredTime = TimeOfDay.now();
    }
  }

  void _requestTitleFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _titleFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const StatusBarPadding(),
          CreateHabitHeader(
            isEditMode: isEditMode,
            canSave: _isFormValid,
            onCancel: () => context.pop(),
            onSave: _saveHabit,
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  CreateHabitMainContent(
                    titleController: _titleController,
                    descriptionController: _descriptionController,
                    tagsController: _tagsController,
                    titleFocus: _titleFocus,
                    descriptionFocus: _descriptionFocus,
                    selectedColor: _selectedColor,
                    selectedTime: _isFlexibleTime ? null : _preferredTime,
                    isFlexibleTime: _isFlexibleTime,
                    onChanged: () => setState(() {}),
                    onColorTap: _showColorPicker,
                    onTimeTap: _isFlexibleTime ? null : () => _showTimePicker(),
                    selectedStartDate: _startDate,
                    onStartDateTap: _showStartDatePicker,
                  ),
                  _sectionSpacing,
                  CreateHabitFlexibleTimeSection(
                    isFlexibleTime: _isFlexibleTime,
                    onFlexibleTimeToggle: _handleFlexibleTimeToggle,
                  ),
                  _sectionSpacing,
                  CreateHabitTypeSection(
                    habitType: _habitType,
                    targetValue: _targetValue,
                    unit: _unit,
                    onTypeChanged: (type) => setState(() => _habitType = type),
                    onTargetValueChanged:
                        (value) => setState(() => _targetValue = value),
                    onUnitChanged: (unit) => setState(() => _unit = unit),
                  ),
                  _sectionSpacing,
                  CreateHabitFrequencySection(
                    frequency: _frequency,
                    selectedWeekdays: _selectedWeekdays,
                    monthDay: _monthDay,
                    customInterval: _customInterval,
                    onFrequencyChanged:
                        (freq) => setState(() => _frequency = freq),
                    onWeekdaysChanged:
                        (days) => setState(() => _selectedWeekdays = days),
                    onMonthDayChanged: (day) => setState(() => _monthDay = day),
                    onCustomIntervalChanged:
                        (interval) =>
                            setState(() => _customInterval = interval),
                  ),
                  _sectionSpacing,
                  CreateHabitEndConditionSection(
                    endCondition: _endCondition,
                    endDate: _endDate,
                    targetCount: _targetCount,
                    onEndConditionChanged:
                        (condition) =>
                            setState(() => _endCondition = condition),
                    onEndDateChanged: (date) => setState(() => _endDate = date),
                    onTargetCountChanged:
                        (count) => setState(() => _targetCount = count),
                  ),
                  _sectionSpacing,
                  CreateHabitNotificationSection(
                    hasNotification: _hasNotification,
                    minutesBefore: _notificationMinutesBefore,
                    onNotificationToggle:
                        (value) => setState(() => _hasNotification = value),
                    onMinutesChanged:
                        (minutes) => setState(
                          () => _notificationMinutesBefore = minutes,
                        ),
                  ),
                  _keyboardClearance,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleFlexibleTimeToggle(bool isFlexible) {
    setState(() {
      _isFlexibleTime = isFlexible;
      if (isFlexible) {
        _preferredTime = const TimeOfDay(hour: 0, minute: 0);
      } else {
        _preferredTime = TimeOfDay.now();
      }
    });
  }

  bool get _isFormValid {
    if (_titleController.text.trim().isEmpty) return false;

    if (_frequency == HabitFrequency.weekly && _selectedWeekdays.isEmpty) {
      return false;
    }

    if (_habitType == HabitType.quantifiable) {
      if (_targetValue == null || _targetValue! <= 0) return false;
      if (_unit?.trim().isEmpty ?? true) return false;
    }

    if (_endCondition == HabitEndCondition.onDate && _endDate == null) {
      return false;
    }

    if (_endCondition == HabitEndCondition.afterCount &&
        (_targetCount == null || _targetCount! <= 0)) {
      return false;
    }

    return true;
  }

  void _saveHabit() {
    if (!_isFormValid) return;

    final habitBloc = context.read<HabitBloc>();
    final habitModel = _createHabitModel();

    if (isEditMode) {
      habitBloc.add(UpdateHabit(habitModel));
    } else {
      habitBloc.add(AddHabit(habitModel));
    }

    context.pop();
  }

  HabitModel _createHabitModel() {
    final now = DateTime.now();

    final normalizedStartDate = _isSameDay(_startDate, now) ? now : _startDate;

    final baseData = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'frequency': _frequency,
      'weekdays':
          _frequency == HabitFrequency.weekly ? _selectedWeekdays : null,
      'monthDay': _frequency == HabitFrequency.monthly ? _monthDay : null,
      'customInterval':
          _frequency == HabitFrequency.custom ? _customInterval : null,
      'preferredTime': _preferredTime,
      'endCondition': _endCondition,
      'startDate': normalizedStartDate,
      'endDate': _endDate,
      'targetCount': _targetCount,
      'habitType': _habitType,
      'targetValue': _habitType == HabitType.quantifiable ? _targetValue : null,
      'unit': _habitType == HabitType.quantifiable ? _unit : null,
      'color': _selectedColor,
      'tags': _parseTags(),
      'hasNotification': _hasNotification,
      'notificationMinutesBefore': _notificationMinutesBefore,
    };

    if (isEditMode) {
      return widget.habitToEdit!.copyWith(
        title: baseData['title'] as String,
        description: baseData['description'] as String,
        frequency: baseData['frequency'] as HabitFrequency,
        weekdays: baseData['weekdays'] as List<int>?,
        monthDay: baseData['monthDay'] as int?,
        customInterval: baseData['customInterval'] as int?,
        preferredTime: baseData['preferredTime'] as TimeOfDay,
        endCondition: baseData['endCondition'] as HabitEndCondition,
        startDate: baseData['startDate'] as DateTime,
        endDate: baseData['endDate'] as DateTime?,
        targetCount: baseData['targetCount'] as int?,
        habitType: baseData['habitType'] as HabitType,
        targetValue: baseData['targetValue'] as int?,
        unit: baseData['unit'] as String?,
        color: baseData['color'] as String,
        tags: baseData['tags'] as List<String>,
        hasNotification: baseData['hasNotification'] as bool,
        notificationMinutesBefore: baseData['notificationMinutesBefore'] as int,
      );
    }

    return HabitModel(
      title: baseData['title'] as String,
      description: baseData['description'] as String,
      frequency: baseData['frequency'] as HabitFrequency,
      weekdays: baseData['weekdays'] as List<int>?,
      monthDay: baseData['monthDay'] as int?,
      customInterval: baseData['customInterval'] as int?,
      preferredTime: baseData['preferredTime'] as TimeOfDay,
      endCondition: baseData['endCondition'] as HabitEndCondition,
      startDate: baseData['startDate'] as DateTime,
      createdAt: now,
      endDate: baseData['endDate'] as DateTime?,
      targetCount: baseData['targetCount'] as int?,
      habitType: baseData['habitType'] as HabitType,
      targetValue: baseData['targetValue'] as int?,
      unit: baseData['unit'] as String?,
      color: baseData['color'] as String,
      tags: baseData['tags'] as List<String>,
      hasNotification: baseData['hasNotification'] as bool,
      notificationMinutesBefore: baseData['notificationMinutesBefore'] as int,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<String> _parseTags() {
    return _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  Future<void> _showColorPicker() async {
    final selectedColor = await ColorPickerModal.show(
      context: context,
      selectedColor: _selectedColor,
      title: 'Choose Habit Color',
      previewBuilder: _buildColorPreview,
      showPreview: true,
    );

    if (selectedColor != null && mounted) {
      setState(() => _selectedColor = selectedColor);
    }
  }

  Widget _buildColorPreview(String colorHex) {
    return HomeHabitBlock(
      habit: HabitModel(
        title:
            _titleController.text.isNotEmpty
                ? _titleController.text
                : 'Sample Habit',
        description: _descriptionController.text,
        frequency: _frequency,
        color: colorHex,
        tags: _parseTags().isNotEmpty ? _parseTags() : ['Health', 'Daily'],
        currentStreak: 5,
        habitType: _habitType,
        targetValue:
            _habitType == HabitType.quantifiable ? (_targetValue ?? 8) : null,
        unit: _habitType == HabitType.quantifiable ? (_unit ?? 'times') : null,
        preferredTime: _preferredTime,
        hasNotification: _hasNotification,
      ),
      instance: HabitInstanceModel(
        habitId: 'preview',
        date: DateTime.now(),
        status: HabitInstanceStatus.pending,
        value:
            _habitType == HabitType.quantifiable
                ? ((_targetValue ?? 8) * 0.6).round()
                : null,
      ),
      selectedDate: DateTime.now(),
      onComplete: (_) {},
      onUncomplete: (_) {},
      onUpdateInstance: (_) {},
      onOptions: (_) {},
    );
  }

  Future<void> _showTimePicker() async {
    final selectedTime = await TimePickerModal.show(
      context: context,
      selectedTime: _preferredTime,
      title: 'Set Preferred Time',
      allowClearTime: false,
    );

    if (selectedTime != null && mounted) {
      setState(() {
        _preferredTime = selectedTime;
        _isFlexibleTime = false;
      });
    }
  }

  Future<void> _showStartDatePicker() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final selectedDate = await DatePickerModal.show(
      context: context,
      selectedDate: _startDate,
      title: 'Select Start Date',
      minDate: today,
      maxDate: today.add(const Duration(days: 365)),
    );

    if (selectedDate != null && mounted) {
      setState(() => _startDate = selectedDate);
    }
  }
}
