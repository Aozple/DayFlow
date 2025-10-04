import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';

class HomeEmptySlot extends StatelessWidget {
  const HomeEmptySlot({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface.withAlpha(150),
          borderRadius: BorderRadius.circular(12),
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
