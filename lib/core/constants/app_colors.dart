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

  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static String toHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  static Color getTaskBackground(String colorHex, bool isCompleted) {
    if (isCompleted) return surface.withAlpha(130);

    if (colorHex == '#2C2C2E' || colorHex == '#8E8E93') {
      return surfaceLight;
    }

    return fromHex(colorHex).withAlpha(25);
  }

  static const List<Color> accentColors = [
    Color(0xFF4A90E2),
    Color(0xFF00B894),
    Color(0xFFFF7675),
    Color(0xFFFFA500),
    Color(0xFFFDCB82),
    Color(0xFFA29BFE),
    Color(0xFF00CEC9),
    Color(0xFF6C5CE7),
    Color(0xFFF8A5C2),
    Color(0xFFE17055),
  ];

  static Color getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return const Color(0xFF4CAF50);
      case 2:
        return const Color(0xFF2196F3);
      case 3:
        return const Color(0xFFFFC107);
      case 4:
        return const Color(0xFFFF9800);
      case 5:
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  static Color getAccent(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Color getAccentDim(BuildContext context) {
    return Theme.of(context).colorScheme.tertiary;
  }
}
