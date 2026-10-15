import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/ui/esel_glass.dart';
import '../../../../core/ui/esel_paint_asset.dart';
import '../../../../core/ui/esel_pressable.dart';
import '../../../../core/ui/esel_image.dart';

class IntroScreen extends StatefulWidget {
  final VoidCallback onOpenLogin;
  final VoidCallback onStartJoin;

  const IntroScreen({
    super.key,
    required this.onOpenLogin,
    required this.onStartJoin,
  });

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showLoginBar = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 640px 스크롤 감지 시 로그인 바 슬라이드 업 (P12, P16)
    if (_scrollController.offset >= 640 && !_showLoginBar) {
      setState(() => _showLoginBar = true);
    } else if (_scrollController.offset < 640 && _showLoginBar) {
      setState(() => _showLoginBar = false);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EselTokens.paper,
      body: Stack(
        children: [
          ListView(
            controller: _scrollController,
            padding: EdgeInsets.zero,
            children: [
              _buildCoverSection(),
              _buildFirstPageSection(),
              _buildSecondPageSection(),
              _buildTeaserEndSection(),
              const SizedBox(height: 120),
            ],
          ),
          // 로그인 후 캡슐이 있는 자리(아래 34, 홈 인디케이터가 더 높으면 그 위).
          Positioned(
            left: 16,
            right: 16,
            bottom: math.max(34.0, MediaQuery.paddingOf(context).bottom),
            child: _buildLoginBar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverSection() {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const EselAssetImage('assets/demo/dana.jpg', fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.35),
                  Colors.transparent,
                  Colors.black.withOpacity(0.55),
                ],
              ),
            ),
          ),
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
          Positioned(
            top: 54,
            right: 20,
            child: EselPressable(
              onTap: widget.onOpenLogin,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(EselTokens.radiusPill),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
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
          ),
          Positioned(
            bottom: 80,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'dana',
                  style: EselTypography.headlineSmall.copyWith(
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const EselPaintAsset(paint: EselPaint.powder, width: 24),
                    const SizedBox(width: 8),
                    Text(
                      '파우더 블루 · 같은 색 187명',
                      style: EselTypography.bodySmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '난간에 기대서, 셔츠 하나로.',
                  style: EselTypography.bodyLarge.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white70,
                      size: 24,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '아래로 스크롤하여 맛보기',
                      style: EselTypography.caption.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirstPageSection() {
    return Padding(
      padding: const EdgeInsets.all(EselTokens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '안쪽 1쪽',
            style: EselTypography.monoSmall.copyWith(
              color: EselTokens.inkMuted,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(EselTokens.radius16),
            child: const EselAssetImage(
              'assets/models/m01.jpg',
              fit: BoxFit.cover,
              height: 320,
              width: double.infinity,
            ),
          ),
          const SizedBox(height: 12),
          Text('바람이 머물다 가는 시간, 그 자리에서.', style: EselTypography.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildSecondPageSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EselTokens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '안쪽 2쪽',
            style: EselTypography.monoSmall.copyWith(
              color: EselTokens.inkMuted,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(EselTokens.radius16),
            child: const EselAssetImage(
              'assets/models/m02.jpg',
              fit: BoxFit.cover,
              height: 320,
              width: double.infinity,
            ),
          ),
          const SizedBox(height: 12),
          Text('가장 나다운 빛깔로 하루를 채우다.', style: EselTypography.bodyMedium),
        ],
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
