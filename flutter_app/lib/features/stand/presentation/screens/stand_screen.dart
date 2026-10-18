import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/ui/esel_paint_asset.dart';
import '../../../issue/domain/models/public_issue.dart';
import '../../../issue/presentation/canvas_photo.dart';
import '../../domain/rules/same_color_rule.dart';
import '../controllers/stand_controller.dart';

class StandScreen extends StatefulWidget {
  final StandController controller;
  final SameColorViewer viewer;
  final String? viewerId;
  final void Function(PublicIssue) onSelectCover;
  final VoidCallback onMakeTodayIssue;
  final VoidCallback? onOpenChallenges, onOpenCollections;
  const StandScreen({
    super.key,
    required this.controller,
    required this.viewer,
    this.viewerId,
    required this.onSelectCover,
    required this.onMakeTodayIssue,
    this.onOpenChallenges,
    this.onOpenCollections,
  });
  @override
  State<StandScreen> createState() => _StandScreenState();
}

class _StandScreenState extends State<StandScreen> {
  StandController get c => widget.controller;
  @override
  void initState() {
    super.initState();
    c.configure(viewer: widget.viewer, viewerId: widget.viewerId);
  }

  @override
  void didUpdateWidget(StandScreen old) {
    super.didUpdateWidget(old);
    c.configure(viewer: widget.viewer, viewerId: widget.viewerId);
  }

  Future<void> _colors() async {
    c.selectTab(PaletteTab.colors);
    final picked = await showModalBottomSheet<EselPaint>(
      context: context,
      useSafeArea: true,
      builder: (context) => ListView(
        children: [
          const ListTile(title: Text('색상')),
          for (final color in [
            if (widget.viewer.candidates.contains(c.preferredColor))
              c.preferredColor!,
            ...widget.viewer.candidates.where((v) => v != c.preferredColor),
            ...EselPaints.order.where(
              (v) => !widget.viewer.candidates.contains(v),
            ),
          ]) ...[
            if (!widget.viewer.candidates.contains(color) &&
                color ==
                    EselPaints.order.firstWhere(
                      (v) => !widget.viewer.candidates.contains(v),
                    ))
              const Divider(key: Key('palette-candidate-divider')),
            ListTile(
              leading: EselPaintAsset(paint: color, width: 36),
              title: Text(EselPaints.of(color).nameKo),
              trailing: SameColorRule.isLockedToday(color, widget.viewer)
                  ? const Icon(Icons.lock_outline)
                  : null,
              onTap: () => Navigator.pop(context, color),
            ),
          ],
        ],
      ),
    );
    if (picked != null && mounted) c.select(picked);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: c,
    builder: (context, _) => Scaffold(
      backgroundColor: EselColors.paper,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 130),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '팔레트',
                      style: EselTypography.heading(fontSize: 34),
                    ),
                  ),
                  Text(
                    '${widget.viewer.today.shortLabel} ${widget.viewer.today.weekdayLabel}',
                    style: EselTypography.name(fontSize: 16),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                for (final tab in PaletteTab.values)
                  Expanded(
                    child: TextButton(
                      key: ValueKey('palette-${tab.name}'),
                      onPressed: tab == PaletteTab.colors
                          ? _colors
                          : () => c.selectTab(tab),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            switch (tab) {
                              PaletteTab.recommended => '추천',
                              PaletteTab.colors =>
                                c.selected == null
                                    ? '색상 ▾'
                                    : '${EselPaints.of(c.selected!).nameKo} ▾',
                              PaletteTab.subscriptions => '구독',
                            },
                            style: EselTypography.label(
                              fontSize: 16,
                              color: c.tab == tab
                                  ? EselColors.ink
                                  : EselColors.muted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 2,
                            width: 28,
                            color: c.tab == tab
                                ? EselColors.ink
                                : Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (c.isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (c.errorMessage case final error?)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(error),
                    TextButton(onPressed: c.load, child: const Text('다시 불러오기')),
                  ],
                ),
              ),
            if (!c.isLoading && c.errorMessage == null) ...[
              if (c.tab == PaletteTab.colors && c.selected != null)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    EselPaints.of(c.selected!).nameKo,
                    style: EselTypography.heading(fontSize: 28),
                  ),
                ),
              if (c.tiles.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('지금 볼 수 있는 캔버스가 없어요. 구독하거나 다른 색을 둘러보세요.'),
                ),
              for (var start = 0; start < c.tiles.length; start += 5)
                _block(c.tiles.skip(start).take(5).toList(), start ~/ 5),
              if (c.shelf?.isPreview == true) ...[
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (var i = 0; i < (c.shelf!.hiddenCount.clamp(0, 9)); i++)
                      const ColoredBox(color: EselColors.photo),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        '올리면 함께 펼쳐집니다',
                        style: EselTypography.heading(fontSize: 26),
                      ),
                      Text('${c.shelf!.hiddenCount}장이 더 있어요.'),
                      const Text('서울 자정이 지나면 지난 캔버스도 볼 수 있어요.'),
                      TextButton(
                        onPressed: widget.onMakeTodayIssue,
                        child: const Text('오늘의 캔버스 만들기'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            Padding(
              padding: const EdgeInsets.all(20),
              child: Wrap(
                spacing: 16,
                children: [
                  if (widget.onOpenChallenges != null)
                    TextButton(
                      onPressed: widget.onOpenChallenges,
                      child: const Text('이번 주 주제 →'),
                    ),
                  if (widget.onOpenCollections != null)
                    TextButton(
                      onPressed: widget.onOpenCollections,
                      child: const Text('전시 →'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _block(List<PublicIssue> items, int block) => LayoutBuilder(
    builder: (context, box) {
      final w = (box.maxWidth - 4) / 3, h = w * 4 / 3;
      Widget tile(int index, double height) => SizedBox(
        height: height,
        child: index >= items.length
            ? const SizedBox.shrink()
            : InkWell(
                key: ValueKey('palette-cover-${items[index].id}'),
                onTap: () => widget.onSelectCover(items[index]),
                child: Semantics(
                  label: '${items[index].masthead}의 스케치북 보기',
                  child: CanvasPhoto(issue: items[index], cover: true),
                ),
              ),
      );
      final columns = [
        Expanded(
          child: Column(
            children: [tile(0, h), const SizedBox(height: 2), tile(2, h)],
          ),
        ),
        Expanded(
          child: Column(
            children: [tile(1, h), const SizedBox(height: 2), tile(3, h)],
          ),
        ),
        Expanded(child: tile(4, h * 2 + 2)),
      ];
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (block.isOdd) columns[2] else columns[0],
            const SizedBox(width: 2),
            columns[1],
            const SizedBox(width: 2),
            if (block.isOdd) columns[0] else columns[2],
          ],
        ),
      );
    },
  );
}
