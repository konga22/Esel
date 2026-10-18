import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/ui/esel_pressable.dart';
import '../../../issue/domain/models/public_issue.dart';
import '../../../reactions/presentation/controllers/reactions_controller.dart';
import '../../../stand/domain/rules/same_color_rule.dart';
import '../controllers/feed_controller.dart';
import '../widgets/feed_pages.dart';
import '../widgets/melting_masthead.dart';

/// C1·C7 표지 피드. 표지는 첫 장만(P16): 사인 "Esel"은 첫 장에만 크게 있고, 내리면 표지와
/// 함께 올라가며, 위로 48px 올리면 작은 로고, 맨 위 360px에서 사인로 녹아든다.
/// 그 아래는 사인 없는 안쪽 지면이다. 반응 숫자는 그리지 않는다(P18).
class FeedScreen extends StatefulWidget {
  final FeedController feedController;
  final ReactionsController reactionsController;
  final SameColorViewer viewer;
  final void Function(String ownerId) onOpenAuthorShelf;
  final void Function(PublicIssue issue) onOpenIssue;
  final void Function(EselPaint color) onOpenStand;
  final VoidCallback onMakeTodayIssue;

  /// 이번 주 주제·전시 카드. 없는 모드(서버)에서는 null이라 카드를 그리지 않는다.
  final FeedFeature? challenge;
  final FeedFeature? collection;

  const FeedScreen({
    super.key,
    required this.feedController,
    required this.reactionsController,
    required this.viewer,
    required this.onOpenAuthorShelf,
    required this.onOpenIssue,
    required this.onOpenStand,
    required this.onMakeTodayIssue,
    this.challenge,
    this.collection,
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ScrollController _scroll = ScrollController();

  void _configure() => widget.feedController.configure(
    viewer: widget.viewer,
    signedIn: true,
    subscribedOwnerIds: widget.reactionsController.subscribedOwnerIds,
  );

  @override
  void initState() {
    super.initState();
    _configure();
    widget.reactionsController.addListener(_configure);
  }

  @override
  void didUpdateWidget(FeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reactionsController != widget.reactionsController) {
      oldWidget.reactionsController.removeListener(_configure);
      widget.reactionsController.addListener(_configure);
    }
    _configure();
  }

  @override
  void dispose() {
    widget.reactionsController.removeListener(_configure);
    _scroll.dispose();
    super.dispose();
  }

  void _toTop() {
    if (!_scroll.hasClients) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(0);
    } else {
      _scroll.animateTo(
        0,
        duration: EselMotion.sheet,
        curve: EselMotion.drawer,
      );
    }
  }

  PageActions _actions(PublicIssue issue) {
    final rc = widget.reactionsController;
    return PageActions(
      liked: rc.isLiked(issue.id),
      scrapped: rc.isScrapped(issue.id),
      subscribed: rc.isSubscribed(issue.ownerId),
      onLike: () => rc.toggleLike(issue.id),
      onScrap: () => rc.toggleScrap(issue.id),
      onSubscribe: () => rc.toggleSubscription(issue.ownerId),
      onOpenSpread: () => widget.onOpenIssue(issue),
      onOpenAuthor: () => widget.onOpenAuthorShelf(issue.ownerId),
      onOpenStand: () => widget.onOpenStand(issue.color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fc = widget.feedController;
    return AnimatedBuilder(
      animation: Listenable.merge([fc, widget.reactionsController]),
      builder: (context, _) {
        final page = fc.page;
        final media = MediaQuery.of(context);
        final chromeTop = math.max(48.0, media.padding.top);
        final cover = page?.cover;
        return Scaffold(
          backgroundColor: EselColors.paper,
          body: page == null || cover == null
              ? _buildEmpty(page, chromeTop)
              : Stack(
                  children: [
                    ListView(
                      controller: _scroll,
                      padding: EdgeInsets.zero,
                      children: [
                        TodayCover(
                          issue: cover,
                          sameColorCount: page.sameColorCount(cover.color),
                          height: math.max(600.0, media.size.height - 52),
                          chromeTop: chromeTop,
                          leading: _tabs(
                            cover.inkMasthead ? EselColors.ink : Colors.white,
                          ),
                          meta:
                              'Nº ${page.appIssueNumber} · ${page.date.label}',
                          actions: _actions(cover),
                        ),
                        for (final (i, issue) in page.innerPages.indexed) ...[
                          InnerPage(
                            issue: issue,
                            pageNumber: i + 2,
                            actions: _actions(issue),
                          ),
                          if (page.heldBack &&
                              i == math.min(1, page.innerPages.length - 1))
                            HeldBackNotice(
                              candidates: widget.viewer.candidates,
                              onMakeTodayIssue: widget.onMakeTodayIssue,
                            ),
                          // 목업처럼 다섯째 장 뒤에 주제, 열째 장 뒤에 전시. 장이 적으면 끝에.
                          for (final (at, feature) in [
                            (4, widget.challenge),
                            (9, widget.collection),
                          ])
                            if (feature != null &&
                                i == math.min(at, page.innerPages.length - 1))
                              FeatureCard(
                                key: ValueKey(
                                  'feed-feature-${feature.eyebrow}',
                                ),
                                feature: feature,
                                photos: _photosAround(page.innerPages, i),
                              ),
                        ],
                        const SizedBox(height: 110),
                      ],
                    ),
                    MeltingMasthead(
                      controller: _scroll,
                      coverColor: cover.inkMasthead
                          ? EselColors.ink
                          : Colors.white,
                      chromeTop: chromeTop,
                      onTapLogo: _toTop,
                    ),
                  ],
                ),
        );
      },
    );
  }

  /// 카드 사진 석 장: 카드 뒤에 올 지면부터, 모자라면 앞 지면에서. 피드에 이미 있는 것이라
  /// 내가 지금 볼 수 있는 사진이다(P01).
  List<PublicIssue> _photosAround(List<PublicIssue> pages, int index) => [
    ...pages.skip(index + 1),
    ...pages.take(index + 1).toList().reversed,
  ].where((issue) => issue.photo.isNotEmpty).take(3).toList();

  /// 전체 / 구독. 선택한 쪽 아래에 1.5px 밑줄.
  Widget _tabs(Color color) => const SizedBox.shrink();

  /// 처음 받는 중, 오류, 또는 구독 탭이 비었을 때. 탭은 그대로 둔다.
  Widget _buildEmpty(FeedPage? page, double chromeTop) {
    final fc = widget.feedController;
    final String message;
    if (page == null) {
      message = fc.errorMessage ?? '';
    } else if (fc.currentTab == FeedTab.subscribed) {
      message = '구독한 잡지의 오늘의 캔버스가 아직 없어요.\n표지에서 이름 옆 구독을 눌러 보세요.';
    } else {
      message = '오늘의 표지가 아직 없어요. 잠시 뒤 다시 열어 주세요.';
    }
    return Padding(
      padding: EdgeInsets.only(top: chromeTop),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 20, 0),
            child: SizedBox(
              height: 44,
              child: DefaultTextStyle(
                style: EselTypography.label(fontSize: 13),
                child: Row(children: [_tabs(EselColors.ink)]),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: page == null && fc.errorMessage == null
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: EselTypography.body(color: EselColors.muted),
                          ),
                          if (page == null) ...[
                            const SizedBox(height: 12),
                            EselPressable(
                              semanticsLabel: '다시 불러오기',
                              onTap: fc.load,
                              child: Text(
                                '다시 불러오기',
                                style: EselTypography.label(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
