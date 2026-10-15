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

/// C1·C7 표지 피드. 표지는 첫 장만(P16): 제호 "Esel"은 첫 장에만 크게 있고, 내리면 표지와
/// 함께 올라가며, 위로 48px 올리면 작은 로고, 맨 위 360px에서 제호로 녹아든다.
/// 그 아래는 제호 없는 안쪽 지면이다. 반응 숫자는 그리지 않는다(P18).
class FeedScreen extends StatefulWidget {
  final FeedController feedController;
  final ReactionsController reactionsController;
  final SameColorViewer viewer;
  final void Function(String ownerId) onOpenAuthorShelf;
  final void Function(PublicIssue issue) onOpenIssue;
  final void Function(EselPaint color) onOpenStand;
  final VoidCallback onMakeTodayIssue;

  const FeedScreen({
    super.key,
    required this.feedController,
    required this.reactionsController,
    required this.viewer,
    required this.onOpenAuthorShelf,
    required this.onOpenIssue,
    required this.onOpenStand,
    required this.onMakeTodayIssue,
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

  /// 전체 / 구독. 선택한 쪽 아래에 1.5px 밑줄.
  Widget _tabs(Color color) {
    final fc = widget.feedController;
    Widget tab(String label, FeedTab value) {
      final on = fc.currentTab == value;
      return Semantics(
        selected: on,
        child: EselPressable(
          semanticsLabel: label,
          onTap: () {
            fc.switchTab(value);
            if (_scroll.hasClients) _scroll.jumpTo(0);
          },
          child: Opacity(
            opacity: on ? 1 : 0.78,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: TextStyle(color: color)),
                  const SizedBox(height: 3),
                  Container(
                    height: 1.5,
                    width: 26,
                    color: on ? color : Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [tab('전체', FeedTab.all), tab('구독', FeedTab.subscribed)],
    );
  }

  /// 처음 받는 중, 오류, 또는 구독 탭이 비었을 때. 탭은 그대로 둔다.
  Widget _buildEmpty(FeedPage? page, double chromeTop) {
    final fc = widget.feedController;
    final String message;
    if (page == null) {
      message = fc.errorMessage ?? '';
    } else if (fc.currentTab == FeedTab.subscribed) {
      message = '구독한 잡지의 오늘 호가 아직 없어요.\n표지에서 이름 옆 구독을 눌러 보세요.';
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
