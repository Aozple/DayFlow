import 'package:dayflow/presentation/screens/task/widgets/create_task_date_picker.dart';
import 'package:dayflow/presentation/screens/task/widgets/create_task_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:dayflow/presentation/blocs/settings/settings_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_event.dart';
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
  /// Text controllers for our input fields.
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagsController;

  /// Variables to hold the selected date, time, priority, and color.
  late DateTime _selectedDate;
  late TimeOfDay? _selectedTime;
  late int _priority;
  late String _selectedColor;

  /// Flag to check if a specific time is set for the task.
  bool _hasTime = false;

  /// Focus nodes to manage keyboard focus on text fields.
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();

  /// A getter to easily check if we are in edit mode.
  bool get isEditMode => widget.taskToEdit != null;

  @override
  void initState() {
    super.initState();
    // Initialize text controllers with existing task data if in edit mode, otherwise empty.
    _titleController = TextEditingController(
      text: widget.taskToEdit?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.taskToEdit?.description ?? '',
    );
    _tagsController = TextEditingController(
      text: widget.taskToEdit?.tags.join(', ') ?? '',
    );

    // Initialize form values based on whether we're editing an existing task or creating a new one.
    if (isEditMode && widget.taskToEdit != null) {
      final task = widget.taskToEdit!;
      _selectedDate = task.dueDate ?? DateTime.now();
      _selectedTime =
          task.dueDate != null
              ? TimeOfDay.fromDateTime(task.dueDate!)
              : TimeOfDay.now();
      _hasTime = task.dueDate != null;
      _priority = task.priority;
      _selectedColor = task.color;
    } else {
      // If creating a new task, use prefilled date or current date.
      _selectedDate = widget.prefilledDate ?? DateTime.now();
      // If a prefilled hour is provided, set the time and enable the time picker.
      if (widget.prefilledHour != null) {
        _selectedTime = TimeOfDay(hour: widget.prefilledHour!, minute: 0);
        _hasTime = true; // Automatically enable time
      } else {
        _selectedTime = TimeOfDay.now();
        _hasTime = false;
      }
      // Get the default priority from the app settings.
      final settingsState = context.read<SettingsBloc>().state;
      _priority =
          settingsState is SettingsLoaded ? settingsState.defaultPriority : 3;
      // Set the default color for new tasks.
      _selectedColor = AppColors.toHex(AppColors.userColors[0]);
    }

    // For new tasks, automatically focus on the title input field.
    if (!isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _titleFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    // Clean up controllers and focus nodes to prevent memory leaks.
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
      body: SafeArea(
        child: Column(
          children: [
            // The header section with cancel and save buttons.
            CreateTaskHeader(
              isEditMode: isEditMode,
              canSave: _canSave(),
              onCancel: () => context.pop(),
              onSave: _saveTask,
            ),
            // The main scrollable content area for task details.
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Section for task title and description.
                    CreateTaskMainContent(
                      titleController: _titleController,
                      descriptionController: _descriptionController,
                      titleFocus: _titleFocus,
                      descriptionFocus: _descriptionFocus,
                      onChanged:
                          () => setState(
                            () {},
                          ), // Rebuild to update save button state.
                    ),
                    const SizedBox(height: 16),
                    // Section for selecting date and time.
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
                    // Section for choosing task priority.
                    CreateTaskPrioritySection(
                      priority: _priority,
                      onPriorityChanged:
                          (priority) => setState(() => _priority = priority),
                    ),
                    const SizedBox(height: 16),
                    // Section for selecting a task color.
                    CreateTaskColorSection(
                      selectedColor: _selectedColor,
                      onColorChanged:
                          (color) => setState(() => _selectedColor = color),
                    ),
                    const SizedBox(height: 16),
                    // Section for adding tags to the task.
                    CreateTaskTagsSection(tagsController: _tagsController),
                    const SizedBox(height: 100), // Extra space for keyboard.
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Checks if the task can be saved (i.e., if the title is not empty).
  bool _canSave() {
    return _titleController.text.trim().isNotEmpty;
  }

  /// Shows a Cupertino-style modal for selecting a date.
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

  /// Shows a Cupertino-style modal for selecting a time.
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

  /// Handles saving or updating the task based on the current mode.
  void _saveTask() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return; // Don't save if the title is empty.

    // Get the TaskBloc instance to dispatch events.
    final taskBloc = context.read<TaskBloc>();

    // Parse tags from the input field, splitting by comma and cleaning up.
    final tags =
        _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList();

    // Combine the selected date and time into a single DateTime object.
    DateTime? dueDateTime;
    if (_hasTime && _selectedTime != null) {
      dueDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    } else {
      dueDateTime = _selectedDate; // If no time, just use the date.
    }

    if (isEditMode) {
      // If in edit mode, create an updated task object and dispatch an UpdateTask event.
      final updatedTask = widget.taskToEdit!.copyWith(
        title: title,
        description: _descriptionController.text.trim(),
        dueDate: dueDateTime,
        priority: _priority,
        color: _selectedColor,
        tags: tags,
      );
      taskBloc.add(UpdateTask(updatedTask));
    } else {
      // If creating a new task, create a new TaskModel and dispatch an AddTask event.
      final newTask = TaskModel(
        title: title,
        description: _descriptionController.text.trim(),
        dueDate: dueDateTime,
        priority: _priority,
        color: _selectedColor,
        tags: tags,
      );
      taskBloc.add(AddTask(newTask));
    }

    // Navigate back to the previous screen after saving.
    context.pop();
  }
}
