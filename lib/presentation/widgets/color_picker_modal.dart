import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/core/utils/app_color_utils.dart';
import 'package:dayflow/presentation/widgets/draggable_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ColorPickerModal extends StatefulWidget {
  final String selectedColor;

  final Function(String) onColorSelected;

  final Widget Function(String colorHex)? previewBuilder;

  final String title;

  final List<String>? recentColors;

  final bool showPreview;

  final List<Color>? customColors;

  const ColorPickerModal({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    this.previewBuilder,
    this.title = 'Select Color',
    this.recentColors,
    this.showPreview = true,
    this.customColors,
  });

  static Future<String?> show({
    required BuildContext context,
    required String selectedColor,
    Widget Function(String colorHex)? previewBuilder,
    String title = 'Select Color',
    List<String>? recentColors,
    bool showPreview = true,
    List<Color>? customColors,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => ColorPickerModal(
            selectedColor: selectedColor,
            onColorSelected: (color) => Navigator.pop(context, color),
            previewBuilder: previewBuilder,
            title: title,
            recentColors: recentColors,
            showPreview: showPreview,
            customColors: customColors,
          ),
    );
  }

  @override
  State<ColorPickerModal> createState() => _ColorPickerModalState();
}

class _ColorPickerModalState extends State<ColorPickerModal>
    with TickerProviderStateMixin {
  late String _currentSelectedColor;
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  List<Color> get _colorsToShow => widget.customColors ?? AppColors.userColors;

  @override
  void initState() {
    super.initState();
    _currentSelectedColor = widget.selectedColor;
    _initializeAnimations();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseController.repeat(reverse: true);

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  void _handleColorSelection(String colorHex) {
    HapticFeedback.lightImpact();
    _scaleController.forward().then((_) => _scaleController.reverse());
    setState(() => _currentSelectedColor = colorHex);
  }

  void _confirmSelection() {
    HapticFeedback.mediumImpact();
    widget.onColorSelected(_currentSelectedColor);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableModal(
      title: widget.title,
      initialHeight: _calculateInitialHeight(),
      minHeight: 300,
      rightAction: _buildConfirmButton(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showPreview && widget.previewBuilder != null) ...[
              const SizedBox(height: 16),
              _buildPreviewSection(),
              const SizedBox(height: 16),
            ],
            if (widget.recentColors != null &&
                widget.recentColors!.isNotEmpty) ...[
              _buildRecentColorsSection(),
              const SizedBox(height: 32),
            ],
            _buildAllColorsSection(),
            const SizedBox(height: 72),
          ],
        ),
      ),
    );
  }

  double _calculateInitialHeight() {
    double baseHeight = 300;

    if (widget.showPreview && widget.previewBuilder != null) {
      baseHeight += 140;
    }

    if (widget.recentColors != null && widget.recentColors!.isNotEmpty) {
      baseHeight += 120;
    }

    const colorsPerRow = 5;
    const colorSize = 60.0;
    const rowSpacing = 16.0;
    const sectionHeaderHeight = 60.0;

    final numberOfRows = (_colorsToShow.length / colorsPerRow).ceil();
    final gridHeight =
        sectionHeaderHeight +
        (numberOfRows * colorSize) +
        ((numberOfRows - 1) * rowSpacing);

    baseHeight += gridHeight;

    return baseHeight.clamp(300, 700);
  }

  Widget _buildConfirmButton() {
    final hasChanged = _currentSelectedColor != widget.selectedColor;

    return AnimatedScale(
      scale: hasChanged ? 1.0 : 0.9,
      duration: const Duration(milliseconds: 200),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: hasChanged ? _confirmSelection : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color:
                hasChanged
                    ? Theme.of(context).colorScheme.primary
                    : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  hasChanged
                      ? Theme.of(context).colorScheme.primary
                      : AppColors.divider,
              width: 1,
            ),
          ),
          child: Text(
            'Done',
            style: TextStyle(
              color: hasChanged ? Colors.white : AppColors.textTertiary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.surface.withAlpha(200)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withAlpha(40), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColorUtils.fromHex(_currentSelectedColor).withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  CupertinoIcons.eye_fill,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Preview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          widget.previewBuilder!(_currentSelectedColor),
        ],
      ),
    );
  }

  Widget _buildRecentColorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: CupertinoIcons.clock_fill,
          title: 'Recently Used',
          subtitle: 'Your last ${widget.recentColors!.length} colors',
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.recentColors!.take(8).length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final colorHex = widget.recentColors![index];
              return _buildColorOption(
                AppColorUtils.fromHex(colorHex),
                colorHex,
                size: 52,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAllColorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: CupertinoIcons.color_filter_fill,
          title:
              widget.customColors != null ? 'Available Colors' : 'All Colors',
          subtitle: '${_colorsToShow.length} colors available',
        ),
        const SizedBox(height: 16),
        _buildDynamicColorGrid(),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 34),
          child: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicColorGrid() {
    const colorsPerRow = 5;
    final colorGroups = <List<Color>>[];

    for (int i = 0; i < _colorsToShow.length; i += colorsPerRow) {
      final endIndex =
          (i + colorsPerRow < _colorsToShow.length)
              ? i + colorsPerRow
              : _colorsToShow.length;
      colorGroups.add(_colorsToShow.sublist(i, endIndex));
    }

    return Column(
      children:
          colorGroups.map((colors) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment:
                    colors.length == colorsPerRow
                        ? MainAxisAlignment.spaceBetween
                        : MainAxisAlignment.start,
                children:
                    colors.asMap().entries.map((entry) {
                      final color = entry.value;
                      final isLast = entry.key == colors.length - 1;

                      return Padding(
                        padding: EdgeInsets.only(
                          right:
                              colors.length < colorsPerRow && !isLast ? 16 : 0,
                        ),
                        child: _buildColorOption(
                          color,
                          AppColorUtils.toHex(color),
                        ),
                      );
                    }).toList(),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildColorOption(Color color, String colorHex, {double size = 60}) {
    final isSelected = _currentSelectedColor == colorHex;
    final isOriginalSelection = widget.selectedColor == colorHex;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isSelected ? _scaleAnimation.value : 1.0,
          child: GestureDetector(
            onTap: () => _handleColorSelection(colorHex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color:
                      isSelected
                          ? Colors.white
                          : isOriginalSelection
                          ? AppColors.textSecondary.withAlpha(120)
                          : Colors.transparent,
                  width: isSelected ? 4 : 2,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: color.withAlpha(150),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    ),
                  if (isOriginalSelection && !isSelected)
                    BoxShadow(
                      color: color.withAlpha(80),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child:
                    isSelected
                        ? Container(
                          key: const ValueKey('selected'),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(30),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            CupertinoIcons.checkmark_alt,
                            color: Colors.white,
                            size: 24,
                          ),
                        )
                        : isOriginalSelection
                        ? Container(
                          key: const ValueKey('original'),
                          child: Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(200),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        )
                        : const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}
