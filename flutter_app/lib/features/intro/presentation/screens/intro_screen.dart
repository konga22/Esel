import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/ui/esel_glass.dart';
import '../../../../core/time/service_date.dart';
import '../../../../core/ui/esel_pressable.dart';
import '../../../feed/presentation/controllers/feed_controller.dart';
import '../../../feed/presentation/widgets/feed_pages.dart';
import '../../../feed/presentation/widgets/melting_masthead.dart';
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
    final show = _scrollController.offset >= 640;
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

  /// 비로그인 독자의 반응·구독·스크랩·펼쳐 보기는 모두 로그인부터(P12).
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
              if (page == null || cover == null)
                const Center(child: CircularProgressIndicator(strokeWidth: 2))
              else
                ListView(
                  controller: _scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    Stack(
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
                          meta:
                              'Nº ${page.appIssueNumber} · ${page.date.label}',
                          actions: _loginFirst,
                        ),
                        _buildLoginChip(chromeTop),
                      ],
                    ),
                    for (final (i, issue) in page.innerPages.indexed)
                      InnerPage(
                        issue: issue,
                        pageNumber: i + 2,
                        actions: _loginFirst,
                      ),
                    _buildTeaserEndSection(),
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

  Widget _buildLoginChip(double chromeTop) {
    return Positioned(
      top: chromeTop + 6,
      right: 20,
      child: EselPressable(
        onTap: widget.onOpenLogin,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(EselTokens.radiusPill),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Text(
            '로그인',
            style: EselTypography.labelMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeaserEndSection() {
    return Container(
      margin: const EdgeInsets.all(EselTokens.space24),
      padding: const EdgeInsets.all(EselTokens.space24),
      decoration: BoxDecoration(
        color: EselTokens.paperWarm,
        borderRadius: BorderRadius.circular(EselTokens.radius20),
        border: Border.all(color: EselTokens.borderDefault),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.auto_stories_outlined,
            size: 40,
            color: EselTokens.ink,
          ),
          const SizedBox(height: 16),
          Text(
            '오늘의 맛보기가 끝났습니다',
            style: EselTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '로그인하면 전체 피드와 12색 가판대,\n나만의 잡지를 매일 발행할 수 있습니다.',
            textAlign: TextAlign.center,
            style: EselTypography.bodySmall.copyWith(
              color: EselTokens.inkMuted,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onOpenLogin,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        EselTokens.radiusPill,
                      ),
                    ),
                  ),
                  child: const Text(
                    '로그인',
                    style: TextStyle(color: EselTokens.ink),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onStartJoin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EselTokens.ink,
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        EselTokens.radiusPill,
                      ),
                    ),
                  ),
                  child: const Text(
                    '내 잡지 만들기',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 디자인 "로그인 바": 좌우 16, 높이 66, 모서리 33, 안쪽 8, Glass.
  /// 로그인(Ink 1.5px 테두리) : 내 잡지 만들기(Ink 채움) = 1 : 1.35, 버튼 높이 50.
  /// 640px 지나면 translateY(140%) → 0(360ms drawer)으로 올라오고 200ms에 나타난다.
  /// 동작 줄이기에서는 제자리에서 나타나기만 한다.
  Widget _buildLoginBar(BuildContext context) {
    final calm = MediaQuery.disableAnimationsOf(context);
    return IgnorePointer(
      ignoring: !_showLoginBar,
      child: ExcludeSemantics(
        excluding: !_showLoginBar,
        child: AnimatedSlide(
          offset: _showLoginBar || calm ? Offset.zero : const Offset(0, 1.4),
          duration: EselMotion.loginBar,
          curve: EselMotion.drawer,
          child: AnimatedOpacity(
            opacity: _showLoginBar ? 1 : 0,
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
                      '내 잡지 만들기',
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
