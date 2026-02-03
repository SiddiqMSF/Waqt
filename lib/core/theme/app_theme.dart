import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Utility class for app theming - uses colors that complement the background image.
class AppTheme {
  const AppTheme._();

  /// Seed color that complements the bg.jpg image
  static const _seedColor = Color(0xFF5D8AA8); // Muted blue-gray

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
        dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
        dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
