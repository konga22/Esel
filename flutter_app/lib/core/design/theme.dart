import 'package:flutter/material.dart';
import 'tokens.g.dart';
import 'typography.dart';

abstract final class EselTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: EselTypography.bodyFamily,
      fontFamilyFallback: EselTypography.sansFallback,
      scaffoldBackgroundColor: EselColors.paper,
      colorScheme: const ColorScheme.light(
        surface: EselColors.paper,
        onSurface: EselColors.ink,
        primary: EselColors.ink,
        onPrimary: EselColors.paper,
        outline: EselColors.hairline,
        error: EselColors.error,
      ),
      dividerTheme: const DividerThemeData(
        color: EselColors.hairline,
        thickness: 1.0,
        space: 1.0,
      ),
      textTheme: TextTheme(
        bodyMedium: EselTypography.body(),
        labelLarge: EselTypography.label(),
      ),
    );
  }
}
