import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class CustomSnackBar {
  CustomSnackBar._();

  static const double _borderRadius = 12.0;
  static const double _padding = 14.0;
  static const double _iconSize = 24.0;
  static const double _spacing = 14.0;
  static const double _blurRadius = 16.0;
  static const Duration _animationDuration = Duration(milliseconds: 500);
  static const Duration _displayDuration = Duration(seconds: 3);

  static final Map<String, Color> _colorCache = {};

  static Widget _buildAnimatedIcon(IconData icon) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: _animationDuration,
      curve: Curves.bounceOut,
      builder:
          (context, scale, child) => Transform.scale(
            scale: scale,
            child: Icon(icon, color: Colors.white, size: _iconSize),
          ),
    );
  }

  static Widget _buildContent({
    required String message,
    required IconData icon,
    required Color backgroundColor,
    VoidCallback? onActionPressed,
    String? actionLabel,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(_borderRadius),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withAlpha(80),
            blurRadius: _blurRadius,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAnimatedIcon(icon),
          const SizedBox(width: _spacing),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actionLabel != null && onActionPressed != null) ...[
            const SizedBox(width: _spacing),
            _buildActionButton(actionLabel, onActionPressed),
          ],
        ],
      ),
    );
  }

  static Widget _buildActionButton(String label, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white.withAlpha(40),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  static void _showSnackBar({
    required BuildContext context,
    required Widget content,
    Duration? duration,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: content,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: duration ?? _displayDuration,
        behavior: SnackBarBehavior.fixed,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        dismissDirection: DismissDirection.horizontal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
      ),
    );
  }

  static Color _getCachedColor(String key, Color color) {
    return _colorCache.putIfAbsent(key, () => color);
  }

  static void show({
    required BuildContext context,
    required String message,
    bool isSuccess = true,
    Duration? duration,
    VoidCallback? onActionPressed,
    String? actionLabel,
  }) {
    final backgroundColor = _getCachedColor(
      isSuccess ? 'success' : 'error',
      isSuccess
          ? AppColors.success.withAlpha(100)
          : AppColors.error.withAlpha(100),
    );

    final icon = isSuccess ? Icons.check_circle_rounded : Icons.error_rounded;

    final content = _buildContent(
      message: message,
      icon: icon,
      backgroundColor: backgroundColor,
      onActionPressed:
          onActionPressed != null
              ? () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                onActionPressed();
              }
              : null,
      actionLabel: actionLabel,
    );

    _showSnackBar(context: context, content: content, duration: duration);
  }

  static void success(BuildContext context, String message) {
    show(context: context, message: message, isSuccess: true);
  }

  static void error(BuildContext context, String message) {
    show(context: context, message: message, isSuccess: false);
  }

  static void info(BuildContext context, String message) {
    final backgroundColor = _getCachedColor(
      'info',
      AppColors.info.withAlpha(100),
    );

    final content = _buildContent(
      message: message,
      icon: Icons.info_rounded,
      backgroundColor: backgroundColor,
    );

    _showSnackBar(context: context, content: content);
  }

  static void warning(BuildContext context, String message) {
    final backgroundColor = _getCachedColor(
      'warning',
      AppColors.warning.withAlpha(100),
    );

    final content = _buildContent(
      message: message,
      icon: Icons.warning_rounded,
      backgroundColor: backgroundColor,
    );

    _showSnackBar(context: context, content: content);
  }

  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  static void hideImmediately(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  static void clearCache() {
    _colorCache.clear();
  }
}
