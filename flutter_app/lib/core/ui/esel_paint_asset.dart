import 'package:flutter/widgets.dart';
import '../design/tokens.g.dart';
import '../design/typography.dart';

/// 12색 아크릴 물감 한 획(투명 배경 2:1). 색 이름은 [showLabel]로 물감 바로 옆에 둔다(P17).
///
/// 색은 [EselPaint] 하나로만 받는다. 문자열 키를 추측해 다른 색으로 바꾸지 않는다.
class EselPaintAsset extends StatelessWidget {
  final EselPaint paint;
  final double width;
  final bool showLabel;
  final TextStyle? labelStyle;

  const EselPaintAsset({
    super.key,
    required this.paint,
    this.width = 52.0,
    this.showLabel = false,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final info = EselPaints.of(paint);
    final height = width / 2.0;

    final imageWidget = Image.asset(
      info.assetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: info.color,
            borderRadius: BorderRadius.circular(height / 2),
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
        Flexible(
          child: Text(
            info.nameKo,
            style:
                labelStyle ??
                EselTypography.label(fontSize: 14.0, color: EselColors.ink),
          ),
        ),
      ],
    );
  }
}
