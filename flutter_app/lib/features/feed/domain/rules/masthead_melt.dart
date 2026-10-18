/// P16 표지 사인의 스크롤 연출. 디자인 생성기 `scroll.mjs`(eselScroll·eselPaint)를 옮겼다.
///
/// - 표지는 첫 장만. 아래로 내리면 사인이 표지와 함께 올라간다(300px 넘으면 숨김).
/// - 위로 48px 올리면 작은 로고(유리 알약)가 나타나고, 아래로 18px 내리면 숨는다.
/// - 맨 위 360px 안에서는 작은 로고가 스크롤에 맞춰 커지며 사인 자리로 녹아든다
///   (크기 0.14 → 1, smoothstep, 알약은 진행 18% 안에 사라짐).
/// 값은 `harness.json.feedPolicy.mastheadScroll`과 같다.
enum MastheadMode { cover, float }

/// 한 프레임의 사인·작은 로고 모습.
class MastheadFrame {
  /// 사인의 세로 이동(px)과 크기.
  final double translateY;
  final double scale;
  final double opacity;

  /// 작은 로고의 점(Esel.)과 유리 알약.
  final double dot;
  final double pill;
  final double pillShift;

  /// 0이면 표지 위 사인 모습, 1이면 작은 로고 모습(색을 섞는 데 쓴다).
  final double toLogo;

  const MastheadFrame({
    required this.translateY,
    required this.scale,
    required this.opacity,
    required this.dot,
    required this.pill,
    required this.pillShift,
    required this.toLogo,
  });

  bool get pillVisible => pill > 0.5;
}

class MastheadMelt {
  static const double meltZone = 360;
  static const double showUp = 48;
  static const double hideDown = 18;
  static const double smallScale = 0.14;

  /// 사인 가운데에서 작은 로고 가운데까지(디자인: 사인 top 80 + 90, 알약 top 50 + 23).
  static const double pillOffset = -97;

  /// 표지 모드에서 사인을 지우는 지점.
  static const double hideAt = 300;

  MastheadMode _mode = MastheadMode.cover;
  double _y = 0;
  int _dir = 0;
  double _acc = 0;

  MastheadMode get mode => _mode;
  double get offset => _y;

  /// 스크롤 위치가 바뀔 때 부른다. 모드가 바뀌었으면 true(짧게 애니메이션한다).
  bool update(double raw) {
    final y = raw < 0 ? 0.0 : raw;
    final d = y - _y;
    _y = y;
    if (d != 0) {
      final dir = d > 0 ? 1 : -1;
      if (dir != _dir) {
        _dir = dir;
        _acc = 0;
      }
      _acc += d.abs();
    }
    var mode = _mode;
    if (y <= 1) {
      mode = MastheadMode.cover;
    } else if (mode == MastheadMode.cover &&
        y >= meltZone &&
        _dir < 0 &&
        _acc >= showUp) {
      mode = MastheadMode.float;
    } else if (mode == MastheadMode.float &&
        y >= meltZone &&
        _dir > 0 &&
        _acc >= hideDown) {
      mode = MastheadMode.cover;
    }
    final changed = mode != _mode;
    _mode = mode;
    return changed && y > 1;
  }

  /// 지금 모습. [calm]은 움직임 줄이기: 녹아들기 없이 맨 위에서 한 번에 바뀐다.
  MastheadFrame frame({bool calm = false}) {
    final y = _y;
    if (_mode == MastheadMode.cover) {
      if (y < hideAt) {
        return MastheadFrame(
          translateY: -y,
          scale: 1,
          opacity: 1,
          dot: 0,
          pill: 0,
          pillShift: 0,
          toLogo: 0,
        );
      }
      return const MastheadFrame(
        translateY: pillOffset - 12,
        scale: smallScale,
        opacity: 0,
        dot: 0,
        pill: 0,
        pillShift: -12,
        toLogo: 1,
      );
    }
    if (calm || y >= meltZone) {
      return const MastheadFrame(
        translateY: pillOffset,
        scale: smallScale,
        opacity: 1,
        dot: 1,
        pill: 1,
        pillShift: 0,
        toLogo: 1,
      );
    }
    double clamp(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);
    final p = 1 - y / meltZone;
    final e = p * p * (3 - 2 * p);
    return MastheadFrame(
      translateY: -y < pillOffset ? pillOffset : -y,
      scale: smallScale + (1 - smallScale) * e,
      opacity: 1,
      dot: 1 - clamp(p / 0.25),
      pill: 1 - clamp(p / 0.18),
      pillShift: 0,
      toLogo: 1 - e,
    );
  }
}
