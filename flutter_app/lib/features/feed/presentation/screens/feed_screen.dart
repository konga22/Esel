import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/ui/esel_paint_asset.dart';
import '../../../../core/ui/esel_pressable.dart';
import '../../../../core/ui/esel_image.dart';
import '../../../issue/presentation/widgets/issue_bottom_sheet.dart';
import '../../../moderation/presentation/widgets/moderation_sheet.dart';
import '../../../reactions/presentation/controllers/reactions_controller.dart';
import '../../../sharing/presentation/widgets/share_sheet.dart';
import '../controllers/feed_controller.dart';

class FeedScreen extends StatefulWidget {
  final FeedController feedController;
  final ReactionsController reactionsController;
  final bool isAuthenticated;
  final VoidCallback onRequestLogin;
  final Function(String masthead) onOpenAuthorShelf;

  const FeedScreen({
    super.key,
    required this.feedController,
    required this.reactionsController,
    required this.isAuthenticated,
    required this.onRequestLogin,
    required this.onOpenAuthorShelf,
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _handleProtectedAction(VoidCallback action) {
    if (!widget.isAuthenticated) {
      widget.onRequestLogin();
    } else {
      action();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.feedController,
        widget.reactionsController,
      ]),
      builder: (context, _) {
        final fc = widget.feedController;
        final rc = widget.reactionsController;
        final items = fc.getItems({'seul', 'min'});

        return Scaffold(
          backgroundColor: EselTokens.paper,
          body: Stack(
            children: [
              if (items.isEmpty)
                Center(
                  child: Text(
                    '구독 중인 잡지가 없습니다.\n피드에서 마음에 드는 잡지를 구독해 보세요.',
                    textAlign: TextAlign.center,
                    style: EselTypography.bodyMedium.copyWith(
                      color: EselTokens.inkMuted,
                    ),
                  ),
                )
              else
                PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: items.length,
                  itemBuilder: (context, idx) {
                    final item = items[idx];
                    return _buildCoverPage(item, rc);
                  },
                ),
              Positioned(top: 0, left: 0, right: 0, child: _buildTopTabBar(fc)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopTabBar(FeedController fc) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: EselTokens.space24,
          vertical: 8,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildTabButton('오늘의 표지', FeedTab.all, fc),
                const SizedBox(width: 14),
                _buildTabButton('내 구독', FeedTab.subs, fc),
              ],
            ),
            Text(
              'Nº 249 · 2026. 9. 6.',
              style: EselTypography.monoSmall.copyWith(
                color: Colors.white,
                shadows: [
                  Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, FeedTab tab, FeedController fc) {
    final isSelected = fc.currentTab == tab;
    return EselPressable(
      onTap: () {
        fc.switchTab(tab);
        _scrollToTop();
      },
      child: Text(
        label,
        style: EselTypography.labelLarge.copyWith(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          shadows: [
            Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverPage(FeedItem item, ReactionsController rc) {
    final isLiked = rc.isLiked(item.id);
    final isScrapped = rc.isScrapped(item.id);
    final isSubscribed = rc.isSubscribed(item.masthead);

    return Stack(
      fit: StackFit.expand,
      children: [
        EselAssetImage(item.photoAsset, fit: BoxFit.cover),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.35),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.55),
              ],
              stops: const [0.0, 0.2, 0.7, 1.0],
            ),
          ),
        ),

        // 제호 헤더
        Positioned(
          top: 70,
          left: 20,
          right: 20,
          child: EselPressable(
            onTap: _scrollToTop,
            child: Text(
              'Esel',
              textAlign: TextAlign.center,
              style: EselTypography.mastheadHero.copyWith(
                fontSize: 100,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 하단 정보 & 인터랙션
        Positioned(
          bottom: 100,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  EselPressable(
                    onTap: () => widget.onOpenAuthorShelf(item.masthead),
                    child: Text(
                      item.masthead,
                      style: EselTypography.headlineSmall.copyWith(
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  EselPressable(
                    onTap: () => _handleProtectedAction(
                      () => rc.toggleSubscription(item.masthead),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSubscribed
                            ? Colors.white24
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          EselTokens.radiusPill,
                        ),
                        border: Border.all(color: Colors.white70),
                      ),
                      child: Text(
                        isSubscribed ? '구독 중' : '구독',
                        style: EselTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  EselPaintAsset(paint: item.color, width: 24),
                  const SizedBox(width: 8),
                  Text(
                    '${EselPaints.of(item.color).nameKo} · 같은 색 ${item.sameColorCount}명',
                    style: EselTypography.bodySmall.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                item.caption,
                style: EselTypography.bodyLarge.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  EselPressable(
                    onTap: () =>
                        _handleProtectedAction(() => rc.toggleLike(item.id)),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? EselTokens.semanticRed : Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  EselPressable(
                    onTap: () =>
                        _handleProtectedAction(() => rc.toggleScrap(item.id)),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        isScrapped ? Icons.bookmark : Icons.bookmark_border,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  EselPressable(
                    onTap: () => ShareSheet.show(
                      context,
                      issueId: item.id,
                      masthead: item.masthead,
                      issueNumber: item.issueNumber,
                    ),
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.share_outlined,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                  const Spacer(),
                  EselPressable(
                    onTap: () => IssueBottomSheet.show(
                      context,
                      issueId: item.id,
                      authorMasthead: item.masthead,
                      mainPhoto: item.photoAsset,
                      secondPhoto: item.secondPhotoAsset,
                      color: item.color,
                      caption: item.caption,
                      issueNumber: item.issueNumber,
                      isOwner: false,
                      reactionsController: rc,
                      onOpenAuthorShelf: () =>
                          widget.onOpenAuthorShelf(item.masthead),
                      onShare: () => ShareSheet.show(
                        context,
                        issueId: item.id,
                        masthead: item.masthead,
                        issueNumber: item.issueNumber,
                      ),
                      onReport: () => ModerationSheet.show(
                        context,
                        authorMasthead: item.masthead,
                        onReport: () {},
                        onBlock: () {},
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(
                          EselTokens.radiusPill,
                        ),
                        border: Border.all(color: Colors.white38),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '펼쳐 보기',
                            style: EselTypography.labelSmall.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_up,
                            size: 18,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
