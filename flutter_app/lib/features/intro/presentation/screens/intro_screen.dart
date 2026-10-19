import '../../../media/domain/models/media_photo.dart';
import '../../../media/presentation/remote_media_photo.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/ui/esel_glass.dart';
import '../../../../core/text/korean_count.dart';
import '../../../../core/time/service_date.dart';
import '../../../../core/ui/esel_pressable.dart';
import '../../../feed/presentation/controllers/feed_controller.dart';
import '../../../feed/presentation/widgets/feed_pages.dart';
import '../../../feed/presentation/widgets/melting_masthead.dart';
import '../../../issue/domain/models/public_issue.dart';
import '../../../issue/presentation/issue_photo.dart';
import '../../../stand/domain/rules/same_color_rule.dart';

class IntroScreen extends StatefulWidget {
  /// 비로그인 독자용 오늘의 표지(표지 + 안쪽 2쪽, P12).
  final FeedController feedController;
  final ServiceDate today;
  final VoidCallback onOpenLogin;
  final VoidCallback onStartJoin;

  const IntroScreen({
    super.key,
    required this.feedController,
    required this.today,
    required this.onOpenLogin,
    required this.onStartJoin,
  });

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showLoginBar = false;

  void _configure() => widget.feedController.configure(
    viewer: SameColorViewer.reader(widget.today),
    signedIn: false,
    subscribedOwnerIds: const {},
  );

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _configure();
  }

  @override
  void didUpdateWidget(IntroScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _configure();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 640px 지나면 캡슐 자리에서 로그인 바가 올라온다(P12).
    final threshold = math.min(
      640.0,
      _scrollController.position.maxScrollExtent,
    );
    final show = _scrollController.offset >= threshold - 1;
    if (show != _showLoginBar) setState(() => _showLoginBar = show);
  }

  void _scrollToTop() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _scrollController.jumpTo(0);
      return;
    }
    _scrollController.animateTo(
      0,
      duration: EselMotion.sheet,
      curve: EselMotion.drawer,
    );
  }

  /// 비로그인 독자의 반응·구독·스크랩·자세히 보기는 모두 로그인부터(P12).
  PageActions get _loginFirst => PageActions(
    liked: false,
    scrapped: false,
    subscribed: false,
    onLike: widget.onOpenLogin,
    onScrap: widget.onOpenLogin,
    onSubscribe: widget.onOpenLogin,
    onOpenSpread: widget.onOpenLogin,
    onOpenAuthor: widget.onOpenLogin,
    onOpenStand: widget.onOpenLogin,
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.feedController,
      builder: (context, _) {
        final page = widget.feedController.page;
        final cover = page?.cover;
        final media = MediaQuery.of(context);
        final chromeTop = math.max(48.0, media.padding.top);
        return Scaffold(
          backgroundColor: EselColors.paper,
          body: Stack(
            children: [
              if (widget.feedController.errorMessage case final error?)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error),
                      TextButton(
                        onPressed: () => widget.feedController.load(),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              else if (page != null && cover == null)
                const Center(child: Text('아직 볼 수 있는 캔버스가 없어요.'))
              else if (page == null || cover == null)
                const Center(child: CircularProgressIndicator(strokeWidth: 2))
              else
                ListView(
                  controller: _scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    TodayCover(
                      issue: cover,
                      sameColorCount: page.sameColorCount(cover.color),
                      height: math.max(600.0, media.size.height - 52),
                      chromeTop: chromeTop,
                      leading: const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Text('오늘의 표지'),
                      ),
                      meta: 'Nº ${page.appIssueNumber} · ${page.date.label}',
                      actions: _loginFirst,
                    ),
                    for (final (i, issue) in page.innerPages.indexed)
                      InnerPage(
                        issue: issue,
                        pageNumber: i + 2,
                        actions: _loginFirst,
                      ),
                    _TeaserEnd(
                      remainingPages: page.pagesForMembers,
                      backdrop: page.innerPages.isEmpty
                          ? cover
                          : page.innerPages.last,
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              if (cover != null)
                MeltingMasthead(
                  controller: _scrollController,
                  coverColor: cover.inkMasthead ? EselColors.ink : Colors.white,
                  chromeTop: chromeTop,
                  onTapLogo: _scrollToTop,
                ),
              // 로그인 후 캡슐이 있는 자리(아래 34, 홈 인디케이터가 더 높으면 그 위).
              Positioned(
                left: 16,
                right: 16,
                bottom: math.max(34.0, media.padding.bottom),
                child: _buildLoginBar(context),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 디자인 "로그인 바": 좌우 16, 높이 66, 모서리 33, 안쪽 8, Glass.
  /// 로그인(Ink 1.5px 테두리) : 스케치북 만들기(Ink 채움) = 1 : 1.35, 버튼 높이 50.
  /// 640px 지나면 translateY(140%) → 0(360ms drawer)으로 올라오고 200ms에 나타난다.
  /// 동작 줄이기에서는 제자리에서 나타나기만 한다.
  Widget _buildLoginBar(BuildContext context) {
    final visible =
        _showLoginBar ||
        widget.feedController.errorMessage != null ||
        (widget.feedController.page != null &&
            widget.feedController.page!.cover == null);
    final calm = MediaQuery.disableAnimationsOf(context);
    return IgnorePointer(
      ignoring: !visible,
      child: ExcludeSemantics(
        excluding: !visible,
        child: AnimatedSlide(
          offset: visible || calm ? Offset.zero : const Offset(0, 1.4),
          duration: EselMotion.loginBar,
          curve: EselMotion.drawer,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: EselGlass(
              key: const Key('login-bar'),
              height: EselSizes.loginBar,
              borderRadius: EselSizes.loginBar / 2,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    flex: 100,
                    child: _buildLoginBarButton(
                      '로그인',
                      filled: false,
                      onTap: widget.onOpenLogin,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 135,
                    child: _buildLoginBarButton(
                      '스케치북 만들기',
                      filled: true,
                      onTap: widget.onStartJoin,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginBarButton(
    String label, {
    required bool filled,
    required VoidCallback onTap,
  }) {
    return EselPressable(
      semanticsLabel: label,
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? EselColors.ink : null,
          borderRadius: BorderRadius.circular(25),
          border: filled ? null : Border.all(color: EselColors.ink, width: 1.5),
        ),
        child: Text(
          label,
          maxLines: 1,
          style: EselTypography.label(
            fontSize: 15,
            color: filled ? EselColors.paper : EselColors.ink,
          ),
        ),
      ),
    );
  }
}

/// J1 맛보기 끝(디자인 teaser). 흐린 사진 위에 안내 글만 둔다. 로그인·만들기 버튼은
/// 아래 로그인 바 하나뿐이다. 남은 쪽 수는 받지 않은 지면 수(P12)로 센다.
class _TeaserEnd extends StatelessWidget {
  final int remainingPages;
  final PublicIssue backdrop;

  const _TeaserEnd({required this.remainingPages, required this.backdrop});

  @override
  Widget build(BuildContext context) {
    final title = remainingPages > 0
        ? '오늘의 캔버스는 아직\n${koreanCount(remainingPages)} 쪽이 더 남았어요.'
        : '오늘의 캔버스는\n여기까지 읽었어요.';
    return SizedBox(
      height: 430,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ExcludeSemantics(
            child: Opacity(
              opacity: 0.85,
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: mediaPhotoId(backdrop.photo) != null
                    ? RemoteMediaPhoto(
                        decorative: true,
                        id: mediaPhotoId(backdrop.photo)!,
                        thumbnail: true,
                      )
                    : Image(
                        image: issuePhotoProvider(backdrop.photo),
                        fit: BoxFit.cover,
                        alignment: const Alignment(0.3, -0.7),
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x26F9F9FB), EselColors.paper],
                stops: [0, 0.78],
              ),
            ),
          ),
          Positioned(
            left: 28,
            right: 28,
            top: 170,
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: EselTypography.heading(
                    fontSize: 27,
                  ).copyWith(height: 1.3),
                ),
                const SizedBox(height: 12),
                Text(
                  '로그인하면 끝까지 읽고, 스케치북도 만들 수 있어요.',
                  textAlign: TextAlign.center,
                  style: EselTypography.body(
                    fontSize: 14,
                    color: EselColors.muted,
                  ).copyWith(height: 1.55),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
