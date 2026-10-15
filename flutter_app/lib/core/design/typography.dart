import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'tokens.g.dart';

/// Esel Typography system based on design boards & harness.json
abstract final class EselTypography {
  static const String mastheadFamily = 'Cormorant Garamond';
  static const String serifFamily = 'Cormorant Garamond';
  static const String bodyFamily = 'Pretendard';
  static const String metaFamily = 'DM Mono';
  static const String headingKoFamily = 'Nanum Myeongjo';

  /// Calculate masthead font size according to contract P14:
  /// min(200, 0.9 * width / (0.47 * letters))
  static double mastheadSize(String text, double width, {double max = 200.0}) {
    final letters = math.max(2, text.length);
    final calculated = (width * 0.9) / (letters * 0.47);
    return math.min(max, calculated);
  }

  /// Big Masthead (Cover Title, 200px base or scaled)
  static TextStyle masthead({double? fontSize, Color color = EselColors.ink}) {
    return TextStyle(
      fontFamily: mastheadFamily,
      fontSize: fontSize ?? 200.0,
      height: 0.9,
      letterSpacing: -0.05 * (fontSize ?? 200.0),
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  /// Author Name (76px Italic, Serif)
  static TextStyle name({
    double fontSize = 76.0,
    Color color = EselColors.ink,
  }) {
    return TextStyle(
      fontFamily: serifFamily,
      fontSize: fontSize,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  /// Article Heading (30~36px Serif + Nanum Myeongjo fallback)
  static TextStyle heading({
    double fontSize = 32.0,
    Color color = EselColors.ink,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return TextStyle(
      fontFamily: serifFamily,
      fontSize: fontSize,
      height: 1.25,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// Body Text (15px Sans, height 1.45)
  static TextStyle body({
    double fontSize = 15.0,
    Color color = EselColors.ink,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return TextStyle(
      fontFamily: bodyFamily,
      fontSize: fontSize,
      height: 1.45,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// Label (13~16px SemiBold Sans)
  static TextStyle label({
    double fontSize = 14.0,
    Color color = EselColors.ink,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      fontFamily: bodyFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// Meta Info (11~13px DM Mono, tracking 0.06em)
  static TextStyle meta({
    double fontSize = 12.0,
    Color color = EselColors.muted,
  }) {
    return TextStyle(
      fontFamily: metaFamily,
      fontSize: fontSize,
      letterSpacing: 0.06 * fontSize,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  /// Spine Text (Serif Italic)
  static TextStyle spineOwner({Color color = EselColors.ink}) {
    return TextStyle(
      fontFamily: serifFamily,
      fontSize: 13.0,
      fontStyle: FontStyle.italic,
      color: color,
    );
  }

  static TextStyle spineIssue({Color color = EselColors.ink}) {
    return TextStyle(
      fontFamily: metaFamily,
      fontSize: 10.0,
      letterSpacing: 0.04 * 10.0,
      color: color,
    );
  }

  // --- Convenience Getters & Aliases ---
  static TextStyle get mastheadHero => masthead(fontSize: 100.0);
  static TextStyle get headlineLarge => heading(fontSize: 28.0, fontWeight: FontWeight.w700);
  static TextStyle get headlineMedium => heading(fontSize: 24.0, fontWeight: FontWeight.w600);
  static TextStyle get headlineSmall => heading(fontSize: 20.0, fontWeight: FontWeight.w600);
  static TextStyle get bodyLarge => body(fontSize: 16.0);
  static TextStyle get bodyMedium => body(fontSize: 14.0);
  static TextStyle get bodySmall => body(fontSize: 13.0, color: EselColors.muted);
  static TextStyle get labelLarge => label(fontSize: 16.0);
  static TextStyle get labelMedium => label(fontSize: 14.0);
  static TextStyle get labelSmall => label(fontSize: 12.0);
  static TextStyle get caption => body(fontSize: 12.0, color: EselColors.muted);
  static TextStyle get monoLarge => meta(fontSize: 16.0);
  static TextStyle get monoMedium => meta(fontSize: 14.0);
  static TextStyle get monoSmall => meta(fontSize: 12.0);
}
