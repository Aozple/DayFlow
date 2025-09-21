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
  static const Color timelineLineColor = Color(0xFF38383A);
  static const Color hourTextColor = Color(0xFF8E8E93);

  // User-selectable colors for tasks and notes - Refined Premium Collection
  static const List<Color> userColors = [
    Color(0xFFB0B0B5), // Platinum Gray (softer, modern neutral)
    Color(0xFF4A90E2), // Sapphire Blue (modern crisp blue)
    Color(0xFF00B894), // Jade Green (balanced minty green)
    Color(0xFFE74C3C), // Ruby Red (refined red, less harsh)
    Color(0xFFFFA500), // Amber Orange (warm, rich tone)
    Color(0xFFF1C40F), // Champagne Gold (soft golden yellow)
    Color(0xFF9B59B6), // Amethyst Purple (deep, premium purple)
    Color(0xFF6C5CE7), // Midnight Indigo (luxurious indigo)
    Color(0xFF1ABC9C), // Turquoise Teal (cool and fresh)
    Color(0xFFF8A5C2), // Pastel Rose (soft, sophisticated pink)
  ];

  // Semantic status colors
  static const Color success = Color(0xFF32D74B);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color error = Color(0xFFFF453A);
  static const Color info = Color(0xFF5E5CE6);

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

  // Predefined accent color options - Dark UI Friendly (10 colors)
  static const List<Color> accentColors = [
    Color(0xFF4A90E2), // Crisp Blue
    Color(0xFF00B894), // Mint Green
    Color(0xFFFF7675), // Coral
    Color(0xFFFFA500), // Amber
    Color(0xFFFDCB82), // Soft Gold
    Color(0xFFA29BFE), // Lavender
    Color(0xFF00CEC9), // Aqua Teal
    Color(0xFF6C5CE7), // Indigo
    Color(0xFFF8A5C2), // Pastel Rose
    Color(0xFFE17055), // Warm Peach
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
