import 'package:flutter/material.dart';

class ColorUtils {
  ColorUtils._();

  static final _hexRegex = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$');

  static final Map<String, Color> _colorCache = {};

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
    final cached = _colorCache[hexString];
    if (cached != null) return cached;

    final cleanHex =
        hexString.startsWith('#') ? hexString.substring(1) : hexString;
    final colorValue = int.parse('ff$cleanHex', radix: 16);
    final color = Color(colorValue);

    if (_colorCache.length < 50) {
      _colorCache[hexString] = color;
    }

    return color;
  }

  static String toHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }
}
