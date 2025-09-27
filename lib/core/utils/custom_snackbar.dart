import 'package:flutter/material.dart';

class CustomSnackBar {
  CustomSnackBar._();

  // MARK: - General SnackBar

  /// Shows a customizable snackbar notification.
  static void show({
    required BuildContext context,
    required String message,
    bool isSuccess = true,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onActionPressed,
    String? actionLabel,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final backgroundColor =
        isSuccess
            ? (isDarkMode ? const Color(0xFF00C853) : const Color(0xFF4CAF50))
            : (isDarkMode ? const Color(0xFFFF5252) : const Color(0xFFF44336));

    final iconData =
        isSuccess ? Icons.check_circle_rounded : Icons.error_rounded;

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

  // MARK: - Specific SnackBar Types

  /// Shows a success snackbar.
  static void success(BuildContext context, String message) {
    show(context: context, message: message, isSuccess: true);
  }

  /// Shows an error snackbar.
  static void error(BuildContext context, String message) {
    show(context: context, message: message, isSuccess: false);
  }

  /// Shows an info snackbar with a primary color gradient.
  static void info(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();

    final theme = Theme.of(context);

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

  /// Shows a warning snackbar with an orange gradient.
  static void warning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();

    final warningColor = Colors.orange.shade700;

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

  // MARK: - Control Methods

  /// Hides the current snackbar with animation.
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// Hides all snackbars immediately.
  static void hideImmediately(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }
}
