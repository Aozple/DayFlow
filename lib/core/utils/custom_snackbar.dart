import 'package:flutter/material.dart';

// This class provides custom snackbar notifications for our app.
// It's designed to show nice-looking messages at the bottom of the screen.
class CustomSnackBar {
  // Private constructor to prevent instantiation. We only use static methods.
  CustomSnackBar._();

  // Shows a general custom snackbar with a message, type (success/error), and optional action.
  static void show({
    required BuildContext context,
    required String message,
    bool isSuccess = true, // True for success, false for error.
    Duration duration = const Duration(seconds: 3), // How long the snackbar stays visible.
    VoidCallback? onActionPressed, // Callback for an optional action button.
    String? actionLabel, // Text for the optional action button.
  }) {
    // First, clear any snackbars that are currently showing to avoid stacking.
    ScaffoldMessenger.of(context).clearSnackBars();

    // Get the current theme to determine dark/light mode for color adjustments.
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Define background colors based on whether it's a success or error message.
    final backgroundColor =
        isSuccess
            ? (isDarkMode ? const Color(0xFF00C853) : const Color(0xFF4CAF50)) // Green for success.
            : (isDarkMode ? const Color(0xFFFF5252) : const Color(0xFFF44336)); // Red for error.

    // Choose the appropriate icon based on success or error.
    final iconData =
        isSuccess ? Icons.check_circle_rounded : Icons.error_rounded;

    // Build the actual content of the snackbar.
    final snackBarContent = Container(
      width: double.infinity, // Make it take the full width.
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: backgroundColor, // Background color.
        // Only round the top corners since the snackbar is fixed to the bottom.
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withAlpha(100), // Subtle shadow for depth.
            blurRadius: 20,
            offset: const Offset(0, -5), // Make the shadow appear above the snackbar.
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: true, // Ensure content respects the bottom safe area (e.g., iPhone home indicator).
        child: Row(
          children: [
            // An animated icon that scales in when the snackbar appears.
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0), // Animate from scale 0 to 1.
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut, // A bouncy animation curve.
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Icon(iconData, color: Colors.white, size: 26),
                );
              },
            ),
            const SizedBox(width: 16),
            // The main message text.
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
                overflow: TextOverflow.ellipsis, // Truncate if message is too long.
              ),
            ),
            // Optional action button, only shown if `actionLabel` and `onActionPressed` are provided.
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(width: 12),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide snackbar when action is pressed.
                  onActionPressed(); // Execute the provided action.
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white, // Text color for the button.
                  backgroundColor: Colors.white.withAlpha(50), // Semi-transparent background.
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Rounded corners for the button.
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

    // Show the snackbar using ScaffoldMessenger.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: snackBarContent,
        backgroundColor: Colors.transparent, // Make the SnackBar's own background transparent.
        elevation: 0, // No shadow for the SnackBar itself.
        duration: duration,
        behavior: SnackBarBehavior.fixed, // Fix the snackbar to the bottom of the screen.
        padding: EdgeInsets.zero, // Remove default padding from SnackBar.
        dismissDirection: DismissDirection.down, // Allow dismissing by swiping down.
        shape:
            const RoundedRectangleBorder(), // No rounded corners for the SnackBar container.
      ),
    );
  }

  // Shows a quick success message snackbar.
  static void success(BuildContext context, String message) {
    show(context: context, message: message, isSuccess: true);
  }

  // Shows a quick error message snackbar.
  static void error(BuildContext context, String message) {
    show(context: context, message: message, isSuccess: false);
  }

  // Shows an informational message snackbar with a custom primary color gradient.
  static void info(BuildContext context, String message) {
    // Clear any existing snackbars.
    ScaffoldMessenger.of(context).clearSnackBars();

    final theme = Theme.of(context);

    // Build the info snackbar content.
    final snackBarContent = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary, // Start with primary theme color.
            theme.colorScheme.primary.withAlpha(200), // End with a slightly transparent version.
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
            // Animated info icon.
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
            // Message text.
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

    // Show the info snackbar.
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

  // Shows a warning message snackbar with an orange gradient.
  static void warning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();

    final warningColor = Colors.orange.shade700; // A deep orange color for warnings.

    // Build the warning snackbar content.
    final snackBarContent = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [warningColor, warningColor.withAlpha(220)], // Orange gradient.
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
            // Animated warning icon.
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
            // Message text.
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

    // Show the warning snackbar.
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

  // Hides the currently visible snackbar with an animation.
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  // Hides all snackbars immediately without any animation.
  static void hideImmediately(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }
}
