import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Header widget for settings screen.
///
/// Provides navigation controls with consistent styling matching the app's
/// design system. Features a back button and centered title with proper
/// visual hierarchy and spacing.
class SettingsHeader extends StatelessWidget {
  const SettingsHeader({super.key});

  // Button dimensions
  static const double _buttonHeight = 40.0;
  static const double _buttonVerticalPadding = 8.0;
  static const double _buttonHorizontalPadding = 18.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(200),
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider.withAlpha(30),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          _buildBackButton(context),

          // Header title
          _buildTitleSection(),

          // Spacer to balance the layout (same width as back button)
          const SizedBox(width: 72), // Approximate width of back button
        ],
      ),
    );
  }

  /// Build back button with appropriate styling
  Widget _buildBackButton(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => context.pop(),
      child: Container(
        height: _buttonHeight,
        padding: const EdgeInsets.symmetric(
          horizontal: _buttonHorizontalPadding,
          vertical: _buttonVerticalPadding,
        ),
        decoration: BoxDecoration(
          color: AppColors.error.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.error.withAlpha(40), width: 1),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Back',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build title section with settings icon
  Widget _buildTitleSection() {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.settings, color: AppColors.accent, size: 18),
          const SizedBox(width: 6),
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
