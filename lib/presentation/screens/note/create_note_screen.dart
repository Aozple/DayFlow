import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/custom_snackbar.dart';
import '../../../data/models/task_model.dart';
import 'widgets/create_note_header.dart';
import 'widgets/create_note_title_section.dart';
import 'widgets/create_note_markdown_toolbar.dart';
import 'widgets/create_note_editor.dart';
import 'widgets/create_note_preview.dart';
import 'widgets/create_note_word_count.dart';
import 'widgets/create_note_color_picker.dart';
import 'widgets/create_note_date_time_picker.dart';
import 'widgets/create_note_discard_dialog.dart';

/// Screen for creating a new note or editing an existing one.
///
/// This screen provides a rich text editing experience with Markdown support,
/// including a preview mode, color customization, and date/time selection.
/// It handles both creating new notes and editing existing ones with auto-save functionality.
class CreateNoteScreen extends StatefulWidget {
  /// The note object to edit. If null, we're creating a new note.
  final TaskModel? noteToEdit;

  /// Optional pre-filled hour for convenience, e.g., from a calendar view.
  final int? prefilledHour;

  /// Optional pre-filled date for convenience.
  final DateTime? prefilledDate;

  const CreateNoteScreen({
    super.key,
    this.noteToEdit,
    this.prefilledHour,
    this.prefilledDate,
  });

  @override
  State<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

/// State class for CreateNoteScreen, managing all its dynamic behavior.
///
/// This class handles the core functionality of the note creation/editing screen,
/// including text controllers, animations, user interactions, and state management.
class _CreateNoteScreenState extends State<CreateNoteScreen>
    with TickerProviderStateMixin {
  /// Text controllers for the note's title, content, and tags.
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagsController;

  /// Animation controllers for the preview and markdown toolbar.
  late AnimationController _previewAnimationController;
  late AnimationController _toolbarAnimationController;
  late Animation<double> _toolbarAnimation;

  /// State variables for the note's properties and UI mode.
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isPreviewMode = false; // True if in preview mode, false for editor.
  String _selectedColor = AppColors.toHex(
    AppColors.userColors[6],
  ); // Default note color (purple).
  bool _hasChanges = false; // Tracks if there are unsaved changes.
  final bool _autoSaveEnabled = true; // Flag for auto-save functionality.

  /// Focus nodes to manage keyboard focus on text fields.
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _contentFocus = FocusNode();

  /// Scroll controller for the content editor.
  final ScrollController _scrollController = ScrollController();

  /// A getter to easily check if we are in edit mode.
  bool get isEditMode => widget.noteToEdit != null;

  @override
  void initState() {
    super.initState();
    // Initialize text controllers with existing note data if in edit mode, otherwise empty.
    _titleController = TextEditingController(
      text: widget.noteToEdit?.title ?? '',
    );
    _contentController = TextEditingController(
      text: widget.noteToEdit?.markdownContent ?? '',
    );
    _tagsController = TextEditingController(
      text: widget.noteToEdit?.tags.join(', ') ?? '',
    );

    // Initialize note properties based on whether we're editing or creating.
    if (isEditMode && widget.noteToEdit != null) {
      _selectedDate = widget.noteToEdit!.dueDate ?? DateTime.now();
      _selectedTime = TimeOfDay.fromDateTime(
        widget.noteToEdit!.dueDate ?? DateTime.now(),
      );
      _selectedColor = widget.noteToEdit!.color;
    } else {
      // Use prefilled date and time if provided, otherwise current date/time.
      _selectedDate = widget.prefilledDate ?? DateTime.now();
      if (widget.prefilledHour != null) {
        _selectedTime = TimeOfDay(hour: widget.prefilledHour!, minute: 0);
      } else {
        _selectedTime = TimeOfDay.now();
      }
      // Set default color for new notes (Yellow).
      _selectedColor = AppColors.toHex(AppColors.userColors[4]);
    }

    // Set up animation controllers.
    _previewAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _toolbarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Define the animation curve for the toolbar.
    _toolbarAnimation = CurvedAnimation(
      parent: _toolbarAnimationController,
      curve: Curves.easeOutCubic,
    );

    // Show the toolbar initially.
    _toolbarAnimationController.forward();

    // Add listeners to text controllers to track changes for auto-save and discard dialog.
    _titleController.addListener(_onContentChanged);
    _contentController.addListener(_onContentChanged);
    _tagsController.addListener(_onContentChanged);

    // Auto-focus on the title field for new notes.
    if (!isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _titleFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    // Clean up all controllers and focus nodes to prevent memory leaks.
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    _scrollController.dispose();
    _previewAnimationController.dispose();
    _toolbarAnimationController.dispose();
    super.dispose();
  }

  /// Marks that content has changed, triggering UI updates like auto-save status.
  void _onContentChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  /// Shows a confirmation dialog before deleting a note.
  void _showDeleteConfirmation() {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Delete Note'),
            content: Text(
              'Are you sure you want to delete "${_titleController.text.trim()}"?\n\nThis action cannot be undone.',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context), // Close the dialog.
              ),
              CupertinoDialogAction(
                isDestructiveAction: true, // Make the button red.
                onPressed: () {
                  Navigator.pop(context); // Close the dialog.
                  _deleteCurrentNote(); // Proceed with deleting the note.
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  /// Deletes the current note by dispatching a DeleteTask event to the TaskBloc.
  void _deleteCurrentNote() {
    // Only proceed if we are in edit mode and have a note to delete.
    if (!isEditMode || widget.noteToEdit == null) return;
    final taskBloc = context.read<TaskBloc>();
    // Dispatch the event to delete the note.
    taskBloc.add(DeleteTask(widget.noteToEdit!.id));
    // Show a success message to the user.
    CustomSnackBar.success(context, 'Note deleted successfully');
    // Navigate back to the previous screen (usually home).
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges, // Prevent popping if there are unsaved changes.
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _hasChanges) {
          _showDiscardDialog(); // Show discard dialog if pop is blocked by changes.
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // The header section with blur effect, cancel, and save buttons.
              CreateNoteHeader(
                isEditMode: isEditMode,
                hasChanges: _hasChanges,
                autoSaveEnabled: _autoSaveEnabled,
                isPreviewMode: _isPreviewMode,
                onTogglePreview: _togglePreview,
                onDelete: _showDeleteConfirmation,
                onSave: _saveNote,
                onCancel: () {
                  if (_hasChanges) {
                    _showDiscardDialog();
                  } else {
                    context.pop();
                  }
                },
              ),

              // The main content area, which can switch between editor and preview.
              Expanded(
                child: Stack(
                  children: [
                    // Column containing the title, toolbar, and editor/preview.
                    Column(
                      children: [
                        // Section for the note title and metadata.
                        CreateNoteTitleSection(
                          titleController: _titleController,
                          titleFocus: _titleFocus,
                          selectedColor: _selectedColor,
                          selectedTime: _selectedTime,
                          prefilledDate: widget.prefilledDate,
                          onColorTap: _showColorPicker,
                          onDateTimeTap: _selectDateTime,
                          tagsController: _tagsController,
                        ),

                        // Markdown toolbar, animated to show/hide.
                        AnimatedBuilder(
                          animation: _toolbarAnimation,
                          builder: (context, child) {
                            return SizeTransition(
                              sizeFactor: _toolbarAnimation, // Animates height.
                              child:
                                  _isPreviewMode
                                      ? const SizedBox.shrink() // Hide toolbar in preview mode.
                                      : CreateNoteMarkdownToolbar(
                                        onInsertMarkdown: _insertMarkdown,
                                      ), // Show toolbar in editor mode.
                            );
                          },
                        ),

                        // The main content area, switching between editor and preview with animation.
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) {
                              // Slide transition for switching between editor and preview.
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(
                                    1.0,
                                    0.0,
                                  ), // Starts off-screen to the right.
                                  end:
                                      Offset
                                          .zero, // Slides to its final position.
                                ).animate(animation),
                                child: child,
                              );
                            },
                            child:
                                _isPreviewMode
                                    ? CreateNotePreview(
                                      contentController: _contentController,
                                      selectedDate: _selectedDate,
                                    ) // Show markdown preview.
                                    : CreateNoteEditor(
                                      contentController: _contentController,
                                      contentFocus: _contentFocus,
                                      scrollController: _scrollController,
                                    ), // Show markdown editor.
                          ),
                        ),
                      ],
                    ),
                    // Floating word count, visible only in editor mode with content.
                    if (!_isPreviewMode && _contentController.text.isNotEmpty)
                      CreateNoteWordCount(
                        contentController: _contentController,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Toggles between Markdown editor and preview modes.
  void _togglePreview() {
    setState(() {
      _isPreviewMode = !_isPreviewMode;
    });
    if (_isPreviewMode) {
      _previewAnimationController.forward(); // Start preview animation.
      _toolbarAnimationController.reverse(); // Hide toolbar.
      FocusScope.of(context).unfocus(); // Dismiss the keyboard.
    } else {
      _previewAnimationController.reverse(); // Reverse preview animation.
      _toolbarAnimationController.forward(); // Show toolbar.
    }
    HapticFeedback.lightImpact(); // Provide haptic feedback.
  }

  /// Inserts Markdown syntax (e.g., bold, italic) around the current text selection.
  void _insertMarkdown(String before, String after) {
    final selection = _contentController.selection; // Current text selection.
    final text = _contentController.text; // Full text in the editor.
    final selectedText = selection.textInside(
      text,
    ); // The text currently selected.
    // Create new text by inserting 'before' and 'after' strings around the selection.
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      '$before$selectedText$after',
    );
    // Calculate the new cursor position after insertion.
    final newCursorPos = selection.start + before.length + selectedText.length;
    // Update the text field's value and selection.
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newCursorPos,
      ), // Place cursor after inserted text.
    );
    _contentFocus.requestFocus(); // Keep focus on the content editor.
  }

  /// Shows a Cupertino-style modal for selecting the note's date and time.
  void _selectDateTime() async {
    await showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CreateNoteDateTimePicker(
            selectedDate: _selectedDate,
            selectedTime: _selectedTime,
            onDateTimeChanged: (date) {
              setState(() {
                _selectedDate = date; // Update selected date.
                _selectedTime = TimeOfDay.fromDateTime(
                  date,
                ); // Update selected time.
              });
            },
          ),
    );
  }

  /// Shows a Cupertino-style modal for picking the note's color.
  void _showColorPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext modalContext) {
        return CreateNoteColorPicker(
          initialColor: _selectedColor,
          onColorSelected: (colorHex) {
            setState(
              () => _selectedColor = colorHex,
            ); // Apply selected color to main state.
            CustomSnackBar.success(
              context,
              'Color updated',
            ); // Show success message.
          },
        );
      },
    );
  }

  /// Shows a confirmation dialog when the user tries to leave with unsaved changes.
  void _showDiscardDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => const CreateNoteDiscardDialog(),
    );
  }

  /// Handles saving or updating the note.
  void _saveNote() {
    // If the title is empty, show an error and don't save.
    if (!_canSave()) {
      CustomSnackBar.error(context, 'Please enter a note title');
      return;
    }
    final taskBloc = context.read<TaskBloc>(); // Get the TaskBloc instance.
    // Parse tags from the input field, splitting by comma and cleaning up.
    final tags =
        _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList();
    // Combine the selected date and time into a single DateTime object.
    final dueDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    if (isEditMode) {
      // If in edit mode, create an updated note object and dispatch an UpdateTask event.
      final updatedNote = widget.noteToEdit!.copyWith(
        title: _titleController.text.trim(),
        markdownContent: _contentController.text,
        dueDate: dueDateTime,
        color: _selectedColor,
        tags: tags,
        isNote: true, // Ensure it remains a note.
      );
      taskBloc.add(UpdateTask(updatedNote)); // Dispatch update event.
      CustomSnackBar.success(
        context,
        'Note updated successfully',
      ); // Show success message.
    } else {
      // If creating a new note, create a new TaskModel and dispatch an AddTask event.
      final newNote = TaskModel(
        title: _titleController.text.trim(),
        markdownContent: _contentController.text,
        dueDate: dueDateTime,
        color: _selectedColor,
        tags: tags,
        isNote: true, // Mark as a note.
        priority: 1, // Notes usually have a low default priority.
      );
      taskBloc.add(AddTask(newNote)); // Dispatch add event.
      CustomSnackBar.success(
        context,
        'Note created successfully',
      ); // Show success message.
    }
    _hasChanges = false; // Reset changes flag after saving.
    context.pop(); // Navigate back to the previous screen.
  }

  /// Checks if the note can be saved (i.e., if the title is not empty).
  bool _canSave() {
    return _titleController.text.trim().isNotEmpty;
  }
}
