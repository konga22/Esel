import 'dart:ui';
import 'package:flutter/widgets.dart';
import '../design/tokens.g.dart';

/// Esel Glass (docs/design/README.md "Glass"):
/// - rgba(249,249,251,0.58) 배경 + blur(22px) saturate(1.6)
/// - 안쪽 흰 선 rgba(255,255,255,0.6) 1px
/// - 그림자 0 10px 28px rgba(0,0,0,0.14), 떠 있는 바깥쪽에만
/// - 흰 화면 위(solid), 고대비·투명도 줄이기에서는 같은 그림자의 Paper 단색
class EselGlass extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final BoxBorder? border;

  /// 뒤에 사진이 없는 흰 화면이면 true. 디자인의 "캡슐 · 단색".
  final bool solid;

  const EselGlass({
    super.key,
    required this.child,
    this.borderRadius = EselRadius.card,
    this.padding,
    this.width,
    this.height,
    this.border,
    this.solid = false,
  });

  static const Color innerLine = Color(0x99FFFFFF);
  static const BoxShadow floatShadow = BoxShadow(
    color: Color(0x24000000),
    offset: Offset(0, 10),
    blurRadius: 28,
  );

  /// CSS saturate(1.6)와 같은 색 행렬(feColorMatrix saturate).
  static const ColorFilter saturate = ColorFilter.matrix(<double>[
    0.213 + 0.787 * EselGlassTokens.saturate,
    0.715 - 0.715 * EselGlassTokens.saturate,
    0.072 - 0.072 * EselGlassTokens.saturate,
    0,
    0,
    0.213 - 0.213 * EselGlassTokens.saturate,
    0.715 + 0.285 * EselGlassTokens.saturate,
    0.072 - 0.072 * EselGlassTokens.saturate,
    0,
    0,
    0.213 - 0.213 * EselGlassTokens.saturate,
    0.715 - 0.715 * EselGlassTokens.saturate,
    0.072 + 0.928 * EselGlassTokens.saturate,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);

  @override
  Widget build(BuildContext context) {
    final highContrast = MediaQuery.maybeOf(context)?.highContrast ?? false;
    final radius = BorderRadius.circular(borderRadius);

    if (solid || highContrast) {
      return Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: EselGlassTokens.fallback,
          borderRadius: radius,
          border: border,
          boxShadow: const [floatShadow],
        ),
        child: child,
      );
    }

    return CustomPaint(
      painter: _OuterShadowPainter(radius),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.compose(
            outer: saturate,
            inner: ImageFilter.blur(
              sigmaX: EselGlassTokens.blurSigma,
              sigmaY: EselGlassTokens.blurSigma,
            ),
          ),
          child: Container(
            width: width,
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              color: EselGlassTokens.background,
              borderRadius: radius,
              border: border ?? Border.all(color: innerLine),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// CSS box-shadow처럼 그림자를 유리 바깥에만 그린다.
/// 안쪽까지 그리면 흐림 필터가 그림자를 함께 번지게 해 유리가 탁해진다.
class _OuterShadowPainter extends CustomPainter {
  final BorderRadius radius;
  const _OuterShadowPainter(this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = radius.toRRect(rect);
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect.inflate(80))
      ..addRRect(rrect);
    canvas
      ..save()
      ..clipPath(outside)
      ..drawRRect(
        rrect.shift(EselGlass.floatShadow.offset),
        EselGlass.floatShadow.toPaint(),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_OuterShadowPainter oldDelegate) =>
      oldDelegate.radius != radius;
}
