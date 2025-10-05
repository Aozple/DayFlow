import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/core/utils/color_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CreateNoteTitleSection extends StatefulWidget {
  final TextEditingController titleController;
  final FocusNode titleFocus;
  final String selectedColor;
  final TimeOfDay selectedTime;
  final DateTime? prefilledDate;
  final DateTime selectedDate;
  final VoidCallback onColorTap;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;
  final TextEditingController tagsController;

  const CreateNoteTitleSection({
    super.key,
    required this.titleController,
    required this.titleFocus,
    required this.selectedColor,
    required this.selectedTime,
    required this.prefilledDate,
    required this.selectedDate,
    required this.onColorTap,
    required this.onDateTap,
    required this.onTimeTap,
    required this.tagsController,
  });

  @override
  State<CreateNoteTitleSection> createState() => _CreateNoteTitleSectionState();
}

class _CreateNoteTitleSectionState extends State<CreateNoteTitleSection> {
  TextDirection _titleDirection = TextDirection.ltr;
  TextDirection _tagsDirection = TextDirection.ltr;

  bool _isTitleFocused = false;
  final bool _isTagsFocused = false;

  @override
  void initState() {
    super.initState();
    _setupListeners();
    _setupFocusListeners();
    _updateTextDirections();
  }

  @override
  void dispose() {
    _removeListeners();
    super.dispose();
  }

  void _setupListeners() {
    widget.titleController.addListener(_onTitleTextChange);
    widget.tagsController.addListener(_onTagsTextChange);
  }

  void _setupFocusListeners() {
    widget.titleFocus.addListener(() {
      setState(() => _isTitleFocused = widget.titleFocus.hasFocus);
    });
  }

  void _removeListeners() {
    widget.titleController.removeListener(_onTitleTextChange);
    widget.tagsController.removeListener(_onTagsTextChange);
  }

  void _onTitleTextChange() {
    _updateTextDirection(widget.titleController.text, isTitle: true);
  }

  void _onTagsTextChange() {
    _updateTextDirection(widget.tagsController.text, isTitle: false);
  }

  void _updateTextDirections() {
    _updateTextDirection(widget.titleController.text, isTitle: true);
    _updateTextDirection(widget.tagsController.text, isTitle: false);
  }

  void _updateTextDirection(String text, {required bool isTitle}) {
    if (text.isEmpty) return;

    final firstChar = text.trim().runes.first;
    final isRTL = _isRTLCharacter(firstChar);
    final newDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    if (isTitle && _titleDirection != newDirection) {
      setState(() => _titleDirection = newDirection);
    } else if (!isTitle && _tagsDirection != newDirection) {
      setState(() => _tagsDirection = newDirection);
    }
  }

  bool _isRTLCharacter(int char) {
    return (char >= 0x0600 && char <= 0x06FF) ||
        (char >= 0x0750 && char <= 0x077F) ||
        (char >= 0xFB50 && char <= 0xFDFF) ||
        (char >= 0xFE70 && char <= 0xFEFF) ||
        (char >= 0x0590 && char <= 0x05FF);
  }

  Color get _selectedColor => ColorUtils.fromHex(widget.selectedColor);

  String get _titlePlaceholder =>
      _titleDirection == TextDirection.rtl
          ? 'عنوان یادداشت...'
          : 'Note title...';

  String get _tagsPlaceholder =>
      _tagsDirection == TextDirection.rtl
          ? 'برچسب (با کاما جدا کنید)...'
          : 'Add tags (comma separated)...';

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
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
        children: [_buildTitleSection(), _buildDivider(), _buildTagsSection()],
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
          _buildDateTimeButtons(),
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
          CupertinoIcons.doc_text_fill,
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

  Widget _buildDateTimeButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [_buildDateButton(), _buildTimeButton()],
    );
  }

  Widget _buildDateButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(44, 44),
      onPressed: () {
        HapticFeedback.lightImpact();
        widget.onDateTap();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        width: 44,
        height: 44,
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
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withAlpha(60),
            width: 1,
          ),
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
            Icon(
              CupertinoIcons.calendar,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
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
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(44, 44),
      onPressed: () {
        HapticFeedback.lightImpact();
        widget.onTimeTap();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.info.withAlpha(25),
              AppColors.info.withAlpha(15),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.info.withAlpha(60), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.info.withAlpha(25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.clock, size: 16, color: AppColors.info),
            const SizedBox(height: 3),
            Text(
              _formatTime(widget.selectedTime),
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.info,
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ),
          ],
        ),
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
