import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/custom_snackbar.dart';
import '../../../data/models/task_model.dart';

// This screen is for creating a new note or editing an existing one.
// It supports Markdown for rich text editing and a preview mode.
class CreateNoteScreen extends StatefulWidget {
  // The note object to edit. If null, we're creating a new note.
  final TaskModel? noteToEdit;
  // Optional pre-filled hour for convenience, e.g., from a calendar view.
  final int? prefilledHour;
  // Optional pre-filled date for convenience.
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

// The state class for our CreateNoteScreen, managing all its dynamic behavior.
class _CreateNoteScreenState extends State<CreateNoteScreen>
    with TickerProviderStateMixin {
  // Text controllers for the note's title, content, and tags.
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagsController;

  // Animation controllers for the preview and markdown toolbar.
  late AnimationController _previewAnimationController;
  late AnimationController _toolbarAnimationController;
  late Animation<double> _toolbarAnimation;

  // State variables for the note's properties and UI mode.
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isPreviewMode = false; // True if in preview mode, false for editor.
  String _selectedColor = AppColors.toHex(
    AppColors.userColors[6],
  ); // Default note color (purple).
  bool _hasChanges = false; // Tracks if there are unsaved changes.
  final bool _autoSaveEnabled = true; // Flag for auto-save functionality.

  // Focus nodes to manage keyboard focus on text fields.
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _contentFocus = FocusNode();

  // Scroll controller for the content editor.
  final ScrollController _scrollController = ScrollController();

  // A getter to easily check if we are in edit mode.
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

  // Marks that content has changed, triggering UI updates like auto-save status.
  void _onContentChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  // Shows a confirmation dialog before deleting a note.
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

  // Deletes the current note by dispatching a DeleteTask event to the TaskBloc.
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
              _buildHeader(),

              // The main content area, which can switch between editor and preview.
              Expanded(
                child: Stack(
                  children: [
                    // Column containing the title, toolbar, and editor/preview.
                    Column(
                      children: [
                        // Section for the note title and metadata.
                        _buildTitleSection(),

                        // Markdown toolbar, animated to show/hide.
                        AnimatedBuilder(
                          animation: _toolbarAnimation,
                          builder: (context, child) {
                            return SizeTransition(
                              sizeFactor: _toolbarAnimation, // Animates height.
                              child:
                                  _isPreviewMode
                                      ? const SizedBox.shrink() // Hide toolbar in preview mode.
                                      : _buildMarkdownToolbar(), // Show toolbar in editor mode.
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
                                  begin: const Offset(1.0, 0.0), // Starts off-screen to the right.
                                  end: Offset.zero, // Slides to its final position.
                                ).animate(animation),
                                child: child,
                              );
                            },
                            child:
                                _isPreviewMode
                                    ? _buildPreview() // Show markdown preview.
                                    : _buildEditor(), // Show markdown editor.
                          ),
                        ),
                      ],
                    ),

                    // Floating word count, visible only in editor mode with content.
                    if (!_isPreviewMode && _contentController.text.isNotEmpty)
                      _buildWordCount(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Builds the header bar with "Cancel", "New Note/Edit Note" title, and action buttons.
  Widget _buildHeader() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Apply a blur effect.
        child: Container(
          color: AppColors.surface.withAlpha(200), // Semi-transparent background.
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Cancel button, shows discard dialog if there are changes.
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  if (_hasChanges) {
                    _showDiscardDialog();
                  } else {
                    context.pop(); // Just pop if no changes.
                  }
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color:
                        _hasChanges ? AppColors.error : AppColors.textSecondary, // Red if changes, gray otherwise.
                    fontSize: 17,
                  ),
                ),
              ),

              // Title of the screen and auto-save status.
              Column(
                children: [
                  Text(
                    isEditMode ? 'Edit Note' : 'New Note', // Title changes based on mode.
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  // Show "Auto-saving..." text if changes exist and auto-save is enabled.
                  if (_hasChanges && _autoSaveEnabled)
                    Text(
                      'Auto-saving...',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.accent.withAlpha(200),
                      ),
                    ),
                ],
              ),

              // Action buttons (Preview, Delete, Save).
              Row(
                children: [
                  // Preview/Editor toggle button.
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 32,
                    onPressed: _togglePreview, // Toggles between editor and preview.
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color:
                            _isPreviewMode
                                ? AppColors.accent.withAlpha(30) // Highlight if in preview mode.
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _isPreviewMode
                            ? CupertinoIcons.pencil // Show pencil icon in preview mode.
                            : CupertinoIcons.eye, // Show eye icon in editor mode.
                        color:
                            _isPreviewMode
                                ? AppColors.accent
                                : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Delete button, only visible in edit mode.
                  if (isEditMode) ...[
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 32,
                      onPressed: _showDeleteConfirmation, // Show delete confirmation dialog.
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.error.withAlpha(20), // Red background for destructive action.
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          CupertinoIcons.trash, // Trash icon.
                          color: AppColors.error,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  const SizedBox(width: 8),

                  // Save/Update button, disabled if title is empty.
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _canSave() ? _saveNote : null, // Call save function if title is not empty.
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _canSave()
                                ? AppColors.accent // Accent color if savable.
                                : AppColors.surfaceLight, // Lighter surface if disabled.
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isEditMode ? 'Update' : 'Save', // Text changes based on mode.
                        style: TextStyle(
                          color:
                              _canSave()
                                  ? Colors.white // White text if savable.
                                  : AppColors.textTertiary, // Tertiary text if disabled.
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Builds the section containing the note title input, color picker, date/time, and tags.
  Widget _buildTitleSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface, // Background color for this section.
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Row for color indicator, title field, and date/time button.
          Row(
            children: [
              // Circular color indicator, tappable to open color picker.
              GestureDetector(
                onTap: _showColorPicker, // Opens the color selection modal.
                child: Container(
                  margin: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.fromHex(_selectedColor), // Display selected color.
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.divider, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.fromHex(_selectedColor).withAlpha(50), // Subtle shadow.
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.doc_text_fill, // Note icon inside the circle.
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),

              // Expanded text field for the note title.
              Expanded(
                child: TextField(
                  controller: _titleController,
                  focusNode: _titleFocus,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Note title...', // Placeholder text.
                    hintStyle: TextStyle(color: AppColors.textTertiary),
                    border: InputBorder.none, // No border for the input field.
                    contentPadding: EdgeInsets.all(16),
                  ),
                  textCapitalization: TextCapitalization.sentences, // Capitalize first letter of sentences.
                ),
              ),

              // Button to select date and time for the note.
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 32,
                onPressed: _selectDateTime, // Opens the date/time picker.
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(20), // Subtle accent background.
                    borderRadius: BorderRadius.circular(8),
                    // Add a border if the date was prefilled.
                    border:
                        widget.prefilledDate != null
                            ? Border.all(
                              color: AppColors.accent.withAlpha(50),
                              width: 1,
                            )
                            : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.clock, // Clock icon.
                        size: 16,
                        color: AppColors.accent,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedTime.format(context), // Display selected time.
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.accent,
                          fontWeight:
                              widget.prefilledDate != null
                                  ? FontWeight.w700 // Bolder if prefilled.
                                  : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Divider below the title/date section.
          Container(
            height: 0.5,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: AppColors.divider,
          ),

          // Text field for adding tags to the note.
          TextField(
            controller: _tagsController,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Add tags (comma separated)...', // Placeholder text.
              hintStyle: TextStyle(color: AppColors.textTertiary),
              prefixIcon: Icon(
                CupertinoIcons.tag, // Tag icon.
                color: AppColors.textSecondary,
                size: 18,
              ),
              border: InputBorder.none, // No border.
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  // Builds the horizontal toolbar for Markdown formatting options.
  Widget _buildMarkdownToolbar() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight, // Lighter surface background.
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withAlpha(50), width: 1), // Subtle border.
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // Allows horizontal scrolling for more buttons.
        physics: const BouncingScrollPhysics(), // iOS-style scroll physics.
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            // Buttons for common Markdown formatting.
            _toolbarButton(
              icon: CupertinoIcons.bold,
              onTap: () => _insertMarkdown('**', '**'), // Inserts bold markdown.
              tooltip: 'Bold',
            ),
            _toolbarButton(
              icon: CupertinoIcons.italic,
              onTap: () => _insertMarkdown('*', '*'), // Inserts italic markdown.
              tooltip: 'Italic',
            ),
            _toolbarDivider(), // A visual separator.
            _toolbarButton(
              icon: Icons.title,
              onTap: () => _insertMarkdown('# ', ''), // Inserts heading markdown.
              tooltip: 'Heading',
            ),
            _toolbarButton(
              icon: CupertinoIcons.list_bullet,
              onTap: () => _insertMarkdown('- ', ''), // Inserts bullet list markdown.
              tooltip: 'Bullet List',
            ),
            _toolbarButton(
              icon: CupertinoIcons.list_number,
              onTap: () => _insertMarkdown('1. ', ''), // Inserts numbered list markdown.
              tooltip: 'Numbered List',
            ),
            _toolbarDivider(),
            _toolbarButton(
              icon: CupertinoIcons.checkmark_square,
              onTap: () => _insertMarkdown('- [ ] ', ''), // Inserts checkbox markdown.
              tooltip: 'Checkbox',
            ),
            _toolbarButton(
              icon: CupertinoIcons.quote_bubble,
              onTap: () => _insertMarkdown('> ', ''), // Inserts quote markdown.
              tooltip: 'Quote',
            ),
            _toolbarDivider(),
            _toolbarButton(
              icon: CupertinoIcons.link,
              onTap: () => _insertMarkdown('[Link](', ')'), // Inserts link markdown.
              tooltip: 'Link',
            ),
            _toolbarButton(
              icon: CupertinoIcons.photo,
              onTap: () => _insertMarkdown('![Image](', ')'), // Inserts image markdown.
              tooltip: 'Image',
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for creating a single toolbar button.
  Widget _toolbarButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip, // Shows a tooltip on long press/hover.
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minSize: 34,
        onPressed: () {
          HapticFeedback.lightImpact(); // Provide haptic feedback on tap.
          onTap(); // Execute the button's action.
        },
        child: Icon(icon, size: 18, color: AppColors.textPrimary), // Icon with primary text color.
      ),
    );
  }

  // Helper widget for creating a vertical divider in the toolbar.
  Widget _toolbarDivider() {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppColors.divider, // Divider color.
    );
  }

  // Builds the Markdown editor text field.
  Widget _buildEditor() {
    return Container(
      key: const ValueKey('editor'), // Unique key for AnimatedSwitcher.
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface, // Background color.
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Editor header with icon, label, and optional word count.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.divider, width: 0.5), // Bottom border.
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.pencil_circle, // Pencil icon.
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Markdown Editor',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                // Display word count if content is not empty.
                if (_contentController.text.isNotEmpty)
                  Text(
                    '${_getWordCount()} words',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),

          // The main text field for Markdown content.
          Expanded(
            child: TextField(
              controller: _contentController,
              focusNode: _contentFocus,
              maxLines: null, // Allows unlimited lines.
              expands: true, // Makes the text field expand to fill available height.
              textAlignVertical: TextAlignVertical.top, // Align text to the top.
              style: const TextStyle(
                fontSize: 16,
                height: 1.6, // Line height for readability.
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: _getEditorHint(), // Provides helpful Markdown syntax hints.
                hintStyle: const TextStyle(
                  color: AppColors.textTertiary,
                  height: 1.6,
                ),
                border: InputBorder.none, // No border.
                contentPadding: const EdgeInsets.all(16),
              ),
              scrollController: _scrollController, // Link to our scroll controller.
            ),
          ),
        ],
      ),
    );
  }

  // Builds the Markdown preview display.
  Widget _buildPreview() {
    return Container(
      key: const ValueKey('preview'), // Unique key for AnimatedSwitcher.
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface, // Background color.
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Preview header with icon, label, and date.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.divider, width: 0.5), // Bottom border.
              ),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.eye_fill, // Eye icon.
                  size: 16,
                  color: AppColors.accent, // Accent color.
                ),
                const SizedBox(width: 8),
                Text(
                  'Preview',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.accent,
                  ),
                ),
                const Spacer(),
                // Display the selected date.
                Text(
                  DateFormat('MMM d, yyyy').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          // The area displaying the rendered Markdown content.
          Expanded(
            child:
                _contentController.text.trim().isEmpty
                    ? const Center(
                      // Show a placeholder if the content is empty.
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.doc_text, // Document icon.
                            size: 48,
                            color: AppColors.textTertiary,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Start writing to see preview',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    )
                    : Markdown(
                      data: _contentController.text, // The Markdown text to render.
                      selectable: true, // Allow text selection.
                      physics: const BouncingScrollPhysics(), // iOS-style scroll physics.
                      padding: const EdgeInsets.all(16),
                      styleSheet: _buildMarkdownStyle(), // Custom styles for Markdown elements.
                    ),
          ),
        ],
      ),
    );
  }

  // Builds a floating widget to display word and character counts.
  Widget _buildWordCount() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: AnimatedOpacity(
        opacity: _contentController.text.isNotEmpty ? 1.0 : 0.0, // Fade in/out based on content.
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface.withAlpha(200), // Semi-transparent background.
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.divider.withAlpha(100),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.background.withAlpha(100), // Subtle shadow.
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            '${_getWordCount()} words • ${_getCharCount()} chars', // Display counts.
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to provide a hint text for the Markdown editor.
  String _getEditorHint() {
    return '''Start writing your note...

You can use Markdown syntax:
# Heading
**Bold** *Italic*
- Lists
- [ ] Checkboxes
> Quotes

[Links](url) and more!''';
  }

  // Defines the styling for various Markdown elements.
  MarkdownStyleSheet _buildMarkdownStyle() {
    return MarkdownStyleSheet(
      h1: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        height: 1.3,
      ),
      h2: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        height: 1.3,
      ),
      h3: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      ),
      p: const TextStyle(
        fontSize: 16,
        height: 1.6,
        color: AppColors.textPrimary,
      ),
      code: TextStyle(
        backgroundColor: AppColors.surfaceLight,
        fontFamily: 'monospace',
        fontSize: 14,
        color: AppColors.accent,
      ),
      codeblockDecoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider.withAlpha(50), width: 1),
      ),
      blockquote: const TextStyle(
        color: AppColors.textSecondary,
        fontStyle: FontStyle.italic,
        fontSize: 16,
      ),
      blockquoteDecoration: BoxDecoration(
        color: AppColors.accent.withAlpha(10),
        border: Border(left: BorderSide(color: AppColors.accent, width: 4)),
      ),
      listBullet: TextStyle(color: AppColors.accent),
      checkbox: TextStyle(color: AppColors.accent),
      a: TextStyle(
        color: AppColors.accent,
        decoration: TextDecoration.underline,
      ),
      strong: const TextStyle(
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      em: const TextStyle(
        fontStyle: FontStyle.italic,
        color: AppColors.textPrimary,
      ),
    );
  }

  // Calculates the number of words in the content.
  int _getWordCount() {
    return _contentController.text
        .trim()
        .split(RegExp(r'\s+')) // Split by one or more whitespace characters.
        .where((word) => word.isNotEmpty) // Filter out empty strings.
        .length;
  }

  // Calculates the number of characters in the content.
  int _getCharCount() {
    return _contentController.text.length;
  }

  // Checks if the note can be saved (i.e., if the title is not empty).
  bool _canSave() {
    return _titleController.text.trim().isNotEmpty;
  }

  // Toggles between Markdown editor and preview modes.
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

  // Inserts Markdown syntax (e.g., bold, italic) around the current text selection.
  void _insertMarkdown(String before, String after) {
    final selection = _contentController.selection; // Current text selection.
    final text = _contentController.text; // Full text in the editor.
    final selectedText = selection.textInside(text); // The text currently selected.

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
      selection: TextSelection.collapsed(offset: newCursorPos), // Place cursor after inserted text.
    );

    _contentFocus.requestFocus(); // Keep focus on the content editor.
  }

  // Shows a Cupertino-style modal for selecting the note's date and time.
  void _selectDateTime() async {
    await showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            height: 300,
            decoration: const BoxDecoration(
              color: AppColors.surface, // Background color.
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)), // Rounded top corners.
            ),
            child: Column(
              children: [
                // Header for the date/time picker modal.
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.divider, width: 0.5), // Bottom divider.
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context), // Cancel button.
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      const Text(
                        'Select Date & Time', // Title.
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context), // Done button.
                        child: Text(
                          'Done',
                          style: TextStyle(color: AppColors.accent),
                        ),
                      ),
                    ],
                  ),
                ),

                // The Cupertino date and time picker itself.
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.dateAndTime, // Allow both date and time selection.
                    initialDateTime: DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      _selectedTime.hour,
                      _selectedTime.minute,
                    ),
                    onDateTimeChanged: (date) {
                      setState(() {
                        _selectedDate = date; // Update selected date.
                        _selectedTime = TimeOfDay.fromDateTime(date); // Update selected time.
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  // Shows a Cupertino-style modal for picking the note's color.
  void _showColorPicker() {
    String selectedColorHex = _selectedColor; // Temporarily hold the selected color in the modal.

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 300,
              decoration: const BoxDecoration(
                color: AppColors.surface, // Background color.
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)), // Rounded top corners.
              ),
              child: Column(
                children: [
                  // Drag handle for the modal.
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
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(modalContext), // Cancel button.
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                        const Text(
                          'Note Color', // Title.
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            setState(() => _selectedColor = selectedColorHex); // Apply selected color to main state.
                            Navigator.pop(modalContext); // Close modal.
                            CustomSnackBar.success(context, 'Color updated'); // Show success message.
                          },
                          child: Text(
                            'Done',
                            style: TextStyle(color: AppColors.accent),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Grid view for displaying selectable color options.
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(), // iOS-style scroll physics.
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4, // 4 columns of colors.
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: AppColors.userColors.length, // Number of available colors.
                        itemBuilder: (context, index) {
                          final color = AppColors.userColors[index];
                          final colorHex = AppColors.toHex(color);
                          final isSelected = selectedColorHex == colorHex; // Check if this color is selected.

                          return GestureDetector(
                            onTap: () {
                              setModalState(() => selectedColorHex = colorHex); // Update selected color in modal state.
                              HapticFeedback.lightImpact(); // Provide haptic feedback.
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200), // Smooth animation for selection.
                              decoration: BoxDecoration(
                                color: color, // The actual color.
                                shape: BoxShape.circle, // Circular shape.
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? Colors.white // White border if selected.
                                          : AppColors.divider.withAlpha(50), // Subtle border if not selected.
                                  width: isSelected ? 3 : 1, // Thicker border if selected.
                                ),
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
                              ),
                              child:
                                  isSelected
                                      ? const Icon(
                                        CupertinoIcons.checkmark, // Checkmark if selected.
                                        color: Colors.white,
                                        size: 20,
                                      )
                                      : null, // No child if not selected.
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).padding.bottom), // Space for safe area.
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Shows a confirmation dialog when the user tries to leave with unsaved changes.
  void _showDiscardDialog() {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Discard Changes?'),
            content: const Text(
              'You have unsaved changes. Are you sure you want to discard them?',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Keep Editing'),
                onPressed: () => Navigator.pop(context), // Close dialog, stay on screen.
              ),
              CupertinoDialogAction(
                isDestructiveAction: true, // Make the button red.
                onPressed: () {
                  Navigator.pop(context); // Close dialog.
                  context.pop(); // Close the current screen.
                },
                child: const Text('Discard'),
              ),
            ],
          ),
    );
  }

  // Handles saving or updating the note.
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
      CustomSnackBar.success(context, 'Note updated successfully'); // Show success message.
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
      CustomSnackBar.success(context, 'Note created successfully'); // Show success message.
    }

    _hasChanges = false; // Reset changes flag after saving.

    context.pop(); // Navigate back to the previous screen.
  }
}
