import 'package:dayflow/presentation/screens/task/widgets/create_task_date_picker.dart';
import 'package:dayflow/presentation/screens/task/widgets/create_task_notification_section.dart';
import 'package:dayflow/presentation/screens/task/widgets/create_task_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:dayflow/presentation/blocs/settings/settings_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'widgets/create_task_header.dart';
import 'widgets/create_task_main_content.dart';
import 'widgets/create_task_date_time_section.dart';
import 'widgets/create_task_priority_section.dart';
import 'widgets/create_task_color_section.dart';
import 'widgets/create_task_tags_section.dart';

/// Screen for creating a new task or editing an existing one.
///
/// This screen provides a comprehensive interface for creating or editing tasks,
/// including title, description, date/time selection, priority, color, and tags.
/// It uses BLoC for state management and follows a clean architecture pattern.
class CreateTaskScreen extends StatefulWidget {
  /// Optional task to edit. If null, we're creating a new task.
  final TaskModel? taskToEdit;

  /// Optional task ID, might be used for deep linking or specific scenarios.
  final String? taskId;

  /// Optional pre-filled hour for convenience, e.g., from a calendar view.
  final int? prefilledHour;

  /// Optional pre-filled date for convenience.
  final DateTime? prefilledDate;

  const CreateTaskScreen({
    super.key,
    this.taskToEdit,
    this.taskId,
    this.prefilledHour,
    this.prefilledDate,
  });

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

/// State class for CreateTaskScreen.
///
/// This class manages the UI state and interactions for the task creation/editing screen,
/// including handling form inputs and saving the task.
class _CreateTaskScreenState extends State<CreateTaskScreen> {
  // Text controllers for input fields
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagsController;

  // Notification settings
  late bool _hasNotification;
  late int? _notificationMinutesBefore;
  late String _repeatInterval;

  // Task properties
  late DateTime _selectedDate;
  late TimeOfDay? _selectedTime;
  late int _priority;
  late String _selectedColor;
  bool _hasTime = false;

  // Focus nodes for text fields
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();

  // Getters
  bool get isEditMode => widget.taskToEdit != null;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeFormValues();
    _setupAutoFocus();
  }

  /// Initialize text controllers with appropriate values
  void _initializeControllers() {
    _titleController = TextEditingController(
      text: widget.taskToEdit?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.taskToEdit?.description ?? '',
    );
    _tagsController = TextEditingController(
      text: widget.taskToEdit?.tags.join(', ') ?? '',
    );
  }

  /// Initialize form values based on edit mode or defaults
  void _initializeFormValues() {
    if (isEditMode && widget.taskToEdit != null) {
      _initializeEditModeValues();
    } else {
      _initializeNewTaskValues();
    }
  }

  /// Initialize values for editing an existing task
  void _initializeEditModeValues() {
    final task = widget.taskToEdit!;
    _selectedDate = task.dueDate ?? DateTime.now();
    _selectedTime =
        task.dueDate != null
            ? TimeOfDay.fromDateTime(task.dueDate!)
            : TimeOfDay.now();
    _hasTime = task.dueDate != null;
    _priority = task.priority;
    _selectedColor = task.color;
    _hasNotification = task.hasNotification;
    _notificationMinutesBefore = task.notificationMinutesBefore;
  }

  /// Initialize values for creating a new task
  void _initializeNewTaskValues() {
    // Set date and time
    _selectedDate = widget.prefilledDate ?? DateTime.now();
    if (widget.prefilledHour != null) {
      _selectedTime = TimeOfDay(hour: widget.prefilledHour!, minute: 0);
      _hasTime = true;
    } else {
      _selectedTime = TimeOfDay.now();
      _hasTime = false;
    }

    // Get default settings
    final settingsState = context.read<SettingsBloc>().state;
    _priority =
        settingsState is SettingsLoaded ? settingsState.defaultPriority : 3;
    _selectedColor = AppColors.toHex(AppColors.userColors[0]);

    // Set notification defaults
    if (settingsState is SettingsLoaded) {
      _hasNotification = settingsState.settings.defaultNotificationEnabled;
      _notificationMinutesBefore =
          settingsState.settings.defaultNotificationMinutesBefore;
      _debugPrintNotificationSettings();
    } else {
      _hasNotification = false;
      _notificationMinutesBefore = 0;
    }
    _repeatInterval = 'none';
  }

  /// Debug print notification settings
  void _debugPrintNotificationSettings() {
    debugPrint('📱 Default notification settings loaded:');
    debugPrint('  - Enabled: $_hasNotification');
    debugPrint('  - Minutes before: $_notificationMinutesBefore');
  }

  /// Setup auto-focus for new tasks
  void _setupAutoFocus() {
    if (!isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _titleFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    // Clean up controllers and focus nodes to prevent memory leaks
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildStatusBarPadding(),
          // The header section with cancel and save buttons
          CreateTaskHeader(
            isEditMode: isEditMode,
            canSave: _canSave(),
            onCancel: () => context.pop(),
            onSave: _saveTask,
          ),
          // The main scrollable content area for task details
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Section for task title and description
                  CreateTaskMainContent(
                    titleController: _titleController,
                    descriptionController: _descriptionController,
                    titleFocus: _titleFocus,
                    descriptionFocus: _descriptionFocus,
                    onChanged:
                        () => setState(
                          () {},
                        ), // Rebuild to update save button state
                  ),
                  const SizedBox(height: 16),
                  // Section for selecting date and time
                  CreateTaskDateTimeSection(
                    selectedDate: _selectedDate,
                    selectedTime: _selectedTime,
                    hasTime: _hasTime,
                    isPrefilled: widget.prefilledDate != null,
                    onDateChanged:
                        (date) => setState(() => _selectedDate = date),
                    onTimeChanged: (hasTime, time) {
                      setState(() {
                        _hasTime = hasTime;
                        _selectedTime = time;
                      });
                    },
                    onSelectDate: _selectDate,
                    onSelectTime: _selectTime,
                  ),
                  const SizedBox(height: 16),
                  // Section for choosing task priority
                  CreateTaskPrioritySection(
                    priority: _priority,
                    onPriorityChanged:
                        (priority) => setState(() => _priority = priority),
                  ),
                  const SizedBox(height: 16),
                  // Section for selecting a task color
                  CreateTaskColorSection(
                    selectedColor: _selectedColor,
                    onColorChanged:
                        (color) => setState(() => _selectedColor = color),
                  ),
                  const SizedBox(height: 16),
                  // Section for notification settings
                  CreateTaskNotificationSection(
                    hasNotification: _hasNotification,
                    minutesBefore: _notificationMinutesBefore,
                    hasDate: _hasTime,
                    onNotificationToggle:
                        (value) => setState(() => _hasNotification = value),
                    onMinutesChanged:
                        (minutes) => setState(
                          () => _notificationMinutesBefore = minutes,
                        ),
                  ),
                  const SizedBox(height: 16),
                  // Section for adding tags to the task
                  CreateTaskTagsSection(tagsController: _tagsController),
                  const SizedBox(height: 100), // Extra space for keyboard
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds status bar padding container
  Widget _buildStatusBarPadding() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      color: AppColors.surface.withAlpha(200),
    );
  }

  /// Checks if the task can be saved (i.e., if the title is not empty)
  bool _canSave() {
    return _titleController.text.trim().isNotEmpty;
  }

  /// Shows a Cupertino-style modal for selecting a date
  void _selectDate() async {
    await showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CreateTaskDatePicker(
            selectedDate: _selectedDate,
            onDateChanged: (date) => setState(() => _selectedDate = date),
          ),
    );
  }

  /// Shows a Cupertino-style modal for selecting a time
  void _selectTime() async {
    await showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CreateTaskTimePicker(
            selectedTime: _selectedTime,
            onTimeChanged: (time) => setState(() => _selectedTime = time),
          ),
    );
  }

  /// Handles saving or updating the task based on the current mode
  void _saveTask() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    _debugPrintTaskDetails(title);

    final taskBloc = context.read<TaskBloc>();
    final tags = _parseTags();
    final dueDateTime = _createDueDateTime();

    if (isEditMode) {
      _updateTask(taskBloc, title, dueDateTime, tags);
    } else {
      _createTask(taskBloc, title, dueDateTime, tags);
    }

    context.pop();
  }

  /// Debug print task details before saving
  void _debugPrintTaskDetails(String title) {
    debugPrint('\n💾 === SAVING TASK ===');
    debugPrint('Title: $title');
    debugPrint('Has Time: $_hasTime');
    debugPrint('Selected Date: $_selectedDate');
    debugPrint('Selected Time: $_selectedTime');
    debugPrint('Has Notification: $_hasNotification');
    debugPrint('Minutes Before: ${_notificationMinutesBefore ?? 0}');
    debugPrint('Repeat: $_repeatInterval');
  }

  /// Parse tags from text input
  List<String> _parseTags() {
    return _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  /// Create due datetime if time is set
  DateTime? _createDueDateTime() {
    if (!_hasTime || _selectedTime == null) return null;

    final dueDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    debugPrint('Final Due DateTime: $dueDateTime');
    return dueDateTime;
  }

  /// Update an existing task
  void _updateTask(
    TaskBloc taskBloc,
    String title,
    DateTime? dueDateTime,
    List<String> tags,
  ) {
    final updatedTask = widget.taskToEdit!.copyWith(
      title: title,
      description: _descriptionController.text.trim(),
      dueDate: dueDateTime,
      priority: _priority,
      color: _selectedColor,
      tags: tags,
      hasNotification: _hasNotification && _hasTime,
      notificationMinutesBefore: _notificationMinutesBefore ?? 0,
    );

    _debugPrintUpdatedTaskDetails(updatedTask);
    taskBloc.add(UpdateTask(updatedTask));
  }

  /// Debug print updated task details
  void _debugPrintUpdatedTaskDetails(TaskModel updatedTask) {
    debugPrint('📝 Updated task notification settings:');
    debugPrint('  - hasNotification: ${updatedTask.hasNotification}');
    debugPrint(
      '  - notificationMinutesBefore: ${updatedTask.notificationMinutesBefore}',
    );
  }

  /// Create a new task
  void _createTask(
    TaskBloc taskBloc,
    String title,
    DateTime? dueDateTime,
    List<String> tags,
  ) {
    final newTask = TaskModel(
      title: title,
      description: _descriptionController.text.trim(),
      dueDate: dueDateTime,
      priority: _priority,
      color: _selectedColor,
      tags: tags,
      hasNotification: _hasNotification && _hasTime,
      notificationMinutesBefore: _notificationMinutesBefore ?? 0,
    );

    _debugPrintNewTaskDetails(newTask);
    taskBloc.add(AddTask(newTask));
  }

  /// Debug print new task details
  void _debugPrintNewTaskDetails(TaskModel newTask) {
    debugPrint('📝 New task notification settings:');
    debugPrint('  - hasNotification: ${newTask.hasNotification}');
    debugPrint(
      '  - notificationMinutesBefore: ${newTask.notificationMinutesBefore}',
    );
    debugPrint('  - dueDate: ${newTask.dueDate}');
  }
}
