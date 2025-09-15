import 'package:flutter/material.dart';

// Custom snackbar notifications with enhanced UI
class CustomSnackBar {
  // Private constructor to prevent instantiation
  CustomSnackBar._();

  // Show a general custom snackbar
  static void show({
    required BuildContext context,
    required String message,
    bool isSuccess = true,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onActionPressed,
    String? actionLabel,
  }) {
    // Clear existing snackbars
    ScaffoldMessenger.of(context).clearSnackBars();

    // Get theme for color adjustments
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Set background color based on type
    final backgroundColor =
        isSuccess
            ? (isDarkMode ? const Color(0xFF00C853) : const Color(0xFF4CAF50))
            : (isDarkMode ? const Color(0xFFFF5252) : const Color(0xFFF44336));

    // Choose appropriate icon
    final iconData =
        isSuccess ? Icons.check_circle_rounded : Icons.error_rounded;

    // Build snackbar content
    final snackBarContent = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withAlpha(100),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Row(
          children: [
            // Animated icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Icon(iconData, color: Colors.white, size: 26),
                );
              },
            ),
            const SizedBox(width: 16),
            // Message text
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Optional action button
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(width: 12),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onActionPressed();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withAlpha(50),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    // Show the snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: snackBarContent,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: duration,
        behavior: SnackBarBehavior.fixed,
        padding: EdgeInsets.zero,
        dismissDirection: DismissDirection.down,
        shape: const RoundedRectangleBorder(),
      ),
    );
  }

  // Show success message
  static void success(BuildContext context, String message) {
    show(context: context, message: message, isSuccess: true);
  }

  // Show error message
  static void error(BuildContext context, String message) {
    show(context: context, message: message, isSuccess: false);
  }

  // Show info message with primary color gradient
  static void info(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();

    final theme = Theme.of(context);

    // Build info snackbar content
    final snackBarContent = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withAlpha(200),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withAlpha(100),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Row(
          children: [
            // Animated info icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: const Icon(
                    Icons.info_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
            // Message text
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    // Show info snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: snackBarContent,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.fixed,
        padding: EdgeInsets.zero,
        dismissDirection: DismissDirection.down,
        shape: const RoundedRectangleBorder(),
      ),
    );
  }

  // Show warning message with orange gradient
  static void warning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();

    final warningColor = Colors.orange.shade700;

    // Build warning snackbar content
    final snackBarContent = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [warningColor, warningColor.withAlpha(220)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: warningColor.withAlpha(100),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Row(
          children: [
            // Animated warning icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
            // Message text
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    // Show warning snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: snackBarContent,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.fixed,
        padding: EdgeInsets.zero,
        dismissDirection: DismissDirection.down,
        shape: const RoundedRectangleBorder(),
      ),
    );
  }

  // Hide current snackbar with animation
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  // Hide all snackbars immediately
  static void hideImmediately(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }
}
