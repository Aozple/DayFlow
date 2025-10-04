import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CreateTaskMainContent extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController tagsController;
  final FocusNode titleFocus;
  final FocusNode descriptionFocus;
  final String selectedColor;
  final DateTime selectedDate;
  final TimeOfDay? selectedTime;
  final bool hasTime;
  final VoidCallback onChanged;
  final VoidCallback onColorTap;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;

  const CreateTaskMainContent({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.tagsController,
    required this.titleFocus,
    required this.descriptionFocus,
    required this.selectedColor,
    required this.selectedDate,
    this.selectedTime,
    required this.hasTime,
    required this.onChanged,
    required this.onColorTap,
    required this.onDateTap,
    required this.onTimeTap,
  });

  @override
  State<CreateTaskMainContent> createState() => _CreateTaskMainContentState();
}

class _CreateTaskMainContentState extends State<CreateTaskMainContent> {
  TextDirection _titleDirection = TextDirection.ltr;
  TextDirection _descriptionDirection = TextDirection.ltr;
  TextDirection _tagsDirection = TextDirection.ltr;

  bool _isTitleFocused = false;
  bool _isDescriptionFocused = false;
  final bool _isTagsFocused = false;

  @override
  void initState() {
    super.initState();
    _setupTextListeners();
    _setupFocusListeners();
    _detectTextDirections();
  }

  @override
  void dispose() {
    _removeTextListeners();
    super.dispose();
  }

  void _setupTextListeners() {
    widget.titleController.addListener(_onTitleChanged);
    widget.descriptionController.addListener(_onDescriptionChanged);
    widget.tagsController.addListener(_onTagsChanged);
  }

  void _setupFocusListeners() {
    widget.titleFocus.addListener(() {
      setState(() => _isTitleFocused = widget.titleFocus.hasFocus);
    });

    widget.descriptionFocus.addListener(() {
      setState(() => _isDescriptionFocused = widget.descriptionFocus.hasFocus);
    });
  }

  void _removeTextListeners() {
    widget.titleController.removeListener(_onTitleChanged);
    widget.descriptionController.removeListener(_onDescriptionChanged);
    widget.tagsController.removeListener(_onTagsChanged);
  }

  void _onTitleChanged() {
    _updateTextDirection(
      widget.titleController.text,
      field: _TextFieldType.title,
    );
    widget.onChanged();
  }

  void _onDescriptionChanged() {
    _updateTextDirection(
      widget.descriptionController.text,
      field: _TextFieldType.description,
    );
    widget.onChanged();
  }

  void _onTagsChanged() {
    _updateTextDirection(
      widget.tagsController.text,
      field: _TextFieldType.tags,
    );
    widget.onChanged();
  }

  void _detectTextDirections() {
    _updateTextDirection(
      widget.titleController.text,
      field: _TextFieldType.title,
    );
    _updateTextDirection(
      widget.descriptionController.text,
      field: _TextFieldType.description,
    );
    _updateTextDirection(
      widget.tagsController.text,
      field: _TextFieldType.tags,
    );
  }

  void _updateTextDirection(String text, {required _TextFieldType field}) {
    if (text.isEmpty) return;

    final isRTL = _isRTLText(text);
    final newDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    switch (field) {
      case _TextFieldType.title:
        if (_titleDirection != newDirection) {
          setState(() => _titleDirection = newDirection);
        }
        break;
      case _TextFieldType.description:
        if (_descriptionDirection != newDirection) {
          setState(() => _descriptionDirection = newDirection);
        }
        break;
      case _TextFieldType.tags:
        if (_tagsDirection != newDirection) {
          setState(() => _tagsDirection = newDirection);
        }
        break;
    }
  }

  bool _isRTLText(String text) {
    final firstChar = text.trim().runes.first;
    return (firstChar >= 0x0600 && firstChar <= 0x06FF) ||
        (firstChar >= 0x0750 && firstChar <= 0x077F) ||
        (firstChar >= 0xFB50 && firstChar <= 0xFDFF) ||
        (firstChar >= 0xFE70 && firstChar <= 0xFEFF) ||
        (firstChar >= 0x0590 && firstChar <= 0x05FF);
  }

  Color get _selectedColor => AppColors.fromHex(widget.selectedColor);

  String get _titlePlaceholder =>
      _titleDirection == TextDirection.rtl ? 'عنوان تسک...' : 'Task title *';

  String get _descriptionPlaceholder =>
      _descriptionDirection == TextDirection.rtl
          ? 'توضیحات (اختیاری)...'
          : 'Add description (optional)';

  String get _tagsPlaceholder =>
      _tagsDirection == TextDirection.rtl
          ? 'برچسب (با کاما جدا کنید)...'
          : 'Add tags (comma separated)...';

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    if (_isSameDay(date, today)) return 'Today';
    if (_isSameDay(date, tomorrow)) return 'Tomorrow';
    if (_isSameDay(date, yesterday)) return 'Yesterday';

    return '${date.day}/${date.month}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.surface.withAlpha(250)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color:
              _isTitleFocused
                  ? _selectedColor.withAlpha(60)
                  : AppColors.divider.withAlpha(30),
          width: _isTitleFocused ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        children: [
          _buildTitleSection(),
          _buildDivider(),
          _buildDescriptionSection(),
          _buildDivider(),
          _buildTagsSection(),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildColorIndicator(),
          _buildTitleField(),
          _buildDateButton(),
          _buildTimeButton(),
        ],
      ),
    );
  }

  Widget _buildColorIndicator() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onColorTap();
      },
      child: Container(
        margin: const EdgeInsets.only(left: 8, right: 12),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_selectedColor, _selectedColor.withAlpha(220)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _selectedColor.withAlpha(40),
              blurRadius: 8,
              offset: const Offset(0, 3),
              spreadRadius: 0,
            ),
          ],
        ),
        child: const Icon(
          CupertinoIcons.paintbrush_fill,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextField(
          controller: widget.titleController,
          focusNode: widget.titleFocus,
          textDirection: _titleDirection,
          textAlign:
              _titleDirection == TextDirection.rtl
                  ? TextAlign.right
                  : TextAlign.left,
          maxLines: 1,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            height: 1.3,
          ),
          decoration: InputDecoration(
            hintText: _titlePlaceholder,
            hintStyle: TextStyle(
              color: AppColors.textTertiary.withAlpha(150),
              fontWeight: FontWeight.w500,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
        ),
      ),
    );
  }

  Widget _buildDateButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(48, 48),
      onPressed: () {
        HapticFeedback.lightImpact();
        widget.onDateTap();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withAlpha(25),
              Theme.of(context).colorScheme.primary.withAlpha(15),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(60), width: 1),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withAlpha(25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.calendar, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 3),
            Text(
              _formatDate(widget.selectedDate),
              style: TextStyle(
                fontSize: 9,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeButton() {
    final isActive = widget.hasTime;
    const activeColor = AppColors.info;
    const inactiveColor = AppColors.textSecondary;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(48, 48),
      onPressed: () {
        HapticFeedback.lightImpact();
        widget.onTimeTap();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isActive
                    ? [activeColor.withAlpha(25), activeColor.withAlpha(15)]
                    : [AppColors.surface, AppColors.surface.withAlpha(200)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isActive
                    ? activeColor.withAlpha(60)
                    : AppColors.divider.withAlpha(60),
            width: 1,
          ),
          boxShadow:
              isActive
                  ? [
                    BoxShadow(
                      color: activeColor.withAlpha(25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.clock,
              size: 18,
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 3),
            Text(
              widget.hasTime && widget.selectedTime != null
                  ? _formatTime(widget.selectedTime!)
                  : '--:--',
              style: TextStyle(
                fontSize: 9,
                color: isActive ? activeColor : inactiveColor,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: _isDescriptionFocused ? 16 : 12,
      ),
      decoration: BoxDecoration(
        color:
            _isDescriptionFocused
                ? _selectedColor.withAlpha(8)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4, right: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              CupertinoIcons.doc_text,
              color:
                  _isDescriptionFocused
                      ? _selectedColor
                      : AppColors.textSecondary,
              size: 16,
            ),
          ),
          Expanded(
            child: TextField(
              controller: widget.descriptionController,
              focusNode: widget.descriptionFocus,
              textDirection: _descriptionDirection,
              textAlign:
                  _descriptionDirection == TextDirection.rtl
                      ? TextAlign.right
                      : TextAlign.left,
              maxLines: 4,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText: _descriptionPlaceholder,
                hintStyle: TextStyle(
                  color: AppColors.textTertiary.withAlpha(120),
                  fontSize: 15,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              CupertinoIcons.tag,
              color: _isTagsFocused ? _selectedColor : AppColors.textSecondary,
              size: 16,
            ),
          ),
          Expanded(
            child: TextField(
              controller: widget.tagsController,
              textDirection: _tagsDirection,
              textAlign:
                  _tagsDirection == TextDirection.rtl
                      ? TextAlign.right
                      : TextAlign.left,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
              decoration: InputDecoration(
                hintText: _tagsPlaceholder,
                hintStyle: TextStyle(
                  color: AppColors.textTertiary.withAlpha(120),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.divider.withAlpha(25),
            AppColors.divider.withAlpha(100),
            AppColors.divider.withAlpha(25),
          ],
        ),
      ),
    );
  }
}

enum _TextFieldType { title, description, tags }
