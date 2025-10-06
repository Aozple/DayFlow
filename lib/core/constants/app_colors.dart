import 'package:dayflow/core/utils/app_color_utils.dart';
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF151515);
  static const Color surface = Color(0xFF272827);
  static const Color surfaceLight = Color(0xFF505050);
  static const Color divider = Color(0xFF464646);

  static const Color textPrimary = Color(0xFFf5f5f5);
  static const Color textSecondary = Color(0xFFa5a5a5);
  static const Color textTertiary = Color(0xFF8a8a8a);

  static const Color defaultTaskColor = Color(0xFF2C2C2E);
  static const Color completedTaskColor = Color(0xFF38383A);

  static const Color timelineLineColor = Color(0xFF38383A);
  static const Color hourTextColor = Color(0xFF8E8E93);

  static const Color transparent = Color(0x00000000);

  static const List<Color> userColors = [
    Color(0xFFB0B0B5),
    Color(0xFF4A90E2),
    Color(0xFF00B894),
    Color(0xFFE74C3C),
    Color(0xFFFFA500),
    Color(0xFFF1C40F),
    Color(0xFF9B59B6),
    Color(0xFF6C5CE7),
    Color(0xFF1ABC9C),
    Color(0xFFF8A5C2),
  ];

  static const Color success = Color(0xFF32D74B);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color error = Color(0xFFFF453A);
  static const Color info = Color(0xFF5E5CE6);

  static Color getTaskBackground(String colorHex, bool isCompleted) {
    if (isCompleted) return surface.withAlpha(130);

    if (colorHex == '#2C2C2E' || colorHex == '#8E8E93') {
      return surfaceLight;
    }

    return AppColorUtils.fromHex(colorHex).withAlpha(25);
  }

  static const List<Color> accentColors = [
    Color(0xFF4A90E2),
    Color(0xFF00B894),
    Color(0xFFFF7675),
    Color(0xFFfb6f92),
    Color(0xFFFDCB82),
    Color(0xFFA29BFE),
    Color(0xFF00CEC9),
    Color(0xFF6C5CE7),
    Color(0xFFF8A5C2),
    Color(0xFFE17055),
  ];

  static const Map<int, Color> _priorityColors = {
    1: Color(0xFF4CAF50),
    2: Color(0xFF2196F3),
    3: Color(0xFFFFC107),
    4: Color(0xFFFF9800),
    5: Color(0xFFF44336),
  };

  static const Color _defaultPriorityColor = Color(0xFF9E9E9E);

  static Color getPriorityColor(int priority) {
    return _priorityColors[priority] ?? _defaultPriorityColor;
  }

  static Color getAccent(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Color getAccentDim(BuildContext context) {
    return Theme.of(context).colorScheme.tertiary;
  }
}
