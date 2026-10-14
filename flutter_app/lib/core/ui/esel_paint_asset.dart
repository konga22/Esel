import 'package:flutter/widgets.dart';
import '../design/tokens.g.dart';
import '../design/typography.dart';

class EselPaintAsset extends StatelessWidget {
  final EselPaint? paint;
  final String? colorKey;
  final double width;
  final double? size;
  final bool showLabel;
  final TextStyle? labelStyle;

  const EselPaintAsset({
    super.key,
    this.paint,
    this.colorKey,
    this.width = 52.0,
    this.size,
    this.showLabel = false,
    this.labelStyle,
  });

  static EselPaint _resolvePaint(EselPaint? paint, String? colorKey) {
    if (paint != null) return paint;
    if (colorKey != null) {
      final normalized = colorKey.replaceAll('-', '').toLowerCase();
      if (normalized.contains('powder')) return EselPaint.powder;
      if (normalized.contains('sage')) return EselPaint.sage;
      if (normalized.contains('butter')) return EselPaint.butter;
      if (normalized.contains('coral')) return EselPaint.coral;
      if (normalized.contains('lilac') || normalized.contains('lavender')) return EselPaint.lilac;
      if (normalized.contains('terracotta')) return EselPaint.terracotta;
      if (normalized.contains('burgundy')) return EselPaint.burgundy;
      if (normalized.contains('olive')) return EselPaint.olive;
      if (normalized.contains('cream') || normalized.contains('sand')) return EselPaint.cream;
      if (normalized.contains('charcoal')) return EselPaint.charcoal;
      if (normalized.contains('camel')) return EselPaint.camel;
      if (normalized.contains('cobalt')) return EselPaint.cobalt;
    }
    return EselPaint.powder;
  }

  @override
  Widget build(BuildContext context) {
    final actualPaint = _resolvePaint(paint, colorKey);
    final info = EselPaints.of(actualPaint);
    final actualWidth = size ?? width;
    final actualHeight = actualWidth / 2.0;

    final imageWidget = Image.asset(
      info.assetPath,
      width: actualWidth,
      height: actualHeight,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: actualWidth,
          height: actualHeight,
          decoration: BoxDecoration(
            color: info.color,
            borderRadius: BorderRadius.circular(actualHeight / 2),
          ),
        );
      },
    );

    if (!showLabel) return imageWidget;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        imageWidget,
        const SizedBox(width: 8.0),
        Text(
          info.nameKo,
          style: labelStyle ?? EselTypography.label(fontSize: 14.0, color: EselColors.ink),
        ),
      ],
    );
  }
}
