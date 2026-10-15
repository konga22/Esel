import 'package:flutter/material.dart';
import '../../../core/design/tokens.g.dart';
import '../../../core/design/typography.dart';
import '../../../core/ui/esel_paint_asset.dart';
import '../../drafts/data/local_library.dart';
import '../../drafts/domain/cover_draft.dart';
import '../domain/models/face_layout_mode.dart';

class CoverPreview extends StatelessWidget {
  final CoverDraft draft;
  final bool editing;
  final ValueChanged<Offset>? onFacePosition;

  /// 표지 비율. null이면 주어진 상자를 채운다(창간호 전체 화면 등).
  final double? aspectRatio;

  /// false면 사진·얼굴 연출만 그리고 제호·문구는 화면이 따로 얹는다.
  final bool chrome;
  const CoverPreview({
    super.key,
    required this.draft,
    this.editing = false,
    this.onFacePosition,
    this.aspectRatio = 3 / 4,
    this.chrome = true,
  });
  @override
  Widget build(BuildContext context) {
    final ratio = aspectRatio;
    final cover = _buildCover();
    return ratio == null
        ? cover
        : AspectRatio(aspectRatio: ratio, child: cover);
  }

  Widget _buildCover() => LayoutBuilder(
    builder: (context, c) {
      final w = c.maxWidth, h = c.maxHeight;
      final mode = draft.faceMode;
      final title = draft.masthead.isEmpty ? 'Esel' : draft.masthead;
      final titleY = mode == FaceLayoutMode.behindLogo
          ? (draft.faceY - .08).clamp(0, .8)
          : (mode == FaceLayoutMode.original && draft.faceY < .35 ? .72 : .05);
      final image = draft.photoPath.isEmpty
          ? const ColoredBox(
              color: EselColors.paper,
              child: Center(child: Icon(Icons.add_a_photo_outlined, size: 56)),
            )
          : Image(
              image: localPhotoProvider(draft.photoPath),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const Center(child: Text('사진을 다시 골라 주세요.')),
            );
      return ClipRect(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: editing && mode != FaceLayoutMode.belowNeck
              ? (d) => onFacePosition?.call(
                  Offset(
                    (d.localPosition.dx / w).clamp(0, 1),
                    (d.localPosition.dy / h).clamp(0, 1),
                  ),
                )
              : null,
          onPanUpdate: editing && mode != FaceLayoutMode.belowNeck
              ? (d) => onFacePosition?.call(
                  Offset(
                    (d.localPosition.dx / w).clamp(0, 1),
                    (d.localPosition.dy / h).clamp(0, 1),
                  ),
                )
              : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (mode == FaceLayoutMode.belowNeck)
                Positioned(
                  top: -h * draft.cropTop / (1 - draft.cropTop),
                  left: 0,
                  right: 0,
                  height: h / (1 - draft.cropTop),
                  child: image,
                )
              else
                image,
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black54,
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black87,
                    ],
                    stops: [0, .3, .65, 1],
                  ),
                ),
              ),
              if (mode == FaceLayoutMode.paintStroke)
                Positioned(
                  left: (draft.faceX * w - w * draft.maskSize / 2).clamp(
                    0,
                    w * (1 - draft.maskSize),
                  ),
                  top: (draft.faceY * h - w * draft.maskSize / 4).clamp(
                    0,
                    h - w * draft.maskSize / 2,
                  ),
                  child: Transform.rotate(
                    angle: -.1745,
                    child: EselPaintAsset(
                      paint: draft.color,
                      width: w * draft.maskSize,
                    ),
                  ),
                ),
              if (chrome)
                Positioned(
                  top: h * titleY,
                  left: 16,
                  right: 16,
                  child: SizedBox(
                    height: h * .13,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Text(
                        title,
                        style: EselTypography.mastheadHero.copyWith(
                          fontSize: 80,
                          color: draft.whiteTitle
                              ? Colors.white
                              : EselColors.ink,
                          shadows: const [
                            Shadow(color: Colors.black54, blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (chrome && draft.issueNumber > 0)
                Positioned(
                  top: 12,
                  left: 20,
                  right: 20,
                  child: Text(
                    'ESEL · Nº ${draft.issueNumber.toString().padLeft(3, '0')} · ${draft.publishedOn}',
                    style: EselTypography.meta(color: Colors.white),
                  ),
                ),
              if (chrome)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EselPaintAsset(
                        paint: draft.color,
                        width: 32,
                        showLabel: true,
                        labelStyle: EselTypography.bodySmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        draft.caption,
                        style: EselTypography.bodyMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              if (editing &&
                  !draft.faceConfirmed &&
                  mode != FaceLayoutMode.belowNeck)
                Positioned(
                  left: draft.faceX * w - 20,
                  top: draft.faceY * h - 20,
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
