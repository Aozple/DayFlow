import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/habit_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Compact habit type selection widget with minimal space usage.
///
/// Provides an efficient interface for selecting habit type and configuring
/// target values with optimized vertical space consumption while maintaining
/// visual appeal and usability.
class CreateHabitTypeSection extends StatefulWidget {
  final HabitType habitType;
  final int? targetValue;
  final String? unit;
  final Function(HabitType) onTypeChanged;
  final Function(int?) onTargetValueChanged;
  final Function(String?) onUnitChanged;

  const CreateHabitTypeSection({
    super.key,
    required this.habitType,
    required this.targetValue,
    required this.unit,
    required this.onTypeChanged,
    required this.onTargetValueChanged,
    required this.onUnitChanged,
  });

  @override
  State<CreateHabitTypeSection> createState() => _CreateHabitTypeSectionState();
}

class _CreateHabitTypeSectionState extends State<CreateHabitTypeSection> {
  late TextEditingController _targetController;
  late TextEditingController _unitController;

  // Focus states for visual feedback
  bool _isTargetFocused = false;
  bool _isUnitFocused = false;

  // Focus nodes for input fields
  final FocusNode _targetFocus = FocusNode();
  final FocusNode _unitFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupFocusListeners();
  }

  @override
  void dispose() {
    _targetController.dispose();
    _unitController.dispose();
    _targetFocus.dispose();
    _unitFocus.dispose();
    super.dispose();
  }

  /// Initialize text controllers with current values
  void _initializeControllers() {
    _targetController = TextEditingController(
      text: widget.targetValue?.toString() ?? '',
    );
    _unitController = TextEditingController(text: widget.unit ?? '');
  }

  /// Setup focus listeners for visual feedback
  void _setupFocusListeners() {
    _targetFocus.addListener(() {
      setState(() => _isTargetFocused = _targetFocus.hasFocus);
    });

    _unitFocus.addListener(() {
      setState(() => _isUnitFocused = _unitFocus.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
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
        border: Border.all(color: AppColors.divider.withAlpha(30), width: 0.5),
      ),
      child: Column(
        children: [
          _buildMainRow(),
          if (widget.habitType == HabitType.quantifiable) _buildTargetRow(),
        ],
      ),
    );
  }

  /// Build main row with type selection and header info
  Widget _buildMainRow() {
    return Row(
      children: [
        _buildTypeIcon(),
        const SizedBox(width: 12),
        _buildHeaderInfo(),
        const Spacer(),
        _buildTypeSelector(),
      ],
    );
  }

  /// Build type icon with current selection styling
  Widget _buildTypeIcon() {
    final isQuantifiable = widget.habitType == HabitType.quantifiable;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isQuantifiable
                  ? [AppColors.accent, AppColors.accent.withAlpha(220)]
                  : [AppColors.success, AppColors.success.withAlpha(220)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color:
                isQuantifiable
                    ? AppColors.accent.withAlpha(30)
                    : AppColors.success.withAlpha(30),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        isQuantifiable
            ? CupertinoIcons.chart_bar_fill
            : CupertinoIcons.checkmark_circle_fill,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  /// Build header information section
  Widget _buildHeaderInfo() {
    final isQuantifiable = widget.habitType == HabitType.quantifiable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Habit Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        Text(
          isQuantifiable ? 'Track progress with targets' : 'Simple completion',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  /// Build compact type selector with icons
  Widget _buildTypeSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTypeButton(
          type: HabitType.simple,
          icon: CupertinoIcons.checkmark_circle,
          label: 'Simple',
          color: AppColors.success,
        ),
        const SizedBox(width: 12),
        _buildTypeButton(
          type: HabitType.quantifiable,
          icon: CupertinoIcons.chart_bar,
          label: 'Track',
          color: AppColors.accent,
        ),
      ],
    );
  }

  /// Build individual type selection button
  Widget _buildTypeButton({
    required HabitType type,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isSelected = widget.habitType == type;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTypeChanged(type);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors:
                    isSelected
                        ? [color.withAlpha(25), color.withAlpha(15)]
                        : [
                          AppColors.background,
                          AppColors.background.withAlpha(200),
                        ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isSelected
                        ? color.withAlpha(60)
                        : AppColors.divider.withAlpha(40),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow:
                  isSelected
                      ? [
                        BoxShadow(
                          color: color.withAlpha(20),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                      : null,
            ),
            child: Icon(
              icon,
              color: isSelected ? color : AppColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected ? color : AppColors.textSecondary,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  /// Build target configuration row for quantifiable habits
  Widget _buildTargetRow() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withAlpha(8),
            AppColors.accent.withAlpha(5),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withAlpha(30), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              CupertinoIcons.number_circle_fill,
              size: 18,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Target:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 12),
          _buildCompactTargetInput(),
          const SizedBox(width: 12),
          _buildCompactUnitInput(),
          const SizedBox(width: 8),
          _buildExampleIcon(),
        ],
      ),
    );
  }

  /// Build compact target value input
  Widget _buildCompactTargetInput() {
    return Container(
      width: 60,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              _isTargetFocused
                  ? AppColors.accent.withAlpha(60)
                  : AppColors.divider.withAlpha(40),
          width: _isTargetFocused ? 1.5 : 1,
        ),
        boxShadow:
            _isTargetFocused
                ? [
                  BoxShadow(
                    color: AppColors.accent.withAlpha(20),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
                : null,
      ),
      child: TextField(
        controller: _targetController,
        focusNode: _targetFocus,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.2,
        ),
        decoration: InputDecoration(
          hintText: '0',
          hintStyle: TextStyle(
            color: AppColors.textTertiary.withAlpha(120),
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          isDense: true,
        ),
        onChanged: (value) {
          widget.onTargetValueChanged(
            value.isEmpty ? null : int.tryParse(value),
          );
        },
      ),
    );
  }

  /// Build compact unit input
  Widget _buildCompactUnitInput() {
    return Expanded(
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                _isUnitFocused
                    ? AppColors.accent.withAlpha(60)
                    : AppColors.divider.withAlpha(40),
            width: _isUnitFocused ? 1.5 : 1,
          ),
          boxShadow:
              _isUnitFocused
                  ? [
                    BoxShadow(
                      color: AppColors.accent.withAlpha(20),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                  : null,
        ),
        child: TextField(
          controller: _unitController,
          focusNode: _unitFocus,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
          decoration: InputDecoration(
            hintText: 'glasses, minutes, pages...',
            hintStyle: TextStyle(
              color: AppColors.textTertiary.withAlpha(120),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            isDense: true,
          ),
          onChanged: widget.onUnitChanged,
        ),
      ),
    );
  }

  /// Build example icon with tooltip
  Widget _buildExampleIcon() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showExampleTooltip();
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.info.withAlpha(15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(
          CupertinoIcons.lightbulb_fill,
          size: 16,
          color: AppColors.info,
        ),
      ),
    );
  }

  /// Show example tooltip when help icon is tapped
  void _showExampleTooltip() {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Examples'),
            content: const Text('8 glasses\n30 minutes\n5 pages\n10,000 steps'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Got it'),
              ),
            ],
          ),
    );
  }
}
