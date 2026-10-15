import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/ui/esel_button.dart';
import '../../../../core/ui/esel_paint_asset.dart';
import '../../../../core/ui/esel_pressable.dart';
import '../../../drafts/domain/cover_draft.dart';
import '../../../reactions/presentation/controllers/reactions_controller.dart';
import '../../../media/presentation/cover_preview.dart';

class MyMagazineScreen extends StatelessWidget {
  final String masthead;
  final int issueCount;
  final bool hasPublishedToday;

  /// 오늘 내 색(발행 전이면 고른 후보).
  final EselPaint todayColor;

  /// 오늘 발행한 호(없으면 null).
  final CoverDraft? todayIssue;
  final ReactionsController reactionsController;
  final VoidCallback onMakeTodayIssue;
  final VoidCallback onOpenShelf;
  final VoidCallback onOpenRecords;
  final VoidCallback onOpenFriends;
  final VoidCallback onOpenTwin;
  final VoidCallback onOpenSettings;
  final bool showExtendedFeatures;

  const MyMagazineScreen({
    super.key,
    required this.masthead,
    required this.issueCount,
    required this.hasPublishedToday,
    required this.todayColor,
    this.todayIssue,
    required this.reactionsController,
    required this.onMakeTodayIssue,
    required this.onOpenShelf,
    required this.onOpenRecords,
    required this.onOpenFriends,
    required this.onOpenTwin,
    required this.onOpenSettings,
    this.showExtendedFeatures = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: reactionsController,
      builder: (context, _) {
        final stats = reactionsController.getOwnerStats('my_today');

        return Scaffold(
          backgroundColor: EselTokens.paper,
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: EselTokens.space24,
              ),
              children: [
                const SizedBox(height: EselTokens.space12),
                _buildHeader(),
                const SizedBox(height: EselTokens.space20),
                _buildTodayStatusCard(),
                const SizedBox(height: EselTokens.space20),
                if (showExtendedFeatures) _buildOwnerReactionsCard(stats),
                const SizedBox(height: EselTokens.space24),
                _buildActionMenu(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              masthead,
              style: EselTypography.headlineLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '총 $issueCount호 발행 · 결호 없음',
              style: EselTypography.caption.copyWith(
                color: EselTokens.inkMuted,
              ),
            ),
          ],
        ),
        EselPressable(
          onTap: onOpenSettings,
          child: const SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              Icons.settings_outlined,
              size: 24,
              color: EselTokens.ink,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayStatusCard() {
    if (!hasPublishedToday) {
      return Container(
        padding: const EdgeInsets.all(EselTokens.space20),
        decoration: BoxDecoration(
          color: EselTokens.paperWarm,
          borderRadius: BorderRadius.circular(EselTokens.radius20),
          border: Border.all(color: EselTokens.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                EselPaintAsset(paint: todayColor, width: 24),
                const SizedBox(width: 8),
                Text('오늘 호가 아직 발행되지 않았습니다', style: EselTypography.labelSmall),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '오늘의 사진과 한 줄로\nNº ${(issueCount + 1).toString().padLeft(3, '0')}호를 발행하세요.',
              style: EselTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            EselButton(
              label: '오늘 호 만들기',
              isPrimary: true,
              icon: Icons.add,
              onTap: onMakeTodayIssue,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(EselTokens.space20),
      decoration: BoxDecoration(
        color: EselTokens.paperWarm,
        borderRadius: BorderRadius.circular(EselTokens.radius20),
        border: Border.all(color: EselTokens.borderDefault),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(EselTokens.radius14),
            child: SizedBox(width: 80, height: 106, child: _localCover()),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: EselTokens.ink,
                    borderRadius: BorderRadius.circular(EselTokens.radiusPill),
                  ),
                  child: Text(
                    '오늘 호 발행 완료',
                    style: EselTypography.caption.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nº ${issueCount.toString().padLeft(3, '0')}',
                  style: EselTypography.monoLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  todayIssue?.publishedOn?.replaceAll('-', '. ') ?? '',
                  style: EselTypography.caption.copyWith(
                    color: EselTokens.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerReactionsCard(dynamic stats) {
    return Container(
      padding: const EdgeInsets.all(EselTokens.space16),
      decoration: BoxDecoration(
        color: EselTokens.paperWarm,
        borderRadius: BorderRadius.circular(EselTokens.radius16),
        border: Border.all(color: EselTokens.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lock_outline,
                size: 14,
                color: EselTokens.inkMuted,
              ),
              const SizedBox(width: 6),
              Text(
                '오늘 ${stats.readCount}명이 읽었어요 · 나에게만 보여요',
                style: EselTypography.caption.copyWith(
                  color: EselTokens.inkMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildReactionMetric('좋아요', stats.likeCount.toString()),
              _buildReactionMetric('스크랩', stats.scrapCount.toString()),
              _buildReactionMetric('독자 한 줄', stats.readerLineCount.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _localCover() {
    final issue = todayIssue;
    if (issue == null) return const ColoredBox(color: EselColors.photo);
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: 360,
        height: 480,
        child: CoverPreview(draft: issue),
      ),
    );
  }

  Widget _buildReactionMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: EselTypography.monoLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: EselTypography.caption.copyWith(color: EselTokens.inkMuted),
        ),
      ],
    );
  }

  Widget _buildActionMenu() {
    return Column(
      children: [
        _buildMenuItem(Icons.menu_book_outlined, '서가 전체 보기', onOpenShelf),
        if (showExtendedFeatures) ...[
          _buildMenuItem(
            Icons.calendar_month_outlined,
            '월간 색 기록 (복원 2회)',
            onOpenRecords,
          ),
          _buildMenuItem(Icons.people_outline, '나의 친구', onOpenFriends),
          _buildMenuItem(
            Icons.auto_awesome_mosaic_outlined,
            '트윈 (공동 호)',
            onOpenTwin,
          ),
        ],
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: EselPressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: EselTokens.paperWarm,
            borderRadius: BorderRadius.circular(EselTokens.radius14),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: EselTokens.ink),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: EselTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: EselTokens.inkSubtle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
