import 'package:dayflow/data/models/note_block.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
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
import 'widgets/create_note_color_picker.dart';
import 'widgets/create_note_date_time_picker.dart';
import 'widgets/create_note_discard_dialog.dart';
import 'package:uuid/uuid.dart';

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
  late TextEditingController _titleController;
  late TextEditingController _tagsController;
  late AnimationController _previewAnimationController;
  late AnimationController _toolbarAnimationController;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String _selectedColor = AppColors.toHex(AppColors.userColors[6]);
  bool _hasChanges = false;
  final bool _autoSaveEnabled = true;

  final FocusNode _titleFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // New block-based content
  late List<NoteBlock> _blocks;

  bool get isEditMode => widget.noteToEdit != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.noteToEdit?.title ?? '',
    );
    _tagsController = TextEditingController(
      text: widget.noteToEdit?.tags.join(', ') ?? '',
    );

    // Initialize blocks
    if (isEditMode && widget.noteToEdit != null) {
      // If blocks are available, use them
      _blocks =
          widget.noteToEdit!.blocks ?? widget.noteToEdit!.getLegacyBlocks();
    } else {
      // Start with an empty text block for new notes
      _blocks = [TextBlock(id: const Uuid().v4(), text: '')];
    }

    if (isEditMode && widget.noteToEdit != null) {
      _selectedDate = widget.noteToEdit!.dueDate ?? DateTime.now();
      _selectedTime = TimeOfDay.fromDateTime(
        widget.noteToEdit!.dueDate ?? DateTime.now(),
      );
      _selectedColor = widget.noteToEdit!.color;
    } else {
      _selectedDate = widget.prefilledDate ?? DateTime.now();
      if (widget.prefilledHour != null) {
        _selectedTime = TimeOfDay(hour: widget.prefilledHour!, minute: 0);
      } else {
        _selectedTime = TimeOfDay.now();
      }
      _selectedColor = AppColors.toHex(AppColors.userColors[4]);
    }

    _previewAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _toolbarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _toolbarAnimationController.forward();

    _titleController.addListener(_onContentChanged);
    _tagsController.addListener(_onContentChanged);

    if (!isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _titleFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagsController.dispose();
    _titleFocus.dispose();
    _scrollController.dispose();
    _previewAnimationController.dispose();
    _toolbarAnimationController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  void _onBlocksChanged(List<NoteBlock> blocks) {
    _blocks = blocks;
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

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

  void _deleteCurrentNote() {
    if (!isEditMode || widget.noteToEdit == null) return;

    final taskBloc = context.read<TaskBloc>();
    taskBloc.add(DeleteTask(widget.noteToEdit!.id));
    CustomSnackBar.success(context, 'Note deleted successfully');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _hasChanges) {
          _showDiscardDialog();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              CreateNoteHeader(
                isEditMode: isEditMode,
                hasChanges: _hasChanges,
                autoSaveEnabled: _autoSaveEnabled,
                isPreviewMode: false, // Always false now
                onTogglePreview: () {}, // Empty function since we don't need it
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
              Expanded(
                child: Stack(
                  children: [
                    Column(
                      children: [
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

                        // Replace the old editor with the new block editor
                        Expanded(
                          child: NoteBlockEditor(
                            initialBlocks: _blocks,
                            onBlocksChanged: _onBlocksChanged,
                          ),
                        ),
                      ],
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

  void _selectDateTime() async {
    await showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CreateNoteDateTimePicker(
            selectedDate: _selectedDate,
            selectedTime: _selectedTime,
            onDateTimeChanged: (date) {
              setState(() {
                _selectedDate = date;
                _selectedTime = TimeOfDay.fromDateTime(date);
              });
            },
          ),
    );
  }

  void _showColorPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext modalContext) {
        return CreateNoteColorPicker(
          initialColor: _selectedColor,
          onColorSelected: (colorHex) {
            setState(() => _selectedColor = colorHex);
            CustomSnackBar.success(context, 'Color updated');
          },
        );
      },
    );
  }

  void _showDiscardDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => const CreateNoteDiscardDialog(),
    );
  }

  void _saveNote() {
    if (!_canSave()) {
      CustomSnackBar.error(context, 'Please enter a note title');
      return;
    }

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
        blocks: _blocks, // Use blocks instead of markdownContent
        dueDate: dueDateTime,
        color: _selectedColor,
        tags: tags,
        isNote: true,
      );
      taskBloc.add(UpdateTask(updatedNote));
      CustomSnackBar.success(context, 'Note updated successfully');
    } else {
      final newNote = TaskModel(
        title: _titleController.text.trim(),
        blocks: _blocks, // Use blocks instead of markdownContent
        dueDate: dueDateTime,
        color: _selectedColor,
        tags: tags,
        isNote: true,
        priority: 1,
      );
      taskBloc.add(AddTask(newNote));
      CustomSnackBar.success(context, 'Note created successfully');
    }

    _hasChanges = false;
    context.pop();
  }

  bool _canSave() {
    return _titleController.text.trim().isNotEmpty;
  }
}
