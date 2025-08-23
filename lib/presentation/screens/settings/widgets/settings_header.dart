import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Custom SliverAppBar for the settings screen.
///
/// This widget provides a consistent header for the settings screen with
/// a back button and title. It's designed to be pinned at the top
/// when scrolling through the settings options.
class SettingsHeader extends StatelessWidget {
  const SettingsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent, // Transparent background.
      elevation: 0, // No shadow.
      pinned: true, // Stays at the top when scrolling.
      leading: Container(
        margin: const EdgeInsets.only(left: 8),
        child: CircleAvatar(
          backgroundColor: AppColors.surfaceLight,
          child: IconButton(
            icon: const Icon(
              CupertinoIcons.chevron_back, // Back arrow icon.
              color: AppColors.textPrimary,
              size: 22,
            ),
            onPressed:
                () => context.pop(), // Pop the current screen to go back.
          ),
        ),
      ),
      title: const Text(
        'Settings',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      centerTitle: true, // Center the title.
    );
  }
}
