import 'package:dayflow/presentation/blocs/settings/settings_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/task_model.dart';

// This screen is for creating a new task or editing an existing one.
class CreateTaskScreen extends StatefulWidget {
  // Optional task to edit. If null, we're creating a new task.
  final TaskModel? taskToEdit;
  // Optional task ID, might be used for deep linking or specific scenarios.
  final String? taskId;
  // Optional pre-filled hour for convenience, e.g., from a calendar view.
  final int? prefilledHour;
  // Optional pre-filled date for convenience.
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

// The state class for our CreateTaskScreen.
class _CreateTaskScreenState extends State<CreateTaskScreen> {
  // Text controllers for our input fields.
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagsController;

  // Variables to hold the selected date, time, priority, and color.
  late DateTime _selectedDate;
  late TimeOfDay? _selectedTime;
  late int _priority;
  late String _selectedColor;
  // Flag to check if a specific time is set for the task.
  bool _hasTime = false;

  // Focus nodes to manage keyboard focus on text fields.
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();

  // A getter to easily check if we are in edit mode.
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
            _buildHeader(),

            // The main scrollable content area for task details.
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Section for task title and description.
                    _buildMainContentSection(),

                    const SizedBox(height: 16),

                    // Section for selecting date and time.
                    _buildDateTimeSection(),

                    const SizedBox(height: 16),

                    // Section for choosing task priority.
                    _buildPrioritySection(),

                    const SizedBox(height: 16),

                    // Section for selecting a task color.
                    _buildColorSection(),

                    const SizedBox(height: 16),

                    // Section for adding tags to the task.
                    _buildTagsSection(),

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

  // Builds the header bar with "Cancel", "New Task/Edit Task" title, and "Add/Update" buttons.
  Widget _buildHeader() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: AppColors.surface.withAlpha(200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Button to cancel and go back.
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => context.pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.accent, fontSize: 17),
                ),
              ),

              // Title of the screen, changes based on edit or new task mode.
              Text(
                isEditMode ? 'Edit Task' : 'New Task',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),

              // Button to save or update the task. It's disabled if the title is empty.
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _canSave() ? _saveTask : null,
                child: Text(
                  isEditMode ? 'Update' : 'Add',
                  style: TextStyle(
                    color:
                        _canSave() ? AppColors.accent : AppColors.textTertiary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Builds the main content section including title and description input fields.
  Widget _buildMainContentSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Text field for the task title.
          TextField(
            controller: _titleController,
            focusNode: _titleFocus,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: 'Task title',
              hintStyle: TextStyle(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.normal,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}), // Rebuild to update save button state.
          ),

          // A thin divider line.
          Container(
            height: 0.5,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: AppColors.divider,
          ),

          // Text field for the task description.
          TextField(
            controller: _descriptionController,
            focusNode: _descriptionFocus,
            style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Add description',
              hintStyle: TextStyle(color: AppColors.textTertiary),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 3, // Allows up to 3 lines before scrolling.
            minLines: 1, // Starts with at least 1 line.
          ),
        ],
      ),
    );
  }

  // Builds the section for selecting the task's date and time.
  Widget _buildDateTimeSection() {
    // Check if the date was prefilled from another screen.
    final isPrefilled = widget.prefilledDate != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        // Add a subtle border if the date was prefilled.
        border:
            isPrefilled
                ? Border.all(color: AppColors.accent.withAlpha(50), width: 1)
                : null,
      ),
      child: Column(
        children: [
          // List tile for picking the date.
          ListTile(
            leading: Icon(
              CupertinoIcons.calendar,
              color: AppColors.accent,
              size: 22,
            ),
            title: const Text(
              'Date',
              style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
            ),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _selectDate, // Opens the date picker.
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Show a "Prefilled" tag if the date came from another screen.
                  if (isPrefilled) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Prefilled',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  // Display the selected date.
                  Text(
                    DateFormat('EEE, MMM d').format(_selectedDate),
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 15,
                      fontWeight:
                          isPrefilled ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Divider below the date picker.
          Container(
            height: 0.5,
            margin: const EdgeInsets.only(left: 56),
            color: AppColors.divider,
          ),

          // Switch to enable/disable time selection for the task.
          SwitchListTile(
            secondary: Icon(
              CupertinoIcons.clock,
              color: _hasTime ? AppColors.accent : AppColors.textSecondary,
              size: 22,
            ),
            title: const Text(
              'Time',
              style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
            ),
            value: _hasTime,
            onChanged: (value) {
              setState(() => _hasTime = value);
              // If time is enabled and no time is selected, default to now.
              if (value && _selectedTime == null) {
                _selectedTime = TimeOfDay.now();
              }
            },
            activeColor: AppColors.accent,
          ),

          // Time picker section, only visible if _hasTime is true.
          if (_hasTime) ...[
            // Divider above the time picker.
            Container(
              height: 0.5,
              margin: const EdgeInsets.only(left: 56),
              color: AppColors.divider,
            ),
            ListTile(
              leading: const SizedBox(width: 22), // Aligns with other list tiles.
              title: const Text(
                'Time',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Show a "Prefilled" tag if the time came from another screen.
                  if (isPrefilled) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Prefilled',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  // Button to open the time picker.
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _selectTime,
                    child: Text(
                      _selectedTime?.format(context) ?? 'Select time', // Display selected time or a placeholder.
                      style: TextStyle(color: AppColors.accent, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Builds the section for selecting task priority.
  Widget _buildPrioritySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.flag, color: AppColors.accent, size: 22),
              const SizedBox(width: 12),
              const Text(
                'Priority',
                style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Row of priority selection buttons (1 to 5).
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (index) {
              final priority = index + 1;
              final isSelected = _priority == priority;

              return GestureDetector(
                onTap: () => setState(() => _priority = priority), // Update selected priority.
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200), // Smooth animation for selection.
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppColors.accent : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.divider,
                      width: isSelected ? 0 : 1,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Display the priority number.
                        Text(
                          priority.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                          ),
                        ),
                        // Add "High" label for priority 5.
                        if (priority == 5)
                          Text(
                            'High',
                            style: TextStyle(
                              fontSize: 9,
                              color:
                                  isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                            ),
                          ),
                        // Add "Low" label for priority 1.
                        if (priority == 1)
                          Text(
                            'Low',
                            style: TextStyle(
                              fontSize: 9,
                              color:
                                  isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // Builds the section for selecting a task color.
  Widget _buildColorSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.paintbrush,
                color: AppColors.accent,
                size: 22,
              ),
              const SizedBox(width: 12),
              const Text(
                'Color',
                style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Wrap widget to display color options, allowing them to wrap to the next line.
          Wrap(
            spacing: 12, // Horizontal spacing between color circles.
            runSpacing: 12, // Vertical spacing between lines of color circles.
            children:
                // Map through our predefined user colors to create selectable circles.
                AppColors.userColors.map((color) {
                  final colorHex = AppColors.toHex(color); // Convert color to hex string for comparison.
                  final isSelected = _selectedColor == colorHex; // Check if this color is currently selected.

                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = colorHex), // Update selected color on tap.
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200), // Smooth animation for selection.
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color, // The actual color of the circle.
                        shape: BoxShape.circle, // Make it a circle.
                        border: Border.all(
                          color:
                              isSelected
                                  ? AppColors.textPrimary // Highlight border if selected.
                                  : Colors.transparent, // No border if not selected.
                          width: 3,
                        ),
                      ),
                      child:
                          isSelected
                              ? const Icon(
                                Icons.check, // Show a checkmark if selected.
                                color: Colors.white,
                                size: 20,
                              )
                              : null, // No child if not selected.
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  // Builds the section for adding tags to the task.
  Widget _buildTagsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _tagsController, // Controller for the tags input.
        style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
        decoration: const InputDecoration(
          hintText: 'Add tags (comma separated)', // Placeholder text.
          hintStyle: TextStyle(color: AppColors.textTertiary),
          prefixIcon: Icon(
            CupertinoIcons.tag, // Tag icon.
            color: AppColors.textSecondary,
            size: 22,
          ),
          border: InputBorder.none, // No border for the input field.
          contentPadding: EdgeInsets.all(16),
        ),
      ),
    );
  }

  // Checks if the task can be saved (i.e., if the title is not empty).
  bool _canSave() {
    return _titleController.text.trim().isNotEmpty;
  }

  // Shows a Cupertino-style modal for selecting a date.
  void _selectDate() async {
    await showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            height: 250, // Fixed height for the date picker.
            color: AppColors.surface, // Background color of the picker.
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date, // Only show date selection.
              initialDateTime: _selectedDate, // Start with the currently selected date.
              minimumDate: DateTime.now().subtract(const Duration(days: 1)), // Can't select dates before yesterday.
              onDateTimeChanged: (date) {
                setState(() => _selectedDate = date); // Update the selected date.
              },
            ),
          ),
    );
  }

  // Shows a Cupertino-style modal for selecting a time.
  void _selectTime() async {
    await showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            height: 250, // Fixed height for the time picker.
            color: AppColors.surface, // Background color of the picker.
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time, // Only show time selection.
              initialDateTime: DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                _selectedTime?.hour ?? 0, // Use selected time's hour or default to 0.
                _selectedTime?.minute ?? 0, // Use selected time's minute or default to 0.
              ),
              onDateTimeChanged: (date) {
                setState(() {
                  _selectedTime = TimeOfDay(
                    hour: date.hour,
                    minute: date.minute,
                  );
                });
              },
            ),
          ),
    );
  }

  // Handles saving or updating the task based on the current mode.
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
