import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/ui/esel_button.dart';
import '../../../../core/ui/esel_paint_asset.dart';
import '../../../../core/ui/esel_pressable.dart';
import '../../../../core/ui/esel_image.dart';
import '../../../reactions/presentation/controllers/reactions_controller.dart';
import '../../domain/models/magazine_models.dart';
import '../controllers/magazine_controller.dart';
import '../../../media/presentation/cover_preview.dart';

class ShelfScreen extends StatelessWidget {
  final String masthead;
  final MagazineController controller;
  final ReactionsController reactionsController;
  final Function(IssueSummary issue) onSelectIssue;
  final VoidCallback onBack;
  final bool isOwner;

  const ShelfScreen({
    super.key,
    required this.masthead,
    required this.controller,
    required this.reactionsController,
    required this.onSelectIssue,
    required this.onBack,
    this.isOwner = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller, reactionsController]),
      builder: (context, _) {
        final profile = controller.getMagazineProfile(
          masthead,
          myIssueCount: 249,
          hasPublishedToday: true,
        );
        final isSubscribed = reactionsController.isSubscribed(masthead);
        final isSpines = controller.viewMode == ShelfViewMode.spines;

        return Scaffold(
          backgroundColor: EselTokens.paper,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopBar(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: EselTokens.space24,
                  ),
                  child: _buildProfileHeader(profile, isSubscribed),
                ),
                const SizedBox(height: EselTokens.space16),
                _buildViewToggle(isSpines),
                const SizedBox(height: EselTokens.space12),
                Expanded(
                  child: isSpines
                      ? _buildSpinesView(profile)
                      : _buildCoversView(profile),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EselTokens.space16,
        vertical: 8,
      ),
      child: Row(
        children: [
          EselPressable(
            onTap: onBack,
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: EselTokens.ink,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(MagazineProfile profile, bool isSubscribed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              profile.masthead,
              style: EselTypography.headlineLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!isOwner)
              EselButton(
                label: isSubscribed ? '구독 중' : '구독',
                isPrimary: !isSubscribed,
                onTap: () => reactionsController.toggleSubscription(masthead),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          profile.bio,
          style: EselTypography.bodyMedium.copyWith(color: EselTokens.inkMuted),
        ),
        const SizedBox(height: 12),
        Text(
          '총 ${profile.totalIssues}호 발행 · 결호 없음',
          style: EselTypography.caption.copyWith(color: EselTokens.inkSubtle),
        ),
      ],
    );
  }

  Widget _buildViewToggle(bool isSpines) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EselTokens.space24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          EselPressable(
            onTap: controller.toggleViewMode,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: EselTokens.paperWarm,
                borderRadius: BorderRadius.circular(EselTokens.radiusPill),
                border: Border.all(color: EselTokens.borderDefault),
              ),
              child: Row(
                children: [
                  Icon(
                    isSpines ? Icons.grid_view : Icons.view_column_outlined,
                    size: 16,
                    color: EselTokens.ink,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isSpines ? '표지 보기' : '책등 보기',
                    style: EselTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
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

  Widget _buildCoversView(MagazineProfile profile) {
    if (profile.issues.isEmpty) {
      return const Center(child: Text('아직 발행한 호가 없어요. 오늘의 표지를 만들어 보세요.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(EselTokens.space24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: profile.issues.length,
      itemBuilder: (context, idx) {
        final issue = profile.issues[idx];
        return EselPressable(
          onTap: () => onSelectIssue(issue),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(EselTokens.radius14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (issue.cover != null)
                  FittedBox(
                    child: SizedBox(
                      width: 360,
                      height: 480,
                      child: CoverPreview(draft: issue.cover!),
                    ),
                  )
                else
                  EselAssetImage(issue.photoAsset, fit: BoxFit.cover),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Text(
                    issue.issueString,
                    style: EselTypography.monoSmall.copyWith(
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Row(
                    children: [
                      EselPaintAsset(paint: issue.color, width: 18),
                      const SizedBox(width: 6),
                      Text(
                        issue.date,
                        style: EselTypography.caption.copyWith(
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.6),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpinesView(MagazineProfile profile) {
    return ListView.separated(
      padding: const EdgeInsets.all(EselTokens.space24),
      itemCount: profile.issues.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final issue = profile.issues[idx];
        return EselPressable(
          onTap: () => onSelectIssue(issue),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: EselTokens.paperWarm,
              borderRadius: BorderRadius.circular(EselTokens.radius12),
              border: Border.all(color: EselTokens.borderDefault),
            ),
            child: Row(
              children: [
                EselPaintAsset(paint: issue.color, width: 24),
                const SizedBox(width: 14),
                Text(
                  issue.issueString,
                  style: EselTypography.monoMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    issue.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: EselTypography.bodySmall,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  issue.date,
                  style: EselTypography.caption.copyWith(
                    color: EselTokens.inkSubtle,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
