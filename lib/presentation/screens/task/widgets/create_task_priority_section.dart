import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Compact task priority selection widget with minimal space usage.
///
/// Provides a streamlined interface for selecting task priority levels
/// with visual feedback and color coding while maintaining minimal
/// vertical space consumption.
class CreateTaskPrioritySection extends StatelessWidget {
  /// The currently selected priority (1-5).
  final int priority;

  /// Callback function when the priority changes.
  final Function(int) onPriorityChanged;

  const CreateTaskPrioritySection({
    super.key,
    required this.priority,
    required this.onPriorityChanged,
  });

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
          const SizedBox(height: 12),
          _buildPriorityButtons(),
        ],
      ),
    );
  }

  /// Build main row with icon and title
  Widget _buildMainRow() {
    return Row(
      children: [
        _buildPriorityIcon(),
        const SizedBox(width: 12),
        _buildHeaderInfo(),
        const Spacer(),
        _buildCurrentPriorityBadge(),
      ],
    );
  }

  /// Build priority icon with current selection styling
  Widget _buildPriorityIcon() {
    final color = AppColors.getPriorityColor(priority);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withAlpha(220)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(30),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        CupertinoIcons.flag_fill,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  /// Build header information section
  Widget _buildHeaderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priority',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _getPriorityDescription(),
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

  /// Build current priority badge
  Widget _buildCurrentPriorityBadge() {
    final color = AppColors.getPriorityColor(priority);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(40), width: 1),
      ),
      child: Text(
        _getPriorityLabel(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          height: 1.0,
        ),
      ),
    );
  }

  /// Build priority selection buttons
  Widget _buildPriorityButtons() {
    return Row(
      children: List.generate(5, (index) {
        final priorityValue = index + 1;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
            child: _buildPriorityButton(priorityValue),
          ),
        );
      }),
    );
  }

  /// Build individual priority selection button
  Widget _buildPriorityButton(int priorityValue) {
    final isSelected = priority == priorityValue;
    final color = AppColors.getPriorityColor(priorityValue);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPriorityChanged(priorityValue);
      },
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isSelected
                    ? [color, color.withAlpha(220)]
                    : [
                      AppColors.background,
                      AppColors.background.withAlpha(200),
                    ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : AppColors.divider.withAlpha(50),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: color.withAlpha(30),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                priorityValue.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _getShortPriorityLabel(priorityValue),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color:
                      isSelected
                          ? Colors.white.withAlpha(200)
                          : AppColors.textSecondary,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get label for current priority level
  String _getPriorityLabel() {
    switch (priority) {
      case 1:
        return 'Lowest';
      case 2:
        return 'Low';
      case 3:
        return 'Medium';
      case 4:
        return 'High';
      case 5:
        return 'Highest';
      default:
        return 'Medium';
    }
  }

  /// Get short label for priority buttons
  String _getShortPriorityLabel(int priorityValue) {
    switch (priorityValue) {
      case 1:
        return 'Low';
      case 2:
        return 'Low';
      case 3:
        return 'Med';
      case 4:
        return 'High';
      case 5:
        return 'High';
      default:
        return 'Med';
    }
  }

  /// Get description for current priority level
  String _getPriorityDescription() {
    switch (priority) {
      case 1:
        return 'Lowest priority, can be done later';
      case 2:
        return 'Low priority task';
      case 3:
        return 'Medium priority, standard level';
      case 4:
        return 'High priority, needs attention';
      case 5:
        return 'Highest priority, urgent task';
      default:
        return 'Medium priority, standard level';
    }
  }
}
