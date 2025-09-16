import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';

/// Empty slot indicator with plus icon for adding new items
class HomeEmptySlot extends StatelessWidget {
  const HomeEmptySlot({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surface.withAlpha(60),
              AppColors.surfaceLight.withAlpha(40),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.divider.withAlpha(30),
            width: 0.5,
          ),
        ),
        child: Center(
          child: Icon(
            CupertinoIcons.plus,
            color: AppColors.textTertiary.withAlpha(120),
            size: 16,
          ),
        ),
      ),
    );
  }
}
