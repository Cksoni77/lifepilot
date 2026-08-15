import 'package:flutter/material.dart';

abstract final class AppTypography {
  static TextTheme textTheme(Color color) {
    return TextTheme(
      displaySmall: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: color,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: color,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      bodyLarge: TextStyle(fontSize: 15, color: color),
      bodyMedium: TextStyle(fontSize: 14, color: color),
      bodySmall: TextStyle(fontSize: 12, color: color.withValues(alpha: .72)),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}
