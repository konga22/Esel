import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import '../design/tokens.g.dart';

/// 디자인은 393×852 휴대폰 화면 기준이다. 넓은 창(웹·데스크톱)에서는 화면을 늘리지 않고
/// 가운데 휴대폰 크기로 묶어, 휴대폰과 같은 비율의 표지·캡슐이 보이게 한다.
class EselPhoneFrame extends StatelessWidget {
  final Widget child;
  const EselPhoneFrame({super.key, required this.child});

  static const double wideFrom = 600;
  static const Size maxSize = Size(430, 932);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width < wideFrom) return child;
    final size = Size(
      maxSize.width,
      math.min(maxSize.height, media.size.height),
    );
    return ColoredBox(
      color: EselColors.photo,
      child: Center(
        child: SizedBox.fromSize(
          size: size,
          child: MediaQuery(
            data: media.copyWith(size: size),
            child: ClipRect(child: child),
          ),
        ),
      ),
    );
  }
}
