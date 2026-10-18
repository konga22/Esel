import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/design/tokens.g.dart';
import '../../../core/design/typography.dart';
import '../../../core/ui/esel_paint_asset.dart';
import '../../../core/time/service_date.dart';
import '../../drafts/data/local_library.dart';
import '../../publishing/domain/rules/publish_rule.dart';
import '../../drafts/domain/cover_draft.dart';
import '../domain/models/face_box.dart';
import '../domain/models/face_layout_mode.dart';
import 'cover_photo.dart';
import 'photo_ratio_builder.dart';

/// 내 표지 초안을 그린다(만들기 C6, 첫 캔버스 J5~J7, 스케치북). 얼굴 연출은 [CoverPhoto]가
/// 생성기 계산대로 그리고, 사인은 늘 위쪽에 둔다(P14·P15).
///
/// - 사인 뒤로: 사진을 키워 얼굴을 사인 높이로 올린다. 사인을 얼굴 쪽으로 옮기지 않는다.
/// - 그대로: 사인이 얼굴에 닿지 않게 사인을 줄인다. 그래도 닿으면 [plainMastheadTouchesFace].
class CoverPreview extends StatelessWidget {
  final CoverDraft draft;
  final bool editing;

  /// 얼굴을 찾는 동안에는 변형 전 사진을 보여 준다. 선택한 연출은 유지한다.
  final bool locatingFace;

  /// 표지에서 얼굴 가운데를 누른 자리(사진에 대한 비율).
  final ValueChanged<Offset>? onFacePosition;

  /// 사진 아래쪽 가운데의 짧은 안내(예: 위치 지정 중 "얼굴 가운데를 눌러 주세요").
  final String? hint;

  /// 표지 비율. null이면 주어진 상자를 채운다(첫 캔버스 전체 화면 등).
  final double? aspectRatio;

  /// false면 사진·얼굴 연출만 그리고 사인·문구는 화면이 따로 얹는다.
  final bool chrome;

  const CoverPreview({
    super.key,
    required this.draft,
    this.editing = false,
    this.locatingFace = false,
    this.onFacePosition,
    this.hint,
    this.aspectRatio = 3 / 4,
    this.chrome = true,
  });

  /// 사인 위치(표지 높이 비율)와 가장 작게 줄일 수 있는 비율.
  static const double mastheadTop = 0.04;
  static const double minMastheadScale = 0.5;

  static FaceBox faceOf(CoverDraft draft) =>
      FaceBox(draft.faceX, draft.faceY, draft.faceWidth);

  /// 그대로 연출에서 사인 글자 크기. 얼굴 윗부분(얼굴 폭의 0.7 위)에 닿지 않게 줄인다.
  static double plainMastheadSize(CoverDraft draft, Size box, {double? ratio}) {
    final title = draft.masthead.isEmpty ? 'Esel' : draft.masthead;
    final full =
        EselTypography.mastheadSize(title, box.width, max: box.width * .54) *
        draft.mastheadScale;
    if (draft.effectiveFaceEffects.isNotEmpty) return full;
    final rect = CoverPhoto.photoRect(
      box: box,
      photoRatio: ratio ?? 4 / 3,
      face: faceOf(draft),
      mode: FaceLayoutMode.original,
    );
    final faceTop =
        rect.top +
        draft.faceY * rect.height -
        draft.faceWidth * rect.width * 0.7;
    final room = faceTop - box.height * mastheadTop - 4;
    final fit = room / 0.9;
    return math.max(full * minMastheadScale, math.min(full, fit));
  }

  /// 그대로 연출에서 사인을 가장 작게 줄여도 얼굴에 닿는지. 편집 화면이 다른 연출을 권한다.
  static bool plainMastheadTouchesFace(
    CoverDraft draft,
    Size box, {
    double? ratio,
  }) {
    if (draft.effectiveFaceEffects.isNotEmpty) return false;
    final rect = CoverPhoto.photoRect(
      box: box,
      photoRatio: ratio ?? 4 / 3,
      face: faceOf(draft),
      mode: FaceLayoutMode.original,
    );
    final faceTop =
        rect.top +
        draft.faceY * rect.height -
        draft.faceWidth * rect.width * 0.7;
    final size = plainMastheadSize(draft, box, ratio: ratio);
    return box.height * mastheadTop + size * 0.9 > faceTop;
  }

  @override
  Widget build(BuildContext context) {
    final ratio = aspectRatio;
    final cover = draft.photoPath.isEmpty
        ? LayoutBuilder(builder: (context, c) => _buildCover(c, 4 / 3))
        : PhotoRatioBuilder(
            image: localPhotoProvider(draft.photoPath),
            builder: (context, photoRatio) => LayoutBuilder(
              builder: (context, c) => _buildCover(c, photoRatio),
            ),
          );
    return ratio == null
        ? cover
        : AspectRatio(aspectRatio: ratio, child: cover);
  }

  Widget _buildCover(BoxConstraints c, double photoRatio) {
    final box = Size(c.maxWidth, c.maxHeight);
    final effects = locatingFace
        ? <FaceLayoutMode>{}
        : draft.effectiveFaceEffects;
    final mode = faceCropMode(effects);
    final title = draft.masthead.isEmpty ? 'Esel' : draft.masthead;
    final face = faceOf(draft);
    final hasPhoto = draft.photoPath.isNotEmpty;
    // 편집 중 얼굴 표시와 탭 변환에 쓰는 지금 연출의 사진 자리.
    final rect = CoverPhoto.photoRect(
      box: box,
      photoRatio: photoRatio,
      face: face,
      mode: mode,
    );
    final canPlace = editing && hasPhoto && mode != FaceLayoutMode.belowNeck;

    void place(Offset local) {
      onFacePosition?.call(
        Offset(
          ((local.dx - rect.left) / rect.width).clamp(0.0, 1.0),
          ((local.dy - rect.top) / rect.height).clamp(0.0, 1.0),
        ),
      );
    }

    return ClipRect(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: canPlace ? (d) => place(d.localPosition) : null,
        onPanUpdate: canPlace ? (d) => place(d.localPosition) : null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPhoto)
              CoverPhoto(
                image: localPhotoProvider(draft.photoPath),
                photoRatio: photoRatio,
                face: face,
                mode: mode,
                effects: effects,
                paint: draft.color,
              )
            else
              const ColoredBox(
                color: EselColors.paper,
                child: Center(
                  child: Icon(Icons.add_a_photo_outlined, size: 56),
                ),
              ),
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x66000000),
                      Colors.transparent,
                      Colors.transparent,
                      Color(0x8C000000),
                    ],
                    stops: [0, .45, .6, 1],
                  ),
                ),
              ),
            ),
            if (chrome && draft.issueNumber > 0)
              Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ESEL',
                      style: EselTypography.meta(
                        fontSize: 9,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${PublishRule.formatIssueNumber(draft.issueNumber)} · ${ServiceDate.tryParse(draft.publishedOn)?.shortLabel ?? ''}',
                      style: EselTypography.meta(
                        fontSize: 9,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            if (chrome)
              Positioned(
                top: box.height * mastheadTop + 10,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                        style: EselTypography.masthead(
                          fontSize: plainMastheadSize(
                            draft,
                            box,
                            ratio: photoRatio,
                          ),
                          color: draft.whiteTitle
                              ? Colors.white
                              : EselColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (chrome)
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: IgnorePointer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EselPaintAsset(
                        paint: draft.color,
                        width: 32,
                        showLabel: true,
                        labelStyle: EselTypography.body(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                      if (draft.caption.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          draft.caption,
                          style: EselTypography.body(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            if (hint case final text?)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: IgnorePointer(
                  child: Center(
                    child: DecoratedBox(
                      key: const Key('cover-preview-hint'),
                      decoration: BoxDecoration(
                        color: const Color(0xB3000000),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        // 좁은 표지에서도 한 줄로, 넘치면 글자를 줄인다.
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.touch_app_outlined,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                text,
                                maxLines: 1,
                                softWrap: false,
                                style: EselTypography.body(
                                  fontSize: 12.5,
                                  color: Colors.white,
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
            // 얼굴 자리 표시: 가운데와 얼굴 폭. 위치를 정하는 동안에만.
            if (canPlace && !draft.faceConfirmed && !locatingFace)
              Positioned(
                left:
                    rect.left +
                    face.x * rect.width -
                    face.width * rect.width / 2,
                top:
                    rect.top +
                    face.y * rect.height -
                    face.width * rect.width / 2,
                width: face.width * rect.width,
                height: face.width * rect.width,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
