import '../../../media/domain/models/media_photo.dart';
import '../../../media/presentation/remote_media_photo.dart';
import '../../../issue/presentation/canvas_photo.dart';
import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/ui/esel_paint_asset.dart';
import '../../../../core/ui/esel_pressable.dart';
import '../../../issue/domain/models/public_issue.dart';
import '../../../issue/presentation/issue_photo.dart';
import '../../../media/presentation/cover_photo.dart';

/// 지면의 반응 버튼 상태와 동작. 숫자는 그리지 않는다(P18). 로그인 전에는 누르면 로그인 시트.
class PageActions {
  final bool liked;
  final bool scrapped;
  final bool subscribed;
  final VoidCallback onLike;
  final VoidCallback onScrap;
  final VoidCallback onSubscribe;
  final VoidCallback onOpenSpread;
  final VoidCallback onOpenAuthor;
  final VoidCallback onOpenStand;

  const PageActions({
    required this.liked,
    required this.scrapped,
    required this.subscribed,
    required this.onLike,
    required this.onScrap,
    required this.onSubscribe,
    required this.onOpenSpread,
    required this.onOpenAuthor,
    required this.onOpenStand,
  });
}

/// C1·J1 오늘의 표지(피드의 첫 장). 큰 사인 "Esel"은 화면이 스크롤 레이어로 따로 얹는다(P16).
class TodayCover extends StatelessWidget {
  final PublicIssue issue;
  final int sameColorCount;
  final double height;
  final double chromeTop;

  /// 위쪽 줄 왼쪽(전체/구독 또는 "오늘의 표지").
  final Widget leading;

  /// 위쪽 줄 오른쪽 `Nº 249 · 2026. 9. 6.`
  final String meta;
  final PageActions actions;

  const TodayCover({
    super.key,
    required this.issue,
    required this.sameColorCount,
    required this.height,
    required this.chromeTop,
    required this.leading,
    required this.meta,
    required this.actions,
  });

  Color get topColor => issue.inkMasthead ? EselColors.ink : Colors.white;

  @override
  Widget build(BuildContext context) {
    final info = EselPaints.of(issue.color);
    // 같은 색 인원을 모르면(서버가 아직 주지 않음) 숫자 없이 색 이름만. 표지 자신이 있어 0명일 수는 없다.
    final sameColorLabel = sameColorCount > 0
        ? '${info.nameKo} · 같은 색 $sameColorCount명'
        : info.nameKo;
    const white = Colors.white;
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: actions.onOpenSpread,
            child: mediaPhotoId(issue.photo) != null
                ? RemoteMediaPhoto(
                    id: mediaPhotoId(issue.photo)!,
                    semanticLabel: issue.alt,
                  )
                : CoverPhoto(
                    image: issuePhotoProvider(issue.photo),
                    photoRatio: issue.photoRatio,
                    face: issue.face,
                    mode: issue.faceMode,
                    effects: issue.faceEffects,
                    paint: issue.color,
                    position: const Offset(0.58, 0.5),
                    semanticLabel: issue.alt,
                  ),
          ),
          if (!issue.inkMasthead)
            const _Shade(top: true, height: 300, alpha: 0.4),
          const _Shade(top: false, height: 460, alpha: 0.72),
          Semantics(
            header: true,
            label: 'Esel 오늘의 표지',
            child: const SizedBox.shrink(),
          ),
          Positioned(
            left: 14,
            right: 20,
            top: chromeTop,
            height: 44,
            child: DefaultTextStyle(
              style: EselTypography.label(
                fontSize: 13,
                color: topColor,
              ).copyWith(letterSpacing: 0.04 * 13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  leading,
                  Flexible(
                    child: Text(
                      meta,
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      style: EselTypography.label(
                        fontSize: 12,
                        color: topColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 8,
            bottom: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: EselPressable(
                        semanticsLabel: '${issue.masthead}의 잡지',
                        onTap: actions.onOpenAuthor,
                        child: Text(
                          issue.masthead,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          style: EselTypography.name(
                            fontSize: 76,
                            color: white,
                          ).copyWith(height: 0.9, letterSpacing: -0.03 * 76),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _SubscribePill(
                      subscribed: actions.subscribed,
                      onTap: actions.onSubscribe,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                EselPressable(
                  semanticsLabel: '$sameColorLabel 팔레트',
                  onTap: actions.onOpenStand,
                  child: SizedBox(
                    height: 44,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EselPaintAsset(paint: issue.color, width: 60),
                        const SizedBox(width: 8),
                        Text(
                          sameColorLabel,
                          style: EselTypography.label(color: white),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 18, color: white),
                      ],
                    ),
                  ),
                ),
                Text(issue.caption, style: EselTypography.body(color: white)),
                const SizedBox(height: 2),
                Transform.translate(
                  offset: const Offset(-12, 0),
                  child: Row(
                    children: [
                      _Stat(
                        icon: actions.liked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        label: '좋아요',
                        selected: actions.liked,
                        color: white,
                        onTap: actions.onLike,
                      ),
                      _Stat(
                        icon: Icons.chat_bubble_outline,
                        label: '한 줄',
                        color: white,
                        onTap: actions.onOpenSpread,
                      ),
                      _Stat(
                        icon: actions.scrapped
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        label: '스크랩',
                        selected: actions.scrapped,
                        color: white,
                        onTap: actions.onScrap,
                      ),
                      const Spacer(),
                      EselPressable(
                        semanticsLabel: '자세히 보기',
                        onTap: actions.onOpenSpread,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '자세히 보기',
                                style: EselTypography.label(color: white),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.keyboard_arrow_up,
                                size: 20,
                                color: white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// C7 안쪽 지면. 사인 없이 쪽 번호·시각, 전체 폭 사진(500), 이름 줄, 캡션 한 줄.
class InnerPage extends StatelessWidget {
  final PublicIssue issue;

  /// 쪽 번호(표지가 01).
  final int pageNumber;
  final PageActions actions;

  const InnerPage({
    super.key,
    required this.issue,
    required this.pageNumber,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final info = EselPaints.of(issue.color);
    final folio = EselTypography.name(fontSize: 16);
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(pageNumber.toString().padLeft(2, '0'), style: folio),
                Text(issue.timeLabel, style: folio),
              ],
            ),
          ),
          GestureDetector(
            onTap: actions.onOpenSpread,
            child: SizedBox(
              height: 500,
              child: CanvasPhoto(
                issue: issue,
                onTag: (_) => actions.onOpenSpread(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 6, 0),
            child: Row(
              children: [
                EselPressable(
                  semanticsLabel: '${issue.masthead}의 잡지',
                  onTap: actions.onOpenAuthor,
                  child: Text(
                    issue.masthead,
                    style: EselTypography.label(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 8),
                EselPaintAsset(paint: issue.color, width: 54),
                const SizedBox(width: 8),
                Text(
                  info.nameKo,
                  style: EselTypography.body(
                    fontSize: 13,
                    color: EselColors.muted,
                  ),
                ),
                const Spacer(),
                _Stat(
                  icon: actions.liked ? Icons.favorite : Icons.favorite_border,
                  label: '좋아요',
                  selected: actions.liked,
                  color: EselColors.ink,
                  onTap: actions.onLike,
                ),
                _Stat(
                  icon: actions.scrapped
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  label: '스크랩',
                  selected: actions.scrapped,
                  color: EselColors.ink,
                  onTap: actions.onScrap,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(issue.caption, style: EselTypography.body()),
          ),
        ],
      ),
    );
  }
}

/// 올리기 전에는 오늘 후보 색 표지가 피드에서 빠졌다는 안내(P01). 한 번만 넣는다.
/// 손실 문구·카운트다운은 쓰지 않는다.
class HeldBackNotice extends StatelessWidget {
  final List<EselPaint> candidates;
  final VoidCallback onMakeTodayIssue;

  const HeldBackNotice({
    super.key,
    required this.candidates,
    required this.onMakeTodayIssue,
  });

  @override
  Widget build(BuildContext context) {
    final names = candidates.map((c) => EselPaints.of(c).nameKo).join('·');
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 30),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(EselRadius.colorPick),
        border: Border.all(color: EselColors.hairline),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_outline, size: 20, color: EselColors.ink),
          const SizedBox(height: 6),
          Text(
            '올리면 함께 펼쳐집니다',
            textAlign: TextAlign.center,
            style: EselTypography.heading(fontSize: 22).copyWith(height: 1.2),
          ),
          const SizedBox(height: 4),
          Text(
            '오늘의 $names 표지는 오늘의 캔버스를 올리면 여기에 함께 꽂혀요.',
            textAlign: TextAlign.center,
            style: EselTypography.body(fontSize: 13, color: EselColors.muted),
          ),
          const SizedBox(height: 12),
          EselPressable(
            semanticsLabel: '오늘의 캔버스 만들기',
            onTap: onMakeTodayIssue,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 26),
              decoration: BoxDecoration(
                color: EselColors.ink,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 18, color: EselColors.paper),
                  const SizedBox(width: 6),
                  Text(
                    '오늘의 캔버스 만들기',
                    style: EselTypography.label(
                      fontSize: 15,
                      color: EselColors.paper,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscribePill extends StatelessWidget {
  final bool subscribed;
  final VoidCallback onTap;

  const _SubscribePill({required this.subscribed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return EselPressable(
      semanticsLabel: subscribed ? '구독 중' : '구독',
      onTap: onTap,
      child: SizedBox(
        height: 44,
        child: Center(
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: subscribed ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Text(
              subscribed ? '구독 중' : '구독',
              style: EselTypography.label(
                fontSize: 13,
                color: subscribed ? EselColors.ink : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool? selected;

  const _Stat({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: EselPressable(
        semanticsLabel: label,
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, size: 23, color: color),
        ),
      ),
    );
  }
}

class _Shade extends StatelessWidget {
  final bool top;
  final double height;
  final double alpha;

  const _Shade({required this.top, required this.height, required this.alpha});

  @override
  Widget build(BuildContext context) {
    final dark = Colors.black.withValues(alpha: alpha);
    return Align(
      alignment: top ? Alignment.topCenter : Alignment.bottomCenter,
      child: IgnorePointer(
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: top
                    ? [dark, Colors.transparent]
                    : [Colors.transparent, dark],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 홈 피드 사이 카드로 오는 이번 주 주제·전시(10-18, 마이페이지에서 빠졌다).
class FeedFeature {
  final String eyebrow;
  final String title;
  final String sub;
  final VoidCallback onTap;
  const FeedFeature({
    required this.eyebrow,
    required this.title,
    required this.sub,
    required this.onTap,
  });
}

/// 흰 카드: 작은 머리말, 세리프 제목, 한 줄 설명, 사진 석 장(지금 내가 볼 수 있는 것만, P01).
class FeatureCard extends StatelessWidget {
  final FeedFeature feature;
  final List<PublicIssue> photos;
  const FeatureCard({super.key, required this.feature, required this.photos});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 8, 18, 26),
    child: EselPressable(
      semanticsLabel: '${feature.eyebrow} · ${feature.title}',
      onTap: feature.onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFECECE8)),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(feature.eyebrow, style: EselTypography.meta(fontSize: 11)),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(right: 28),
                  child: Text(
                    feature.title,
                    style: EselTypography.heading(fontSize: 26),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feature.sub,
                  style: EselTypography.body(
                    fontSize: 13,
                    color: EselColors.muted,
                  ),
                ),
                if (photos.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  // 목업은 104×138 석 장. 좁은 폭에서는 같은 비율로 줄인다.
                  Row(
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Flexible(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 104),
                            child: AspectRatio(
                              aspectRatio: 104 / 138,
                              child: i < photos.length
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: ExcludeSemantics(
                                        child: CanvasPhoto(
                                          issue: photos[i],
                                          thumbnail: true,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
            const Positioned(
              top: 0,
              right: 0,
              child: Icon(Icons.arrow_forward, size: 18),
            ),
          ],
        ),
      ),
    ),
  );
}
