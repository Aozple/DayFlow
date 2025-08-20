import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_event.dart';
import 'package:dayflow/presentation/blocs/tasks/task_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/custom_snackbar.dart';
import '../../../data/models/task_model.dart';

// This screen displays the detailed information of a single task.
class TaskDetailsScreen extends StatefulWidget {
  // The task object whose details are to be displayed.
  final TaskModel task;

  const TaskDetailsScreen({super.key, required this.task});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

// The state class for our TaskDetailsScreen.
class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  // Holds the current task data, which might be updated by the BLoC.
  late TaskModel _currentTask;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task; // Initialize with the task passed to the widget.
  }

  @override
  Widget build(BuildContext context) {
    // BlocListener listens for changes in the TaskBloc state.
    // If the task is updated (e.g., marked complete), we update our local state.
    return BlocListener<TaskBloc, TaskState>(
      listener: (context, state) {
        if (state is TaskLoaded) {
          // Find the updated version of our task from the loaded tasks.
          final updatedTask = state.tasks.firstWhere(
            (t) => t.id == _currentTask.id,
            orElse: () => _currentTask, // Fallback to current task if not found.
          );

          // If the task has actually changed, update the UI.
          if (updatedTask != _currentTask) {
            setState(() {
              _currentTask = updatedTask;
            });
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(), // iOS-style scroll physics.
          slivers: [
            // A custom app bar that expands and collapses.
            SliverAppBar(
              expandedHeight: 120, // Height when fully expanded.
              floating: false, // Does not float above content.
              pinned: true, // Stays visible at the top when scrolling up.
              backgroundColor: Colors.transparent, // Transparent background.
              elevation: 0, // No shadow.
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // Apply a blur effect.
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.surface.withAlpha(220), // Semi-transparent surface for gradient.
                          AppColors.surface.withAlpha(180),
                        ],
                      ),
                    ),
                    child: FlexibleSpaceBar(
                      centerTitle: true,
                      titlePadding: const EdgeInsets.only(bottom: 14),
                      title: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Task title.
                          Text(
                            _currentTask.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis, // Truncate long titles.
                          ),
                          const SizedBox(height: 2),
                          // Task completion status.
                          Text(
                            _currentTask.isCompleted
                                ? 'Completed'
                                : 'In Progress',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color:
                                  _currentTask.isCompleted
                                      ? AppColors.success // Green for completed.
                                      : AppColors.accent, // Accent color for in progress.
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              leading: Container(
                margin: const EdgeInsets.only(left: 8),
                child: CircleAvatar(
                  backgroundColor: AppColors.surfaceLight,
                  child: IconButton(
                    icon: const Icon(
                      CupertinoIcons.chevron_back, // Back arrow icon.
                      color: AppColors.textPrimary,
                      size: 22,
                    ),
                    onPressed: () => context.pop(), // Pop the current screen.
                  ),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: CircleAvatar(
                    backgroundColor: AppColors.surfaceLight,
                    child: IconButton(
                      icon: Icon(
                        CupertinoIcons.ellipsis, // Ellipsis (more options) icon.
                        color: AppColors.accent,
                        size: 22,
                      ),
                      onPressed: _showMoreOptions, // Show more options action sheet.
                    ),
                  ),
                ),
              ],
            ),

            // The main content of the task details screen.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section for primary actions (complete, edit, delete).
                    _buildPrimaryActions(),

                    const SizedBox(height: 20),

                    // Section displaying task information (date, priority, color).
                    _buildTaskInfo(),

                    // Description section, only shown if a description exists.
                    if (_currentTask.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 16),
                      _buildDescription(),
                    ],

                    // Tags section, only shown if tags exist.
                    if (_currentTask.tags.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildTags(),
                    ],

                    const SizedBox(height: 16),

                    // Metadata section (created at, completed at).
                    _buildMetadata(),

                    const SizedBox(height: 80), // Extra space at the bottom.
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds the row of primary action buttons (Complete/Undo, Edit, Delete).
  Widget _buildPrimaryActions() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface, // Background color for the action bar.
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Button to mark task as complete or undo completion.
          Expanded(
            child: _buildPrimaryButton(
              icon:
                  _currentTask.isCompleted
                      ? CupertinoIcons.arrow_uturn_left // Undo icon.
                      : CupertinoIcons.checkmark_circle, // Complete icon.
              label: _currentTask.isCompleted ? 'Undo' : 'Complete',
              color:
                  _currentTask.isCompleted
                      ? AppColors.warning // Warning color for undo.
                      : AppColors.success, // Success color for complete.
              onTap: _toggleComplete, // Toggles completion status.
              isFirst: true, // Marks as the first button for styling.
            ),
          ),

          Container(width: 1, height: 60, color: AppColors.divider), // Vertical divider.

          // Button to edit the task.
          Expanded(
            child: _buildPrimaryButton(
              icon: CupertinoIcons.pencil_circle, // Pencil icon.
              label: 'Edit',
              color: AppColors.accent, // Accent color.
              onTap: _editTask, // Navigates to edit screen.
              isFirst: false,
            ),
          ),

          Container(width: 1, height: 60, color: AppColors.divider), // Vertical divider.

          // Button to delete the task.
          Expanded(
            child: _buildPrimaryButton(
              icon: CupertinoIcons.trash_circle, // Trash icon.
              label: 'Delete',
              color: AppColors.error, // Error color for destructive action.
              onTap: _deleteTask, // Shows delete confirmation.
              isFirst: false,
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to build a single primary action button.
  Widget _buildPrimaryButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isFirst, // Not directly used for styling here, but good for consistency.
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        height: 80, // Fixed height for consistent layout.
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28), // Icon.
            const SizedBox(height: 6),
            Text(
              label, // Button label.
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds the section displaying task's schedule, priority, and color.
  Widget _buildTaskInfo() {
    final taskColor = AppColors.fromHex(_currentTask.color); // Convert hex string to Color object.

    return Container(
      width: double.infinity, // Takes full available width.
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface, // Background color.
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: taskColor, width: 4)), // Left border with task's color.
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date & Time information with an edit button.
          _buildInfoItem(
            icon: CupertinoIcons.calendar, // Calendar icon.
            label: 'Schedule',
            value:
                _currentTask.dueDate != null
                    ? DateFormat(
                      'EEE, MMM d • HH:mm', // Format date and time.
                    ).format(_currentTask.dueDate!)
                    : 'No date set', // Display if no due date.
            onEdit: _quickReschedule, // Opens date/time picker.
          ),

          const Divider(height: 24, color: AppColors.divider), // Divider.

          // Priority information with an edit button.
          _buildInfoItem(
            icon: CupertinoIcons.flag_fill, // Flag icon.
            label: 'Priority',
            value: 'Level ${_currentTask.priority}',
            valueColor: AppColors.getPriorityColor(_currentTask.priority), // Color based on priority.
            onEdit: _quickChangePriority, // Opens priority picker.
          ),

          const Divider(height: 24, color: AppColors.divider), // Divider.

          // Color information with an edit button.
          _buildInfoItem(
            icon: CupertinoIcons.paintbrush_fill, // Paintbrush icon.
            label: 'Color',
            value: null, // No text value, using custom widget.
            customWidget: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: taskColor, // Display task's color.
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider, width: 2),
              ),
            ),
            onEdit: _quickChangeColor, // Opens color picker.
          ),
        ],
      ),
    );
  }

  // Helper widget to build a single info item (icon, label, value, edit button).
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    String? value,
    Color? valueColor,
    Widget? customWidget,
    required VoidCallback onEdit,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: valueColor ?? AppColors.textSecondary), // Icon.
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label, // Label (e.g., "Schedule").
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
              if (value != null) ...[
                const SizedBox(height: 2),
                Text(
                  value, // Value (e.g., "Mon, Aug 21 • 14:30").
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
              ],
              if (customWidget != null) ...[
                const SizedBox(height: 4),
                customWidget, // Custom widget if provided (e.g., color circle).
              ],
            ],
          ),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 32,
          onPressed: onEdit, // Edit button action.
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(20), // Subtle accent background.
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              CupertinoIcons.pencil, // Pencil icon.
              size: 16,
              color: AppColors.accent,
            ),
          ),
        ),
      ],
    );
  }

  // Builds the section displaying the task's description.
  Widget _buildDescription() {
    return Container(
      width: double.infinity, // Full width.
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface, // Background color.
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                CupertinoIcons.doc_text, // Document icon.
                size: 18,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 8),
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _currentTask.description!, // Display the description text.
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              height: 1.5, // Line height for readability.
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  // Builds the section displaying the task's tags.
  Widget _buildTags() {
    return Container(
      width: double.infinity, // Full width.
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface, // Background color.
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                CupertinoIcons.tag, // Tag icon.
                size: 18,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 8),
              Text(
                'Tags',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10, // Horizontal spacing between tags.
            runSpacing: 10, // Vertical spacing between rows of tags.
            children:
                _currentTask.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(25), // Subtle accent background.
                      borderRadius: BorderRadius.circular(20), // Capsule shape for tags.
                      border: Border.all(
                        color: AppColors.accent.withAlpha(50),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.number, // Number icon (could be a generic tag icon too).
                          size: 14,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tag, // The tag text.
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  // Builds the section displaying task metadata (created at, completed at).
  Widget _buildMetadata() {
    return Container(
      width: double.infinity, // Full width.
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(150), // Slightly transparent surface.
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withAlpha(50), width: 1), // Subtle border.
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                CupertinoIcons.info_circle, // Info icon.
                size: 18,
                color: AppColors.textTertiary,
              ),
              SizedBox(width: 8),
              Text(
                'Information',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row for creation date.
          _buildMetaRow(
            'Created',
            DateFormat('MMM d, yyyy • HH:mm').format(_currentTask.createdAt),
          ),
          // Row for completion date, only shown if completed.
          if (_currentTask.completedAt != null) ...[
            const SizedBox(height: 8),
            _buildMetaRow(
              'Completed',
              DateFormat(
                'MMM d, yyyy • HH:mm',
              ).format(_currentTask.completedAt!),
              valueColor: AppColors.success, // Green color for completion date.
            ),
          ],
        ],
      ),
    );
  }

  // Helper widget to build a single metadata row (label and value).
  Widget _buildMetaRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label, // Label (e.g., "Created").
          style: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
        ),
        Text(
          value, // Value (e.g., "Aug 21, 2025 • 14:30").
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: valueColor ?? AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // Shows a Cupertino modal for quickly rescheduling a task.
  void _quickReschedule() async {
    final DateTime? picked = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder:
          (context) => Container(
            height: 300,
            color: AppColors.surface, // Background color.
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context), // Cancel button.
                        child: const Text('Cancel'),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          Navigator.pop(context, _currentTask.dueDate); // Pass current due date back.
                        },
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.dateAndTime, // Allow date and time selection.
                    initialDateTime: _currentTask.dueDate ?? DateTime.now(), // Initial date.
                    onDateTimeChanged: (date) {
                      setState(() {
                        _currentTask = _currentTask.copyWith(dueDate: date); // Update local task with new date.
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
    );

    // If a date was picked and the widget is still mounted, update the task.
    if (picked != null && mounted) {
      context.read<TaskBloc>().add(UpdateTask(_currentTask)); // Dispatch update event.
      CustomSnackBar.success(context, 'Date updated'); // Show success message.
    }
  }

  // Shows a Cupertino action sheet for quickly changing task priority.
  void _quickChangePriority() {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: const Text('Select Priority'),
            actions: List.generate(5, (index) {
              final priority = index + 1; // Priority levels 1 to 5.
              return CupertinoActionSheetAction(
                onPressed: () {
                  setState(() {
                    _currentTask = _currentTask.copyWith(priority: priority); // Update local task with new priority.
                  });
                  context.read<TaskBloc>().add(UpdateTask(_currentTask)); // Dispatch update event.
                  Navigator.pop(context); // Close action sheet.
                  CustomSnackBar.success(context, 'Priority updated'); // Show success message.
                },
                child: Text('Priority $priority'), // Display priority level.
              );
            }),
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context), // Cancel button.
              child: const Text('Cancel'),
            ),
          ),
    );
  }

  // Shows a Cupertino modal for quickly changing task color.
  void _quickChangeColor() {
    String selectedColorHex = _currentTask.color; // Local state for the picker.

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 320,
              decoration: const BoxDecoration(
                color: AppColors.surface, // Background color.
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Drag handle.
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header for the color picker modal.
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(modalContext), // Cancel button.
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Text(
                          'Select Color', // Title.
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            // Update task with selected color.
                            setState(() {
                              _currentTask = _currentTask.copyWith(
                                color: selectedColorHex,
                              );
                            });
                            context.read<TaskBloc>().add(
                              UpdateTask(_currentTask), // Dispatch update event.
                            );
                            Navigator.pop(modalContext); // Close modal.
                            CustomSnackBar.success(context, 'Color updated'); // Show success message.
                          },
                          child: Text(
                            'Done',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Divider.
                  Container(height: 1, color: AppColors.divider),

                  // Grid of color options.
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Calculate item size dynamically.
                          final itemSize =
                              (constraints.maxWidth - (3 * 16)) / 4;

                          return Wrap(
                            spacing: 16, // Horizontal spacing.
                            runSpacing: 16, // Vertical spacing.
                            children:
                                AppColors.userColors.map((color) {
                                  final colorHex = AppColors.toHex(color);
                                  final isSelected =
                                      selectedColorHex == colorHex; // Check if this color is selected.

                                  return GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        selectedColorHex = colorHex; // Update local selection.
                                      });

                                      HapticFeedback.lightImpact(); // Provide haptic feedback.
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      width: itemSize,
                                      height: itemSize,
                                      decoration: BoxDecoration(
                                        color: color, // The actual color.
                                        shape: BoxShape.circle,
                                        boxShadow:
                                            isSelected
                                                ? [
                                                  BoxShadow(
                                                    color: color.withAlpha(100),
                                                    blurRadius: 8,
                                                    spreadRadius: 2,
                                                  ),
                                                ]
                                                : [], // No shadow if not selected.
                                        border: Border.all(
                                          color:
                                              isSelected
                                                  ? Colors.white // White border if selected.
                                                  : AppColors.divider.withAlpha(
                                                    50,
                                                  ), // Subtle border otherwise.
                                          width: isSelected ? 3 : 1,
                                        ),
                                      ),
                                      child:
                                          isSelected
                                              ? TweenAnimationBuilder<double>(
                                                tween: Tween(begin: 0, end: 1), // Scale animation for checkmark.
                                                duration: const Duration(
                                                  milliseconds: 200,
                                                ),
                                                builder: (
                                                  context,
                                                  value,
                                                  child,
                                                ) {
                                                  return Transform.scale(
                                                    scale: value,
                                                    child: const Icon(
                                                      CupertinoIcons.checkmark, // Checkmark icon.
                                                      color: Colors.white,
                                                      size: 20,
                                                      weight: 700,
                                                    ),
                                                  );
                                                },
                                              )
                                              : null, // No child if not selected.
                                    ),
                                  );
                                }).toList(),
                          );
                        },
                      ),
                    ),
                  ),

                  // Bottom safe area padding.
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Shows an action sheet with more options for the task (duplicate, share).
  void _showMoreOptions() {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context); // Close action sheet.
                  _duplicateTask(); // Duplicate the task.
                },
                child: const Text('Duplicate Task'),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context); // Close action sheet.
                  // TODO: Implement actual share functionality.
                  CustomSnackBar.info(context, 'Share coming soon!'); // Placeholder message.
                },
                child: const Text('Share Task'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context), // Cancel button.
              child: const Text('Cancel'),
            ),
          ),
    );
  }

  // Toggles the completion status of the current task.
  void _toggleComplete() {
    context.read<TaskBloc>().add(ToggleTaskComplete(_currentTask.id)); // Dispatch event to BLoC.
    setState(() {
      _currentTask = _currentTask.copyWith(
        isCompleted: !_currentTask.isCompleted, // Flip completion status.
        completedAt: !_currentTask.isCompleted ? DateTime.now() : null, // Set/clear completion timestamp.
      );
    });

    CustomSnackBar.success(
      context,
      _currentTask.isCompleted ? 'Task completed!' : 'Task marked as pending', // Show appropriate message.
    );
  }

  // Navigates to the edit task screen with the current task data.
  void _editTask() {
    context.push('/edit-task', extra: _currentTask);
  }

  // Duplicates the current task and adds it as a new task.
  void _duplicateTask() {
    final newTask = TaskModel(
      title: '${_currentTask.title} (Copy)', // Add "(Copy)" to the title.
      description: _currentTask.description,
      dueDate: _currentTask.dueDate,
      priority: _currentTask.priority,
      color: _currentTask.color,
      tags: _currentTask.tags,
    );

    context.read<TaskBloc>().add(AddTask(newTask)); // Dispatch add event.
    CustomSnackBar.success(context, 'Task duplicated!'); // Show success message.
    context.pop(); // Pop the details screen.
  }

  // Shows a confirmation dialog before deleting the task.
  void _deleteTask() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Delete Task'),
            content: const Text('Are you sure you want to delete this task?'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.pop(context, false), // Cancel button.
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true, // Red button.
                onPressed: () => Navigator.pop(context, true), // Confirm delete.
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    // If deletion is confirmed and widget is still mounted, delete the task.
    if (confirmed == true && mounted) {
      context.read<TaskBloc>().add(DeleteTask(_currentTask.id)); // Dispatch delete event.
      CustomSnackBar.success(context, 'Task deleted'); // Show success message.
      context.pop(); // Pop the details screen.
    }
  }
}
