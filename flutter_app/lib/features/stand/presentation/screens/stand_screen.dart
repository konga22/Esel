import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/ui/esel_glass.dart';
import '../../../../core/ui/esel_paint_asset.dart';
import '../../../issue/domain/models/public_issue.dart';
import '../../../issue/presentation/canvas_photo.dart';
import '../../domain/rules/same_color_rule.dart';
import '../controllers/stand_controller.dart';

/// 팔레트(C4·C8), 10-18 시안 R5-4: 작은 사진 격자가 화면을 채우고 위에는 아무것도 없다.
/// 캡슐 위 둥근 버튼이 지금 보는 것(추천 물감 세 점 · 구독 얼굴 · 색 물감)을 보여 주고,
/// 누르면 엄지 둘레로 부채가 펼쳐진다: 반지름 80 추천·구독, 142 내 후보 3색(올리기 전 자물쇠),
/// 202 많이 고른 색 5개. "모든 색"은 목록 시트. 칸은 사진과 얼굴 연출만(사인 뒤로만 사인).
class StandScreen extends StatefulWidget {
  final StandController controller;
  final SameColorViewer viewer;
  final String? viewerId;
  final void Function(PublicIssue) onSelectCover;
  final VoidCallback onMakeTodayIssue;
  const StandScreen({
    super.key,
    required this.controller,
    required this.viewer,
    this.viewerId,
    required this.onSelectCover,
    required this.onMakeTodayIssue,
  });
  @override
  State<StandScreen> createState() => _StandScreenState();
}

class _StandScreenState extends State<StandScreen> {
  StandController get c => widget.controller;
  bool _fan = false;

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

  /// 내 후보 3색: 고른 색이 먼저.
  List<EselPaint> get _candidates => [
    if (widget.viewer.candidates.contains(c.preferredColor)) c.preferredColor!,
    ...widget.viewer.candidates.where((v) => v != c.preferredColor),
  ];

  /// 나머지 색. 서버 색 순서(오늘 많이 고른 순)가 연결되기 전에는 고정 물감 순서다.
  List<EselPaint> get _others => EselPaints.order
      .where((v) => !widget.viewer.candidates.contains(v))
      .toList();

  bool _locked(EselPaint color) =>
      SameColorRule.isLockedToday(color, widget.viewer);

  String get _viewLabel => switch (c.tab) {
    PaletteTab.recommended => '추천',
    PaletteTab.subscriptions => '구독',
    PaletteTab.colors =>
      c.selected == null ? '색상' : EselPaints.of(c.selected!).nameKo,
  };

  void _show(PaletteTab tab) {
    setState(() => _fan = false);
    c.selectTab(tab);
  }

  void _showColor(EselPaint color) {
    setState(() => _fan = false);
    c.tab = PaletteTab.colors;
    c.select(color);
  }

  Future<void> _allColors() async {
    setState(() => _fan = false);
    final others = _others;
    final picked = await showModalBottomSheet<EselPaint>(
      context: context,
      useSafeArea: true,
      builder: (context) => ListView(
        children: [
          const ListTile(title: Text('모든 색')),
          for (final color in [..._candidates, ...others]) ...[
            if (color == others.first)
              const Divider(key: Key('palette-candidate-divider')),
            ListTile(
              leading: EselPaintAsset(paint: color, width: 36),
              title: Text(EselPaints.of(color).nameKo),
              trailing: _locked(color) ? const Icon(Icons.lock_outline) : null,
              onTap: () => Navigator.pop(context, color),
            ),
          ],
        ],
      ),
    );
    if (picked != null && mounted) _showColor(picked);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: c,
    builder: (context, _) {
      // 캡슐과 같은 계산: 화면 아래 34(홈 인디케이터가 더 높으면 그 위), 높이 60.
      final capsuleBottom = math.max(
        34.0,
        MediaQuery.paddingOf(context).bottom,
      );
      final room = c.tab == PaletteTab.colors && c.selected != null;
      return Scaffold(
        backgroundColor: EselColors.paper,
        body: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  if (room) SafeArea(bottom: false, child: _roomHead()),
                  Expanded(child: _content(room)),
                ],
              ),
            ),
            if (!room)
              const Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 110,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x52000000), Color(0x00000000)],
                      ),
                    ),
                  ),
                ),
              ),
            if (_fan) ..._fanLayer(context, capsuleBottom),
            if (!_fan)
              Positioned(
                right: 86,
                bottom: capsuleBottom + 85,
                child: EselGlass(
                  borderRadius: 15,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  height: 30,
                  child: Center(
                    child: Text(
                      _viewLabel,
                      style: EselTypography.label(fontSize: 13),
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 16,
              bottom: capsuleBottom + 70,
              child: _fanButton(),
            ),
          ],
        ),
      );
    },
  );

  Widget _roomHead() {
    final color = c.selected!;
    final shelf = c.shelf;
    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 18, 0),
        child: Row(
          children: [
            EselPaintAsset(paint: color, width: 48),
            const SizedBox(width: 6),
            Text(
              EselPaints.of(color).nameKo,
              style: EselTypography.heading(fontSize: 30),
            ),
            const SizedBox(width: 8),
            if (shelf != null)
              Flexible(
                child: Text(
                  '같은 색 ${shelf.total}명${shelf.isPreview ? ' · 먼저 ${shelf.items.length}장' : ''}',
                  overflow: TextOverflow.ellipsis,
                  style: EselTypography.body(
                    fontSize: 13,
                    color: EselColors.muted,
                  ),
                ),
              ),
            if (_locked(color)) ...[
              const Spacer(),
              const Icon(Icons.lock_outline, size: 16, color: EselColors.muted),
            ],
          ],
        ),
      ),
    );
  }

  Widget _content(bool room) {
    if (c.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (c.errorMessage case final error?) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error),
            TextButton(onPressed: c.load, child: const Text('다시 불러오기')),
          ],
        ),
      );
    }
    final tiles = c.tiles;
    return ListView(
      padding: const EdgeInsets.only(bottom: 180),
      children: [
        if (tiles.isEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              room ? 24 : MediaQuery.paddingOf(context).top + 60,
              24,
              24,
            ),
            child: Text(
              c.tab == PaletteTab.subscriptions
                  ? '구독한 스케치북이 없어요. 스케치북에서 구독을 누르면 여기에 모여요.'
                  : '지금 볼 수 있는 캔버스가 없어요. 구독하거나 다른 색을 둘러보세요.',
            ),
          ),
        if (c.shelf?.isPreview == true) ...[
          _previewRow(tiles.take(3).toList()),
          _blurred(c.selected!, c.shelf!.hiddenCount),
        ] else
          for (var start = 0; start < tiles.length; start += 5)
            _block(tiles.skip(start).take(5).toList(), start ~/ 5),
      ],
    );
  }

  Widget _tile(PublicIssue issue) => InkWell(
    key: ValueKey('palette-cover-${issue.id}'),
    onTap: () => widget.onSelectCover(issue),
    child: Semantics(
      label: '${issue.masthead}의 스케치북 보기',
      child: CanvasPhoto(issue: issue),
    ),
  );

  Widget _previewRow(List<PublicIssue> items) => LayoutBuilder(
    builder: (context, box) {
      final w = (box.maxWidth - 4) / 3;
      return SizedBox(
        height: w * 4 / 3,
        child: Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              Expanded(
                child: i < items.length
                    ? _tile(items[i])
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      );
    },
  );

  /// 먼저 3장 뒤의 나머지: 사진·이름 없이 그 색 단색 칸(P01).
  Widget _blurred(EselPaint color, int hidden) => LayoutBuilder(
    builder: (context, box) {
      final w = (box.maxWidth - 4) / 3, h = w * 4 / 3;
      final tint = EselPaints.of(color).color;
      Widget cell(int i, double height) => Container(
        height: height,
        color: tint.withValues(alpha: 0.32 + (i * 5 % 4) * 0.08),
      );
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cell(0, h * 2 + 2)),
                const SizedBox(width: 2),
                Expanded(
                  child: Column(
                    children: [
                      cell(1, h),
                      const SizedBox(height: 2),
                      cell(3, h),
                    ],
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Column(
                    children: [
                      cell(2, h),
                      const SizedBox(height: 2),
                      cell(4, h),
                    ],
                  ),
                ),
              ],
            ),
            Positioned.fill(
              child: Align(
                alignment: const Alignment(0, -0.4),
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  decoration: BoxDecoration(
                    color: const Color(0xF2F9F9FB),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: EselColors.hairline),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline, size: 20),
                      const SizedBox(height: 4),
                      Text(
                        '올리면 함께 펼쳐집니다',
                        style: EselTypography.heading(fontSize: 22),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${EselPaints.of(color).nameKo} $hidden장이 더 있어요.\n자정이 지나면 모두 펼쳐져요.',
                        textAlign: TextAlign.center,
                        style: EselTypography.body(
                          fontSize: 13,
                          color: EselColors.muted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: widget.onMakeTodayIssue,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('오늘의 캔버스 만들기'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _block(List<PublicIssue> items, int block) => LayoutBuilder(
    builder: (context, box) {
      final w = (box.maxWidth - 4) / 3, h = w * 4 / 3;
      Widget tile(int index, double height) => SizedBox(
        height: height,
        child: index >= items.length
            ? const SizedBox.shrink()
            : _tile(items[index]),
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

  /// 지금 보는 것: 추천은 물감 세 점, 구독은 구독한 사람 얼굴, 색은 그 색 물감.
  Widget _viewFace() => switch (c.tab) {
    PaletteTab.colors when c.selected != null => EselPaintAsset(
      paint: c.selected!,
      width: 46,
    ),
    PaletteTab.subscriptions => _faces(22),
    _ => _dabs(false),
  };

  Widget _dabs(bool small) {
    final w = small ? 22.0 : 28.0;
    return SizedBox(
      width: small ? 38 : 46,
      height: small ? 24 : 34,
      child: Stack(
        children: [
          for (final (i, paint) in const [
            EselPaint.powder,
            EselPaint.coral,
            EselPaint.sage,
          ].indexed)
            Positioned(
              left: [0.0, w / 2, w / 4.6][i],
              top: [0.0, w / 3, w / 1.55][i],
              child: Transform.rotate(
                angle: -0.21,
                child: EselPaintAsset(paint: paint, width: w),
              ),
            ),
        ],
      ),
    );
  }

  /// 구독한 사람 얼굴 셋. 아직 불러오지 않았으면 사람 아이콘.
  Widget _faces(double size) {
    final people = c.tab == PaletteTab.subscriptions
        ? c.tiles.take(3).toList()
        : const <PublicIssue>[];
    if (people.isEmpty) {
      return Icon(Icons.people_outline, size: size + 4, color: EselColors.ink);
    }
    return SizedBox(
      width: size + (people.length - 1) * (size - 8),
      height: size,
      child: Stack(
        children: [
          for (final (i, issue) in people.indexed)
            Positioned(
              left: i * (size - 8),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(child: CanvasPhoto(issue: issue)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fanButton() => Semantics(
    button: true,
    label: _fan ? '닫기' : '볼 것 고르기 · 지금 $_viewLabel',
    child: GestureDetector(
      key: const ValueKey('palette-fan'),
      onTap: () => setState(() => _fan = !_fan),
      child: _fan
          ? Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: EselColors.ink,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x3D000000),
                    offset: Offset(0, 10),
                    blurRadius: 28,
                  ),
                ],
              ),
              child: const Icon(Icons.close, color: EselColors.paper),
            )
          : EselGlass(
              width: 60,
              height: 60,
              borderRadius: 30,
              child: Center(child: _viewFace()),
            ),
    ),
  );

  List<Widget> _fanLayer(BuildContext context, double capsuleBottom) {
    final size = MediaQuery.sizeOf(context);
    final center = Offset(size.width - 46, size.height - capsuleBottom - 100);
    final calm = MediaQuery.disableAnimationsOf(context);
    Offset at(double r, double deg) => Offset(
      center.dx + r * math.cos(deg * math.pi / 180),
      center.dy + r * math.sin(deg * math.pi / 180),
    );
    List<(EselPaint, Offset)> spread(
      List<EselPaint> list,
      double r,
      double a0,
      double a1,
    ) => [
      for (final (i, v) in list.indexed)
        (v, at(r, a0 + (a1 - a0) * i / math.max(1, list.length - 1))),
    ];
    Widget item({
      required Key key,
      required Offset p,
      required String label,
      required Widget child,
      required VoidCallback onTap,
      bool selected = false,
      bool lock = false,
    }) => Positioned(
      left: p.dx - 29,
      top: p.dy - 29,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: calm ? 1 : 0.9, end: 1),
        duration: calm ? Duration.zero : const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        builder: (context, v, child) => Opacity(
          opacity: calm ? 1 : ((v - 0.9) * 10).clamp(0.0, 1.0),
          child: Transform.scale(scale: v, child: child),
        ),
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          child: GestureDetector(
            key: key,
            onTap: onTap,
            child: SizedBox(
              width: 58,
              height: 58,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  EselGlass(
                    width: 58,
                    height: 58,
                    borderRadius: 29,
                    border: selected
                        ? Border.all(color: EselColors.ink, width: 2)
                        : null,
                    child: Center(child: child),
                  ),
                  if (lock)
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: EselColors.ink,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock,
                          size: 9,
                          color: EselColors.paper,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    Widget pick(PaletteTab tab, String label, double deg) => item(
      key: ValueKey('palette-fan-${tab.name}'),
      p: at(80, deg),
      label: label,
      selected: c.tab == tab,
      onTap: () => _show(tab),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tab == PaletteTab.subscriptions) _faces(18) else _dabs(true),
          Text(label, style: EselTypography.label(fontSize: 10.5)),
        ],
      ),
    );

    final colors = [
      ...spread(_candidates, 142, 192, 258),
      ...spread(_others.take(5).toList(), 202, 182, 268),
    ];
    return [
      Positioned.fill(
        child: GestureDetector(
          key: const ValueKey('palette-fan-dim'),
          onTap: () => setState(() => _fan = false),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(
                  center.dx / size.width * 2 - 1,
                  center.dy / size.height * 2 - 1,
                ),
                radius: 290 / size.shortestSide,
                colors: const [Color(0x80141412), Color(0x24141412)],
              ),
            ),
          ),
        ),
      ),
      pick(PaletteTab.recommended, '추천', 200),
      pick(PaletteTab.subscriptions, '구독', 250),
      for (final (color, p) in colors)
        item(
          key: ValueKey('palette-fan-color-${color.name}'),
          p: p,
          label:
              '${EselPaints.of(color).nameKo}${_locked(color) ? ' · 올리기 전이라 세 장만 먼저 보여요' : ''}',
          selected: c.tab == PaletteTab.colors && c.selected == color,
          lock: _locked(color),
          onTap: () => _showColor(color),
          child: EselPaintAsset(paint: color, width: 44),
        ),
      Positioned(
        left: 16,
        bottom: capsuleBottom + 80,
        child: GestureDetector(
          key: const ValueKey('palette-all-colors'),
          onTap: _allColors,
          child: EselGlass(
            borderRadius: 18,
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Center(
              child: Text('모든 색', style: EselTypography.label(fontSize: 13)),
            ),
          ),
        ),
      ),
    ];
  }
}
