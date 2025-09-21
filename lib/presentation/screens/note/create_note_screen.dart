import 'package:dayflow/data/models/note_block.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
import 'package:dayflow/presentation/screens/home/widgets/blocks/home_note_block.dart';
import 'package:dayflow/presentation/widgets/color_picker_modal.dart';
import 'package:dayflow/presentation/widgets/date_picker_modal.dart';
import 'package:dayflow/presentation/widgets/status_bar_padding.dart';
import 'package:dayflow/presentation/widgets/time_picker_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/custom_snackbar.dart';
import '../../../data/models/task_model.dart';
import 'widgets/create_note_header.dart';
import 'widgets/create_note_title_section.dart';
import 'widgets/note_block_editor.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

class CreateNoteScreen extends StatefulWidget {
  final TaskModel? noteToEdit;
  final int? prefilledHour;
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

class _CreateNoteScreenState extends State<CreateNoteScreen>
    with TickerProviderStateMixin {
  // Constants
  static const Duration _animationDuration = Duration(milliseconds: 300);
  static const Duration _autoSaveDelay = Duration(seconds: 2);
  static const Duration _toolbarAnimationDuration = Duration(milliseconds: 200);

  // Controllers
  late TextEditingController _titleController;
  late TextEditingController _tagsController;
  late AnimationController _previewAnimationController;
  late AnimationController _toolbarAnimationController;
  late Animation<Offset> _toolbarSlideAnimation;

  // Focus and Scroll
  final FocusNode _titleFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // State
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String _selectedColor = AppColors.toHex(AppColors.userColors[6]);
  bool _hasChanges = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  Timer? _autoSaveTimer;

  // Content
  late List<NoteBlock> _blocks;

  // Getters
  bool get isEditMode => widget.noteToEdit != null;
  bool get _hasTitle => _titleController.text.trim().isNotEmpty;
  bool get _hasContent => _blocks.any(_blockHasContent);
  bool get _canSave => _hasTitle;
  bool get _shouldAutoSave => _hasTitle && _hasChanges && !_isSaving;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeContent();
    _initializeAnimations();
    _setupListeners();
    _focusInitialField();
  }

  @override
  void dispose() {
    _disposeResources();
    super.dispose();
  }

  // Initialization methods
  void _initializeControllers() {
    _titleController = TextEditingController(
      text: widget.noteToEdit?.title ?? '',
    );
    _tagsController = TextEditingController(
      text: widget.noteToEdit?.tags.join(', ') ?? '',
    );
  }

  void _initializeContent() {
    if (isEditMode && widget.noteToEdit != null) {
      _blocks =
          widget.noteToEdit!.blocks ?? widget.noteToEdit!.getLegacyBlocks();
      _selectedDate = widget.noteToEdit!.dueDate ?? DateTime.now();
      _selectedTime = TimeOfDay.fromDateTime(
        widget.noteToEdit!.dueDate ?? DateTime.now(),
      );
      _selectedColor = widget.noteToEdit!.color;
    } else {
      _blocks = [TextBlock(id: const Uuid().v4(), text: '')];
      _selectedDate = widget.prefilledDate ?? DateTime.now();
      _selectedTime =
          widget.prefilledHour != null
              ? TimeOfDay(hour: widget.prefilledHour!, minute: 0)
              : TimeOfDay.now();
      _selectedColor = AppColors.toHex(AppColors.userColors[4]);
    }
  }

  void _initializeAnimations() {
    _previewAnimationController = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );

    _toolbarAnimationController = AnimationController(
      duration: _toolbarAnimationDuration,
      vsync: this,
    );

    _toolbarSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _toolbarAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _toolbarAnimationController.forward();
  }

  void _setupListeners() {
    _titleController.addListener(_onContentChanged);
    _tagsController.addListener(_onContentChanged);
  }

  void _focusInitialField() {
    if (!isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _titleFocus.requestFocus();
      });
    }
  }

  void _disposeResources() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _tagsController.dispose();
    _titleFocus.dispose();
    _scrollController.dispose();
    _previewAnimationController.dispose();
    _toolbarAnimationController.dispose();
  }

  // Content change handling
  void _onContentChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
    _scheduleAutoSave();
  }

  void _onBlocksChanged(List<NoteBlock> blocks) {
    _blocks = blocks;
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    if (!_shouldAutoSave || !isEditMode) return;

    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(_autoSaveDelay, () {
      if (_shouldAutoSave && mounted) {
        _performAutoSave();
      }
    });
  }

  Future<void> _performAutoSave() async {
    if (!_shouldAutoSave) return;

    setState(() => _isSaving = true);

    try {
      await _saveNoteInternal(showSnackBar: false);
      setState(() => _hasChanges = false);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // Content validation
  bool _blockHasContent(NoteBlock block) {
    if (block is TextBlock) {
      return block.text.trim().isNotEmpty;
    } else if (block is HeadingBlock) {
      return block.text.trim().isNotEmpty;
    } else if (block is BulletListBlock) {
      return block.items.any((item) => item.trim().isNotEmpty);
    } else if (block is NumberedListBlock) {
      return block.items.any((item) => item.trim().isNotEmpty);
    } else if (block is TodoListBlock) {
      return block.items.any((item) => item.trim().isNotEmpty);
    } else if (block is QuoteBlock) {
      return block.text.trim().isNotEmpty;
    } else if (block is CodeBlock) {
      return block.code.trim().isNotEmpty;
    } else if (block is ToggleBlock) {
      return block.title.trim().isNotEmpty ||
          block.children.any(_blockHasContent);
    } else if (block is CalloutBlock) {
      return block.text.trim().isNotEmpty;
    }
    return false;
  }

  // Navigation handling
  void _handleBackNavigation() {
    if (_hasTitle) {
      // Auto-save and exit
      _saveNote(autoExit: true);
    } else if (!_hasContent) {
      // No content, just exit
      context.pop();
    } else {
      // Has content but no title, show dialog
      _showContentWithoutTitleDialog();
    }
  }

  void _showContentWithoutTitleDialog() {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Save Note?'),
            content: const Text(
              'You have content but no title. What would you like to do?',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Continue Editing'),
                onPressed: () {
                  Navigator.pop(context);
                  _titleFocus.requestFocus();
                },
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  context.pop();
                },
                child: const Text('Exit Without Saving'),
              ),
            ],
          ),
    );
  }

  // Delete functionality
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
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  _deleteCurrentNote();
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _handleCancelNavigation() {
    if (_hasChanges && (_hasTitle || _hasContent)) {
      _showCancelConfirmDialog();
    } else {
      context.pop();
    }
  }

  void _showCancelConfirmDialog() {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Save Changes?'),
            content: const Text(
              'You have unsaved changes. What would you like to do?',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Keep Editing'),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  context.pop(); // Exit without saving
                },
                child: const Text('Discard'),
              ),
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.pop(context); // Close dialog

                  if (!_hasTitle) {
                    _titleController.text = 'Untitled Note';
                  }

                  _saveNote(autoExit: true); // Save and exit
                },
                child: const Text('Save & Exit'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteCurrentNote() async {
    if (!isEditMode || widget.noteToEdit == null) return;

    setState(() => _isDeleting = true);

    try {
      final taskBloc = context.read<TaskBloc>();
      taskBloc.add(DeleteTask(widget.noteToEdit!.id));
      CustomSnackBar.success(context, 'Note deleted successfully');
      context.pop();
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  // Save functionality
  void _saveNote({bool autoExit = false}) {
    if (!_canSave) {
      if (!autoExit) {
        CustomSnackBar.error(context, 'Please enter a note title');
      }
      return;
    }

    _saveNoteInternal(autoExit: autoExit);
  }

  Future<void> _saveNoteInternal({
    bool autoExit = false,
    bool showSnackBar = true,
  }) async {
    setState(() => _isSaving = true);

    try {
      final taskBloc = context.read<TaskBloc>();
      final tags =
          _tagsController.text
              .split(',')
              .map((tag) => tag.trim())
              .where((tag) => tag.isNotEmpty)
              .toList();

      final dueDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      if (isEditMode) {
        final updatedNote = widget.noteToEdit!.copyWith(
          title: _titleController.text.trim(),
          blocks: _blocks,
          dueDate: dueDateTime,
          color: _selectedColor,
          tags: tags,
          isNote: true,
        );
        taskBloc.add(UpdateTask(updatedNote));
        if (showSnackBar) {
          CustomSnackBar.success(context, 'Note updated successfully');
        }
      } else {
        final newNote = TaskModel(
          title: _titleController.text.trim(),
          blocks: _blocks,
          dueDate: dueDateTime,
          color: _selectedColor,
          tags: tags,
          isNote: true,
          priority: 1,
        );
        taskBloc.add(AddTask(newNote));
        if (showSnackBar) {
          CustomSnackBar.success(context, 'Note created successfully');
        }
      }

      _hasChanges = false;
      if (autoExit) {
        context.pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // UI Event handlers
  Future<void> _selectDate() async {
    final selectedDate = await DatePickerModal.show(
      context: context,
      selectedDate: _selectedDate,
      title: 'Select Date',
      minDate: DateTime.now().subtract(const Duration(days: 365)),
      maxDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      setState(() => _selectedDate = selectedDate);
      _onContentChanged();
    }
  }

  Future<void> _selectTime() async {
    final selectedTime = await TimePickerModal.show(
      context: context,
      selectedTime: _selectedTime,
      title: 'Select Time',
    );

    if (selectedTime != null) {
      setState(() => _selectedTime = selectedTime);
      _onContentChanged();
    }
  }

  Future<void> _showColorPicker() async {
    final selectedColor = await ColorPickerModal.show(
      context: context,
      selectedColor: _selectedColor,
      title: 'Choose Note Color',
      showPreview: true,
      previewBuilder: _buildColorPreview,
    );

    if (selectedColor != null && mounted) {
      // mounted check اضافه شد
      setState(() => _selectedColor = selectedColor);
      _onContentChanged();
      if (mounted) {
        // mounted check دوباره
        CustomSnackBar.success(context, 'Color updated');
      }
    }
  }

  Widget _buildColorPreview(String colorHex) {
    // Create a sample note for preview
    final previewNote = TaskModel(
      title:
          _titleController.text.isNotEmpty
              ? _titleController.text
              : 'Sample Note Title',
      color: colorHex,
      tags:
          _tagsController.text.isNotEmpty
              ? _tagsController.text
                  .split(',')
                  .map((tag) => tag.trim())
                  .where((tag) => tag.isNotEmpty)
                  .toList()
              : ['Sample', 'Preview'],
      isNote: true,
      priority: 1,
      dueDate: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      ),
      // Create sample markdown content from blocks
      markdownContent:
          _blocks.isNotEmpty && _blocks.any(_blockHasContent)
              ? _getSampleMarkdownFromBlocks()
              : 'This is a sample note content to show how your note will look with the selected color.',
    );

    return HomeNoteBlock(
      note: previewNote,
      onOptions: (_) {}, // Empty callback for preview
    );
  }

  String _getSampleMarkdownFromBlocks() {
    final contentBlocks = _blocks.where(_blockHasContent).take(2);
    if (contentBlocks.isEmpty) {
      return 'This is a sample note content preview.';
    }

    String content = '';
    for (final block in contentBlocks) {
      if (block is TextBlock && block.text.trim().isNotEmpty) {
        content += '${block.text.trim()} ';
      } else if (block is HeadingBlock && block.text.trim().isNotEmpty) {
        content += '${block.text.trim()} ';
      }
      // Add other block types as needed
    }

    return content.trim().isNotEmpty
        ? content.trim()
        : 'This is a sample note content preview.';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackNavigation();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            const StatusBarPadding(),

            // Animated header
            SlideTransition(
              position: _toolbarSlideAnimation,
              child: CreateNoteHeader(
                isEditMode: isEditMode,
                hasChanges: _hasChanges,
                autoSaveEnabled: true,
                isSaving: _isSaving,
                isDeleting: _isDeleting,
                onDelete: _showDeleteConfirmation,
                onSave: () => _saveNote(autoExit: true),
                onCancel: _handleCancelNavigation,
              ),
            ),

            // Main content
            Expanded(
              child: Column(
                children: [
                  // Title and metadata section
                  CreateNoteTitleSection(
                    titleController: _titleController,
                    titleFocus: _titleFocus,
                    selectedColor: _selectedColor,
                    selectedTime: _selectedTime,
                    prefilledDate: widget.prefilledDate,
                    selectedDate: _selectedDate,
                    onColorTap: _showColorPicker,
                    onDateTap: _selectDate,
                    onTimeTap: _selectTime,
                    tagsController: _tagsController,
                  ),

                  // Block editor
                  Expanded(
                    child: NoteBlockEditor(
                      initialBlocks: _blocks,
                      onBlocksChanged: _onBlocksChanged,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
