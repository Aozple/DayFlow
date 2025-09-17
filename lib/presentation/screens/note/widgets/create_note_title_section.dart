import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CreateNoteTitleSection extends StatefulWidget {
  final TextEditingController titleController;
  final FocusNode titleFocus;
  final String selectedColor;
  final TimeOfDay selectedTime;
  final DateTime? prefilledDate;
  final VoidCallback onColorTap;
  final VoidCallback onDateTimeTap;
  final TextEditingController tagsController;

  const CreateNoteTitleSection({
    super.key,
    required this.titleController,
    required this.titleFocus,
    required this.selectedColor,
    required this.selectedTime,
    required this.prefilledDate,
    required this.onColorTap,
    required this.onDateTimeTap,
    required this.tagsController,
  });

  @override
  State<CreateNoteTitleSection> createState() => _CreateNoteTitleSectionState();
}

class _CreateNoteTitleSectionState extends State<CreateNoteTitleSection>
    with SingleTickerProviderStateMixin {
  // Animation controller
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // State
  TextDirection _titleDirection = TextDirection.ltr;
  TextDirection _tagsDirection = TextDirection.ltr;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupListeners();
    _updateTextDirections();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _removeListeners();
    super.dispose();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  void _setupListeners() {
    widget.titleController.addListener(_onTitleTextChange);
    widget.tagsController.addListener(_onTagsTextChange);
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
    return (char >= 0x0600 && char <= 0x06FF) || // Arabic
        (char >= 0x0750 && char <= 0x077F) || // Arabic Supplement
        (char >= 0xFB50 && char <= 0xFDFF) || // Arabic Presentation Forms A
        (char >= 0xFE70 && char <= 0xFEFF) || // Arabic Presentation Forms B
        (char >= 0x0590 && char <= 0x05FF); // Hebrew
  }

  Color get _selectedColor => AppColors.fromHex(widget.selectedColor);

  String get _titlePlaceholder =>
      _titleDirection == TextDirection.rtl
          ? 'عنوان یادداشت...'
          : 'Note title...';

  String get _tagsPlaceholder =>
      _tagsDirection == TextDirection.rtl
          ? 'برچسب (با کاما جدا کنید)...'
          : 'Add tags (comma separated)...';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [_buildTitleRow(), _buildDivider(), _buildTagsField()],
      ),
    );
  }

  Widget _buildTitleRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildColorIndicator(),
        _buildTitleField(),
        _buildTimeButton(),
      ],
    );
  }

  Widget _buildColorIndicator() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onColorTap();
      },
      child: Container(
        margin: const EdgeInsets.only(left: 12, top: 12, bottom: 12),
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _selectedColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: _selectedColor.withAlpha(
                      (50 * _pulseAnimation.value).round(),
                    ),
                    blurRadius: 6,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.doc_text_fill,
                color: Colors.white,
                size: 14,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return Expanded(
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
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.3,
        ),
        decoration: InputDecoration(
          hintText: _titlePlaceholder,
          hintStyle: TextStyle(
            color: AppColors.textTertiary.withAlpha(120),
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildTimeButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 32,
      onPressed: () {
        HapticFeedback.lightImpact();
        widget.onDateTimeTap();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accent.withAlpha(15),
          borderRadius: BorderRadius.circular(8),
          border:
              widget.prefilledDate != null
                  ? Border.all(color: AppColors.accent.withAlpha(40), width: 1)
                  : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.clock, size: 16, color: AppColors.accent),
            const SizedBox(height: 4),
            Text(
              widget.selectedTime.format(context),
              style: TextStyle(
                fontSize: 9,
                color: AppColors.accent,
                fontWeight:
                    widget.prefilledDate != null
                        ? FontWeight.w700
                        : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: AppColors.divider.withAlpha(50),
    );
  }

  Widget _buildTagsField() {
    return TextField(
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
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 12, right: 8),
          child: Icon(
            CupertinoIcons.tag,
            color: AppColors.textSecondary,
            size: 16,
          ),
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 12,
        ),
        isDense: true,
      ),
    );
  }
}
