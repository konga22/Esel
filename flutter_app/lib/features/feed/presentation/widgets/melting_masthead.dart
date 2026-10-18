import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/ui/esel_glass.dart';
import '../../domain/rules/masthead_melt.dart';

/// 스크롤에 붙어 움직이는 앱 표지 사인 "Esel"과 작은 로고(유리 알약). 표지 피드(C7)와
/// 비로그인 첫 화면(J1)이 같이 쓴다. 사인은 장식이라 스크린 리더에서 뺀다.
class MeltingMasthead extends StatefulWidget {
  /// 표지와 안쪽 지면을 담은 스크롤.
  final ScrollController controller;

  /// 표지 사진 위의 사인 색(먹 또는 흰).
  final Color coverColor;

  /// 화면 위쪽 기준선(상태 표시줄 아래). 디자인 393×852에서 48.
  final double chromeTop;
  final VoidCallback onTapLogo;

  const MeltingMasthead({
    super.key,
    required this.controller,
    required this.coverColor,
    required this.chromeTop,
    required this.onTapLogo,
  });

  @override
  State<MeltingMasthead> createState() => _MeltingMastheadState();
}

class _MeltingMastheadState extends State<MeltingMasthead>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: EselMotion.smallLogo,
  );
  final MastheadMelt _melt = MastheadMelt();
  late MastheadFrame _from;
  late MastheadFrame _to;

  bool get _calm => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _from = _to = _melt.frame();
    widget.controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(MeltingMasthead oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    _anim.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.controller.hasClients) return;
    final modeChanged = _melt.update(widget.controller.offset);
    final next = _melt.frame(calm: _calm);
    setState(() {
      // 모드가 바뀔 때만 200ms로 넘어가고(작은 로고 나타남·숨김), 그 밖에는 스크롤을 그대로 따른다.
      if (modeChanged && !_calm) {
        _from = _current;
        _to = next;
        _anim.forward(from: 0);
      } else {
        _anim.value = 1;
        _from = _to = next;
      }
    });
  }

  MastheadFrame get _current {
    final t = EselMotion.easeOut.transform(_anim.value);
    double lerp(double a, double b) => a + (b - a) * t;
    return MastheadFrame(
      translateY: lerp(_from.translateY, _to.translateY),
      scale: lerp(_from.scale, _to.scale),
      opacity: lerp(_from.opacity, _to.opacity),
      dot: lerp(_from.dot, _to.dot),
      pill: lerp(_from.pill, _to.pill),
      pillShift: lerp(_from.pillShift, _to.pillShift),
      toLogo: lerp(_from.toLogo, _to.toLogo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final size = EselTypography.mastheadSize('Esel', width);
    final top = widget.chromeTop;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final f = _current;
        final color = Color.lerp(widget.coverColor, EselColors.ink, f.toLogo)!;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // 작은 로고(유리 알약). 누르면 맨 위 표지로.
            Positioned(
              left: 0,
              right: 0,
              top: top + 2 + f.pillShift,
              child: Center(
                child: IgnorePointer(
                  ignoring: !f.pillVisible,
                  child: Opacity(
                    opacity: f.pill.clamp(0.0, 1.0),
                    child: Semantics(
                      button: true,
                      label: '맨 위 표지로 돌아가기',
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: widget.onTapLogo,
                        behavior: HitTestBehavior.opaque,
                        child: const EselGlass(
                          width: 108,
                          height: 46,
                          borderRadius: 23,
                          child: SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // 사인. 알약 위에서는 0.14배로 줄어 로고가 된다.
            Positioned(
              left: 0,
              right: 0,
              top: top + 32,
              height: 180,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Opacity(
                    opacity: f.opacity.clamp(0.0, 1.0),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..translateByDouble(0, f.translateY, 0, 1)
                        ..scaleByDouble(f.scale, f.scale, 1, 1),
                      child: Padding(
                        padding: EdgeInsets.only(right: size * 0.05),
                        child: Center(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Text(
                                'Esel',
                                maxLines: 1,
                                softWrap: false,
                                style: EselTypography.masthead(
                                  fontSize: size,
                                  color: color,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: FractionalTranslation(
                                  translation: const Offset(1, 0),
                                  child: Text(
                                    '.',
                                    style: EselTypography.masthead(
                                      fontSize: size,
                                      color: EselColors.dot.withValues(
                                        alpha: f.dot.clamp(0.0, 1.0),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
