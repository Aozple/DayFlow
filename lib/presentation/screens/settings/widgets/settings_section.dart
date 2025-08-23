import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// A reusable widget to build a section container with a title and icon.
///
/// This widget provides a consistent container for grouping related settings
/// options together, with a section header that includes an icon and title.
class SettingsSection extends StatelessWidget {
  /// The title of the section.
  final String title;

  /// The icon to display in the section header.
  final IconData icon;

  /// The list of widgets to display as children in the section.
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface, // Background color for the section.
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with icon and title.
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.accent), // Section icon.
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // The content of the section (list of tiles).
          ...children,
        ],
      ),
    );
  }
}
