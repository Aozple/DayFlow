import 'package:flutter/material.dart';

// Color utility class for app-wide color management
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Background colors
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF1C1C1E);
  static const Color surfaceLight = Color(0xFF2C2C2E);
  static const Color divider = Color(0xFF38383A);

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFF48484A);

  // Accent colors (can be changed by user)
  static Color _currentAccent = const Color(0xFF0A84FF);
  static Color _currentAccentDim = const Color(0xFF0051D5);

  // Accent color getters
  static Color get accent => _currentAccent;
  static Color get accentDim => _currentAccentDim;

  // Task colors
  static const Color defaultTaskColor = Color(0xFF2C2C2E);
  static const Color completedTaskColor = Color(0xFF38383A);

  // Timeline colors
  static const Color currentTimeIndicator = Color(0xFF0A84FF);
  static const Color timelineLineColor = Color(0xFF38383A);
  static const Color hourTextColor = Color(0xFF8E8E93);

  // User-selectable colors for tasks and notes
  static const List<Color> userColors = [
    Color(0xFF8E8E93), // Gray
    Color(0xFF0A84FF), // Blue
    Color(0xFF32D74B), // Green
    Color(0xFFFF453A), // Red
    Color(0xFFFF9F0A), // Orange
    Color(0xFFFFD60A), // Yellow
    Color(0xFFBF5AF2), // Purple
    Color(0xFF5E5CE6), // Indigo
  ];

  // Semantic status colors
  static const Color success = Color(0xFF32D74B);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color error = Color(0xFFFF453A);

  // Convert hex string to Color
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  // Convert Color to hex string
  static String toHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  // Get background color for task based on color and completion status
  static Color getTaskBackground(String colorHex, bool isCompleted) {
    if (isCompleted) return surface.withAlpha(130);

    if (colorHex == '#2C2C2E' || colorHex == '#8E8E93') {
      return surfaceLight;
    }

    return fromHex(colorHex).withAlpha(25);
  }

  // Set app-wide accent color
  static void setAccentColor(String hexColor) {
    _currentAccent = fromHex(hexColor);
    _currentAccentDim = Color.alphaBlend(
      Colors.black.withAlpha(80),
      _currentAccent,
    );
  }

  // Predefined accent color options
  static const List<Color> accentColors = [
    Color(0xFF0A84FF), // iOS Blue (default)
    Color(0xFF32D74B), // Green
    Color(0xFFFF453A), // Red
    Color(0xFFFF9F0A), // Orange
    Color(0xFFFFD60A), // Yellow
    Color(0xFF5E5CE6), // Indigo
    Color(0xFFBF5AF2), // Purple
    Color(0xFF64D2FF), // Cyan
    Color(0xFFFF375F), // Pink
  ];

  // Get color based on task priority
  static Color getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return const Color(0xFF4CAF50); // Lowest
      case 2:
        return const Color(0xFF2196F3); // Low
      case 3:
        return const Color(0xFFFFC107); // Medium
      case 4:
        return const Color(0xFFFF9800); // High
      case 5:
        return const Color(0xFFF44336); // Highest
      default:
        return const Color(0xFF9E9E9E); // Unknown
    }
  }
}
