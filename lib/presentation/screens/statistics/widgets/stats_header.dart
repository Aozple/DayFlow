import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/habit_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StatsHeader extends StatelessWidget {
  final String selectedPeriod;
  final HabitModel? focusedHabit;
  final VoidCallback onBack;
  final Function(String) onPeriodChanged;
  final Function(HabitModel?) onHabitChanged;

  const StatsHeader({
    super.key,
    required this.selectedPeriod,
    this.focusedHabit,
    required this.onBack,
    required this.onPeriodChanged,
    required this.onHabitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider.withAlpha(30),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onBack();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.back,
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statistics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (focusedHabit != null)
                      Text(
                        focusedHabit!.title,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              _buildPeriodSelector(),
            ],
          ),
          if (focusedHabit != null) ...[
            const SizedBox(height: 12),
            _buildHabitFilter(),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    const periods = ['Week', 'Month', 'Year'];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider.withAlpha(40), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children:
            periods.map((period) {
              final isSelected = selectedPeriod == period;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onPeriodChanged(period);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    period,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildHabitFilter() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onHabitChanged(null);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.accent.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.accent.withAlpha(60), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.eye, size: 14, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(
              'Viewing: ${focusedHabit!.title}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 6),
            Icon(CupertinoIcons.xmark, size: 12, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}
