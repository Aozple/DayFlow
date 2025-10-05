import 'package:flutter/material.dart';

class ColorUtils {
  ColorUtils._();

  static final _hexRegex = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$');

  static bool isValidHex(String color) {
    return _hexRegex.hasMatch(color);
  }

  static String? validateHex(String? color) {
    if (color == null || color.isEmpty) return null;

    if (_hexRegex.hasMatch(color)) {
      if (color.length == 4) {
        final r = color[1];
        final g = color[2];
        final b = color[3];
        return '#$r$r$g$g$b$b'.toUpperCase();
      }
      return color.toUpperCase();
    }
    return null;
  }

  static String validateHexWithFallback(String? color, String fallback) {
    return validateHex(color) ?? fallback;
  }

  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static String toHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }
}
