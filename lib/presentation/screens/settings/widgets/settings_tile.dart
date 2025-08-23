import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// A reusable widget to build a tappable list tile for settings.
///
/// This widget provides a consistent tile layout for settings options,
/// with support for destructive actions (shown in red).
class SettingsTile extends StatelessWidget {
  /// The title of the setting.
  final String title;

  /// The subtitle describing the setting.
  final String subtitle;

  /// The widget to display on the trailing side of the tile.
  final Widget trailing;

  /// Callback function when the tile is tapped.
  final VoidCallback onTap;

  /// The icon to display on the leading side of the tile.
  final IconData icon;

  /// Whether this is a destructive action (affects styling).
  final bool isDestructive;

  const SettingsTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
    required this.icon,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 0.5),
        ), // Top border.
      ),
      child: ListTile(
        leading: Icon(
          icon,
          size: 20,
          color:
              isDestructive
                  ? AppColors.error
                  : AppColors.textSecondary, // Red if destructive.
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color:
                isDestructive
                    ? AppColors.error
                    : AppColors.textPrimary, // Red if destructive.
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        trailing: trailing, // Custom trailing widget.
        onTap: onTap, // Action on tap.
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}

/// A reusable widget to build an info list tile (read-only).
///
/// This widget provides a consistent tile layout for displaying information
/// that cannot be changed by the user.
class SettingsInfoTile extends StatelessWidget {
  /// The title of the information.
  final String title;

  /// The value of the information.
  final String value;

  /// The icon to display on the leading side of the tile.
  final IconData icon;

  const SettingsInfoTile({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          size: 20,
          color: AppColors.textSecondary,
        ), // Leading icon.
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: Text(
          value, // The info value.
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
