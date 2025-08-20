import 'package:flutter/material.dart';

// This class holds all the color constants used throughout our app.
// We're going for an iOS dark theme vibe here.
class AppColors {
  // Private constructor to prevent instantiation. We just use static members.
  AppColors._();

  // Background colors for the app.
  static const Color background = Color(0xFF000000); // Pure black background.
  static const Color surface = Color(0xFF1C1C1E); // A dark gray for card-like surfaces.
  static const Color surfaceLight = Color(0xFF2C2C2E); // A slightly lighter gray for some surfaces.
  static const Color divider = Color(0xFF38383A); // Color for separator lines.

  // Text colors, designed to look good on dark backgrounds.
  static const Color textPrimary = Color(0xFFFFFFFF); // Main text color (white).
  static const Color textSecondary = Color(0xFF8E8E93); // Secondary text color (light gray).
  static const Color textTertiary = Color(0xFF48484A); // Tertiary text color (darker gray).

  // Our main accent color, which can be changed by the user.
  static Color _currentAccent = const Color(0xFF0A84FF); // Default iOS blue.
  // A slightly darker version of the accent color, useful for shadows or pressed states.
  static Color _currentAccentDim = const Color(0xFF0051D5);

  // Getters to access the current accent colors.
  static Color get accent => _currentAccent;
  static Color get accentDim => _currentAccentDim;

  // Default colors for tasks.
  static const Color defaultTaskColor = Color(0xFF2C2C2E); // A neutral gray for tasks without a specific color.
  static const Color completedTaskColor = Color(0xFF38383A); // Color for completed tasks.

  // Colors related to the timeline view.
  static const Color currentTimeIndicator = Color(0xFF0A84FF); // The line showing current time.
  static const Color timelineLineColor = Color(0xFF38383A); // The regular lines in the timeline.
  static const Color hourTextColor = Color(0xFF8E8E93); // Color for hour labels in the timeline.

  // A list of colors users can pick for their tasks or notes.
  static const List<Color> userColors = [
    Color(0xFF8E8E93), // Default gray.
    Color(0xFF0A84FF), // Blue.
    Color(0xFF32D74B), // Green.
    Color(0xFFFF453A), // Red.
    Color(0xFFFF9F0A), // Orange.
    Color(0xFFFFD60A), // Yellow.
    Color(0xFFBF5AF2), // Purple.
    Color(0xFF5E5CE6), // Indigo.
  ];

  // Semantic colors for status indicators (success, warning, error).
  static const Color success = Color(0xFF32D74B); // Green for success.
  static const Color warning = Color(0xFFFF9F0A); // Orange for warnings.
  static const Color error = Color(0xFFFF453A); // Red for errors.

  // Converts a hex string (e.g., "#RRGGBB" or "RRGGBB") to a Flutter Color object.
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    // If the hex string is 6 or 7 characters long, assume full opacity (FF).
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    // Remove the '#' if present and append the hex value.
    buffer.write(hexString.replaceFirst('#', ''));
    // Parse the string as a hexadecimal integer to create the Color.
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  // Converts a Flutter Color object to a hex string (e.g., "#RRGGBBAA").
  static String toHex(Color color) {
    // Convert the color to ARGB32 format, then to a hex string, and remove the first two characters (alpha).
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  // Determines the background color for a task block based on its color and completion status.
  static Color getTaskBackground(String colorHex, bool isCompleted) {
    if (isCompleted) return surface.withAlpha(130); // Faded surface if task is completed.

    // Use a slightly lighter surface if the task uses a default neutral color.
    if (colorHex == '#2C2C2E' || colorHex == '#8E8E93') {
      return surfaceLight;
    }

    // Otherwise, use a semi-transparent version of the task's custom color.
    return fromHex(colorHex).withAlpha(25);
  }

  // Sets the global accent color for the app.
  // This also calculates a slightly darker version for `accentDim`.
  static void setAccentColor(String hexColor) {
    _currentAccent = fromHex(hexColor); // Convert hex string to Color.
    // Create `accentDim` by blending the accent color with a semi-transparent black.
    _currentAccentDim = Color.alphaBlend(
      Colors.black.withAlpha(80),
      _currentAccent,
    );
  }

  // A list of predefined accent colors that users can choose from in settings.
  static const List<Color> accentColors = [
    Color(0xFF0A84FF), // iOS Blue (default).
    Color(0xFF32D74B), // Green.
    Color(0xFFFF453A), // Red.
    Color(0xFFFF9F0A), // Orange.
    Color(0xFFFFD60A), // Yellow.
    Color(0xFF5E5CE6), // Indigo.
    Color(0xFFBF5AF2), // Purple.
    Color(0xFF64D2FF), // Cyan.
    Color(0xFFFF375F), // Pink.
  ];

  // Returns a specific color based on the task's priority level.
  static Color getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return const Color(0xFF4CAF50); // Green for lowest priority.
      case 2:
        return const Color(0xFF2196F3); // Blue for low priority.
      case 3:
        return const Color(0xFFFFC107); // Amber for medium priority.
      case 4:
        return const Color(0xFFFF9800); // Darker orange for high priority.
      case 5:
        return const Color(0xFFF44336); // Red for highest priority.
      default:
        return const Color(0xFF9E9E9E); // Default gray for unknown priority.
    }
  }
}
