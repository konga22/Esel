import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import '../../../core/design/tokens.g.dart';
import '../../../core/ui/esel_paint_asset.dart';
import '../domain/models/face_box.dart';
import '../domain/models/face_layout_mode.dart';
import 'photo_ratio_builder.dart';

/// 얼굴 연출을 적용한 사진 한 장(P15). 디자인 생성기 `lib.mjs`의 cover·faceStroke·crop·
/// neckDown을 그대로 옮겨, 어떤 크기의 상자든 채운다.
///
/// - 그대로: object-fit cover(정렬은 [position]).
/// - 물감 한 획: 그 사람 색 물감이 눈 위를 -10° 기울여 가린다. 폭은 얼굴 폭의 2.15배.
/// - 제호 뒤로: 사진을 1.9배로 키워 얼굴을 위쪽 17% 높이(제호 자리)로 옮긴다. 제호는
///   화면이 이 위에 얹어서 얼굴을 덮는다(제호를 옮기지 않는다).
/// - 목 아래: 턱 아래부터 상자를 채우도록 키우고 자른다.
class CoverPhoto extends StatelessWidget {
  final ImageProvider image;

  /// 사진 세로/가로. null이면 사진을 읽어 정한다(내가 고른 사진).
  final double? photoRatio;
  final FaceBox face;
  final FaceLayoutMode mode;
  final Set<FaceLayoutMode>? effects;
  final EselPaint paint;

  /// object-position. (0.5, 0.5)이 가운데.
  final Offset position;
  final String? semanticLabel;

  const CoverPhoto({
    super.key,
    required this.image,
    this.photoRatio,
    required this.face,
    required this.mode,
    this.effects,
    required this.paint,
    this.position = const Offset(0.5, 0.5),
    this.semanticLabel,
  });

  static const double paintToFace = 2.15;
  static const double behindZoom = 1.9;
  static const double behindFaceTop = 0.17;

  /// 상자(w×h) 안에서 사진이 놓일 자리.
  static Rect photoRect({
    required Size box,
    required double photoRatio,
    required FaceBox face,
    required FaceLayoutMode mode,
    Offset position = const Offset(0.5, 0.5),
  }) {
    final w = box.width, h = box.height, r = photoRatio;
    double clampX(double v, double dw) => v.clamp(math.min(0.0, w - dw), 0.0);
    double clampY(double v, double dh) => v.clamp(math.min(0.0, h - dh), 0.0);
    switch (mode) {
      case FaceLayoutMode.behindLogo:
        final dw = w * behindZoom;
        final dh = dw * r;
        return Rect.fromLTWH(
          clampX(w / 2 - face.x * dw, dw),
          clampY(h * behindFaceTop - face.y * dh, dh),
          dw,
          dh,
        );
      case FaceLayoutMode.belowNeck:
        // 턱 = 얼굴 가운데 + 얼굴 폭 × 0.78.
        double below(double dw) =>
            dw * r - (face.y * dw * r + face.width * dw * 0.78);
        final room = below(w);
        // 확대 상한/세로 위치 보정으로 턱을 다시 화면 안에 내리지 않는다.
        // 턱 아래 사진이 전혀 없으면 빈 배경을 남긴다(얼굴을 노출하지 않는다).
        final k = room <= 0 ? 1.0 : math.max(1.0, (h + 2) / room);
        final dw = w * k;
        final dh = dw * r;
        final chin = face.y * dh + face.width * dw * 0.78;
        return Rect.fromLTWH(clampX(w / 2 - face.x * dw, dw), -chin, dw, dh);
      case FaceLayoutMode.original:
      case FaceLayoutMode.paintStroke:
        final dw = math.max(w, h / r);
        final dh = dw * r;
        return Rect.fromLTWH(
          -(dw - w) * position.dx,
          -(dh - h) * position.dy,
          dw,
          dh,
        );
    }
  }

  /// 물감 한 획의 자리(회전 전 상자). 폭 = 얼굴 폭 × 2.15, 높이 = 폭 / 2.
  static Rect strokeRect(Rect photo, FaceBox face) {
    final fx = photo.left + face.x * photo.width;
    final fy = photo.top + face.y * photo.height;
    final fwPx = face.width * photo.width;
    final pw = fwPx * paintToFace;
    return Rect.fromLTWH(fx - pw / 2, fy - fwPx * 0.12 - pw / 4, pw, pw / 2);
  }

  @override
  Widget build(BuildContext context) {
    final ratio = photoRatio;
    if (ratio != null) return _build(ratio);
    return PhotoRatioBuilder(
      image: image,
      builder: (context, resolved) => _build(resolved),
    );
  }

  Widget _build(double ratio) {
    final widget = this;
    final face = widget.face;
    final effects = widget.effects ?? {widget.mode};
    final mode = faceCropMode(effects);
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        final rect = CoverPhoto.photoRect(
          box: size,
          photoRatio: ratio,
          face: face,
          mode: mode,
          position: widget.position,
        );
        final stroke = CoverPhoto.strokeRect(rect, face);
        return ClipRect(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned.fill(child: ColoredBox(color: EselColors.photo)),
              Positioned.fromRect(
                rect: rect,
                child: Image(
                  image: widget.image,
                  fit: BoxFit.fill,
                  semanticLabel: widget.semanticLabel,
                  errorBuilder: (_, _, _) =>
                      const ColoredBox(color: EselColors.photo),
                ),
              ),
              if (effects.contains(FaceLayoutMode.paintStroke))
                Positioned.fromRect(
                  rect: stroke,
                  child: Transform.rotate(
                    angle: -10 * math.pi / 180,
                    child: ExcludeSemantics(
                      child: EselPaintAsset(
                        paint: widget.paint,
                        width: stroke.width,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
