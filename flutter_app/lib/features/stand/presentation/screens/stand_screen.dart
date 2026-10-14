import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/ui/esel_paint_asset.dart';
import '../../../../core/ui/esel_pressable.dart';
import '../../../../core/ui/esel_image.dart';
import '../controllers/stand_controller.dart';

class StandScreen extends StatelessWidget {
  final StandController controller;
  final String mySelectedColorKey;
  final bool hasPublishedToday;
  final Function(StandItem item) onSelectCover;

  const StandScreen({
    super.key,
    required this.controller,
    required this.mySelectedColorKey,
    required this.hasPublishedToday,
    required this.onSelectCover,
  });

  static final List<Map<String, String>> palette12 = EselPaint.values
      .map((color) => {'id': color.name, 'name': EselPaints.of(color).nameKo})
      .toList();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final eval = controller.getRoomEvaluation(
          mySelectedColorKey: mySelectedColorKey,
          hasPublishedToday: hasPublishedToday,
        );
        final visibleItems = controller.getVisibleItems(
          mySelectedColorKey: mySelectedColorKey,
          hasPublishedToday: hasPublishedToday,
        );

        return Scaffold(
          backgroundColor: EselTokens.paper,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                _buildColorChips(),
                const SizedBox(height: EselTokens.space12),
                if (eval.bannerMessage != null)
                  _buildLockBanner(eval.bannerMessage!),
                Expanded(
                  child: _buildGridAndSpines(visibleItems, eval.hiddenCount),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EselTokens.space24,
        vertical: EselTokens.space12,
      ),
      child: Text(
        '가판대',
        style: EselTypography.headlineMedium.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildColorChips() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: EselTokens.space20),
        scrollDirection: Axis.horizontal,
        itemCount: palette12.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final c = palette12[idx];
          final isSelected = controller.selectedColorKey == c['id'];
          final isMyColor = mySelectedColorKey == c['id'];

          return EselPressable(
            onTap: () => controller.selectColor(c['id']!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? EselTokens.ink : EselTokens.paperWarm,
                borderRadius: BorderRadius.circular(EselTokens.radiusPill),
                border: Border.all(
                  color: isSelected ? EselTokens.ink : EselTokens.borderDefault,
                ),
              ),
              child: Row(
                children: [
                  EselPaintAsset(colorKey: c['id']!, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    c['name']!,
                    style: EselTypography.labelSmall.copyWith(
                      color: isSelected ? Colors.white : EselTokens.ink,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                  if (isMyColor && !hasPublishedToday) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.lock_outline,
                      size: 14,
                      color: isSelected ? Colors.white70 : EselTokens.inkMuted,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLockBanner(String msg) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: EselTokens.space20,
        vertical: 6,
      ),
      padding: const EdgeInsets.all(EselTokens.space12),
      decoration: BoxDecoration(
        color: EselTokens.paperWarm,
        borderRadius: BorderRadius.circular(EselTokens.radius14),
        border: Border.all(color: EselTokens.borderDefault),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 18, color: EselTokens.inkMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: EselTypography.bodySmall.copyWith(
                color: EselTokens.inkMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridAndSpines(List<StandItem> items, int hiddenCount) {
    return ListView(
      padding: const EdgeInsets.all(EselTokens.space20),
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 16,
            childAspectRatio: 0.72,
          ),
          itemCount: items.length,
          itemBuilder: (context, idx) {
            final item = items[idx];
            return EselPressable(
              onTap: () => onSelectCover(item),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(EselTokens.radius14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    EselAssetImage(item.photoAsset, fit: BoxFit.cover),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Text(
                        item.masthead,
                        style: EselTypography.headlineSmall.copyWith(
                          color: Colors.white,
                          fontSize: 22,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 10,
                      child: Text(
                        item.issueNumber,
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
                  ],
                ),
              ),
            );
          },
        ),
        if (hiddenCount > 0) ...[
          const SizedBox(height: EselTokens.space24),
          Text(
            '흐린 책등 · 나머지 $hiddenCount권',
            style: EselTypography.caption.copyWith(color: EselTokens.inkMuted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: hiddenCount,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, _) => Container(
                width: 22,
                decoration: BoxDecoration(
                  color: EselTokens.borderDefault.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 100),
      ],
    );
  }
}
