import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';

/// A simplified empty slot indicator with a plus icon.
///
/// This widget is displayed in time slots that have no tasks scheduled,
/// providing a visual cue that users can tap to add a new task or note.
class HomeEmptySlot extends StatelessWidget {
  const HomeEmptySlot({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), // Smooth animation.
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.divider.withAlpha(20), // Subtle background.
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.divider.withAlpha(40),
            width: 1,
          ), // Light border.
        ),
        child: Icon(
          CupertinoIcons.plus, // Plus icon.
          color: AppColors.textTertiary.withAlpha(100), // Faded color.
          size: 18,
        ),
      ),
    );
  }
}
