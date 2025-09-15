import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';

/// Empty slot indicator with plus icon for adding new items
class HomeEmptySlot extends StatelessWidget {
  const HomeEmptySlot({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.divider.withAlpha(20),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.divider.withAlpha(40), width: 1),
        ),
        child: Icon(
          CupertinoIcons.plus,
          color: AppColors.textTertiary.withAlpha(100),
          size: 18,
        ),
      ),
    );
  }
}
