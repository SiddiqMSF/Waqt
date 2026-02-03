import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

/// Utility class for app theming with dynamic color support.
class AppTheme {
  const AppTheme._();

  /// Fallback seed color when dynamic colors are unavailable
  static const _seedColor = Color(0xFF00838F); // Richer cyan

  /// Creates a color scheme with higher contrast for richer colors
  static ColorScheme _createColorScheme(
    ColorScheme? dynamicScheme,
    Brightness brightness,
  ) {
    if (dynamicScheme != null) {
      // Use dynamic colors from wallpaper, but harmonize for consistency
      return dynamicScheme.harmonized();
    }

    // Fallback: Generate from seed with high contrast
    return ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
    );
  }

  /// Light theme data
  static ThemeData lightTheme(ColorScheme? dynamicScheme) {
    final colorScheme = _createColorScheme(dynamicScheme, Brightness.light);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  /// Dark theme data
  static ThemeData darkTheme(ColorScheme? dynamicScheme) {
    final colorScheme = _createColorScheme(dynamicScheme, Brightness.dark);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
