// This file defines the overall themes for our app, specifically an iOS-style dark theme.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

// This class provides our application's theme data.
class AppTheme {
  // Private constructor to prevent direct instantiation. We only use static getters.
  AppTheme._();

  // Defines the dark theme for the application.
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark, // Set the overall brightness to dark.
      scaffoldBackgroundColor: AppColors.background, // Use our custom background color.

      // Define the color scheme for various UI elements.
      colorScheme: ColorScheme.dark(
        primary: AppColors.accent, // Primary color (our accent color).
        secondary: AppColors.accent, // Secondary color (also our accent color).
        surface: AppColors.surface, // Surface color for cards, dialogs, etc.
        error: AppColors.error, // Color for error states.
        onPrimary: Colors.white, // Text/icon color on primary background.
        onSecondary: Colors.white, // Text/icon color on secondary background.
        onSurface: AppColors.textPrimary, // Text/icon color on surface background.
        onError: Colors.white, // Text/icon color on error background.
      ),

      // Configure the app bar's appearance.
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // Transparent app bar background.
        elevation: 0, // No shadow under the app bar.
        systemOverlayStyle: SystemUiOverlayStyle.light, // Light status bar icons.
      ),

      // Configure the appearance of Card widgets.
      cardTheme: CardTheme(
        color: AppColors.surface, // Card background color.
        elevation: 0, // No shadow for cards.
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded corners.
      ),

      // Configure the appearance of divider lines.
      dividerTheme: const DividerThemeData(
        color: AppColors.divider, // Divider color.
        thickness: 0.5, // Thin divider line.
      ),

      // Set the default font family to SF Pro Display, which is common on iOS.
      fontFamily: '.SF Pro Display',

      // Define various text styles for different parts of the UI.
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }

  // For now, our light theme is just a placeholder that uses the dark theme.
  // We can expand this later if we decide to implement a proper light theme.
  static ThemeData get lightTheme => darkTheme;
}
