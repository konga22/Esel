import 'dart:ui';
import 'package:flutter/widgets.dart';
import '../design/tokens.g.dart';

/// Esel Glass effect container adhering to design tokens:
/// - rgba(249,249,251,0.58) background
/// - 22px blur sigma
/// - Inner subtle highlight border
/// - Fallback to solid Paper on high contrast or reduced transparency
class EselGlass extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final BoxBorder? border;

  const EselGlass({
    super.key,
    required this.child,
    this.borderRadius = EselRadius.card,
    this.padding,
    this.width,
    this.height,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    final highContrast = media?.highContrast ?? false;

    final radius = BorderRadius.circular(borderRadius);

    if (highContrast) {
      // Solid fallback
      return Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: EselGlassTokens.fallback,
          borderRadius: radius,
          border: border ?? Border.all(color: EselColors.hairline),
        ),
        child: child,
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: EselGlassTokens.blurSigma,
          sigmaY: EselGlassTokens.blurSigma,
        ),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: EselGlassTokens.background,
            borderRadius: radius,
            border:
                border ??
                Border.all(
                  color: const Color(0x33FFFFFF), // subtle inner highlight line
                  width: 0.8,
                ),
          ),
          child: child,
        ),
      ),
    );
  }
}
