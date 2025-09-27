import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // MARK: - Background Colors
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF1C1C1E);
  static const Color surfaceLight = Color(0xFF2C2C2E);
  static const Color divider = Color(0xFF38383A);

  // MARK: - Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFF48484A);

  // MARK: - Accent Colors
  static Color _currentAccent = const Color(0xFF0A84FF);
  static Color _currentAccentDim = const Color(0xFF0051D5);

  static Color get accent => _currentAccent;
  static Color get accentDim => _currentAccentDim;

  // MARK: - Task Colors
  static const Color defaultTaskColor = Color(0xFF2C2C2E);
  static const Color completedTaskColor = Color(0xFF38383A);

  // MARK: - Timeline Colors
  static const Color timelineLineColor = Color(0xFF38383A);
  static const Color hourTextColor = Color(0xFF8E8E93);

  // MARK: - User-Selectable Colors
  static const List<Color> userColors = [
    Color(0xFFB0B0B5), // Platinum Gray
    Color(0xFF4A90E2), // Sapphire Blue
    Color(0xFF00B894), // Jade Green
    Color(0xFFE74C3C), // Ruby Red
    Color(0xFFFFA500), // Amber Orange
    Color(0xFFF1C40F), // Champagne Gold
    Color(0xFF9B59B6), // Amethyst Purple
    Color(0xFF6C5CE7), // Midnight Indigo
    Color(0xFF1ABC9C), // Turquoise Teal
    Color(0xFFF8A5C2), // Pastel Rose
  ];

  // MARK: - Semantic Status Colors
  static const Color success = Color(0xFF32D74B);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color error = Color(0xFFFF453A);
  static const Color info = Color(0xFF5E5CE6);

  // MARK: - Utility Methods

  /// Converts a hex string to a Color.
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Converts a Color to a hex string.
  static String toHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Gets the background color for a task based on its color and completion status.
  static Color getTaskBackground(String colorHex, bool isCompleted) {
    if (isCompleted) return surface.withAlpha(130);

    if (colorHex == '#2C2C2E' || colorHex == '#8E8E93') {
      return surfaceLight;
    }

    return fromHex(colorHex).withAlpha(25);
  }

  /// Sets the app-wide accent color.
  static void setAccentColor(String hexColor) {
    _currentAccent = fromHex(hexColor);
    _currentAccentDim = Color.alphaBlend(
      Colors.black.withAlpha(80),
      _currentAccent,
    );
  }

  // MARK: - Accent Color Options
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

  // MARK: - Priority Colors

  /// Gets the color based on task priority.
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
