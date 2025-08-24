import 'package:dayflow/presentation/widgets/draggable_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:dayflow/core/constants/app_colors.dart';

class NotificationTimePicker extends StatefulWidget {
  final int currentMinutes;
  final Function(int) onTimeSelected;

  const NotificationTimePicker({
    super.key,
    required this.currentMinutes,
    required this.onTimeSelected,
  });

  @override
  State<NotificationTimePicker> createState() => _NotificationTimePickerState();
}

class _NotificationTimePickerState extends State<NotificationTimePicker> {
  late int selectedMinutes;
  final TextEditingController customController = TextEditingController();
  final List<Map<String, dynamic>> presetOptions = [
    {'label': 'At time of task', 'value': 0},
    {'label': '5 minutes before', 'value': 5},
    {'label': '10 minutes before', 'value': 10},
    {'label': '15 minutes before', 'value': 15},
    {'label': '30 minutes before', 'value': 30},
    {'label': '1 hour before', 'value': 60},
    {'label': '2 hours before', 'value': 120},
    {'label': '1 day before', 'value': 1440},
  ];

  @override
  void initState() {
    super.initState();
    selectedMinutes = widget.currentMinutes;
    if (!presetOptions.any((option) => option['value'] == selectedMinutes)) {
      customController.text = selectedMinutes.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableModal(
      title: 'Default Reminder Time',
      initialHeight: 500,
      minHeight: 400,
      leftAction: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => Navigator.pop(context),
        child: const Text(
          'Cancel',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
      rightAction: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          widget.onTimeSelected(selectedMinutes);
          Navigator.pop(context);
        },
        child: Text(
          'Save',
          style: TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: Column(
        children: [
          // Preset options
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                ...presetOptions.map(
                  (option) => _buildOption(
                    label: option['label'],
                    value: option['value'],
                    isSelected: selectedMinutes == option['value'],
                  ),
                ),
                const SizedBox(height: 8),
                // Custom option
                _buildCustomOption(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required String label,
    required int value,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          setState(() {
            selectedMinutes = value;
            customController.clear();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? AppColors.accent.withAlpha(25)
                    : AppColors.surfaceLight.withAlpha(100),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected
                      ? AppColors.accent.withAlpha(60)
                      : AppColors.divider.withAlpha(50),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.bell,
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color:
                        isSelected ? AppColors.accent : AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.checkmark,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomOption() {
    final isCustomSelected =
        !presetOptions.any((option) => option['value'] == selectedMinutes);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          setState(() {
            selectedMinutes =
                int.tryParse(customController.text) ?? selectedMinutes;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color:
                isCustomSelected
                    ? AppColors.accent.withAlpha(25)
                    : AppColors.surfaceLight.withAlpha(100),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isCustomSelected
                      ? AppColors.accent.withAlpha(60)
                      : AppColors.divider.withAlpha(50),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.time,
                color:
                    isCustomSelected
                        ? AppColors.accent
                        : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Custom',
                style: TextStyle(
                  color:
                      isCustomSelected
                          ? AppColors.accent
                          : AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight:
                      isCustomSelected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: customController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Minutes',
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.divider.withAlpha(50),
                        width: 0.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.divider.withAlpha(50),
                        width: 0.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.accent),
                    ),
                  ),
                  onChanged: (value) {
                    final minutes = int.tryParse(value);
                    if (minutes != null && minutes > 0) {
                      setState(() {
                        selectedMinutes = minutes;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              if (isCustomSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.checkmark,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
