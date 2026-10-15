import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/ui/esel_cover_mini.dart';
import '../../../../core/ui/esel_paint_asset.dart';
import '../../../../core/ui/esel_pressable.dart';
import '../../../issue/domain/models/public_issue.dart';
import '../../../issue/presentation/issue_photo.dart';
import '../../domain/rules/same_color_rule.dart';
import '../controllers/stand_controller.dart';

/// C4 가판대 · C8 같은 색(발행 전).
///
/// 칩 순서는 전체 → 오늘 나의 후보 3색 → 나머지 9색. 발행 전에는 후보 3색 칩 모두에 자물쇠가
/// 붙고, 그 방은 최신 3장과 흐린 책등(개수만)으로 보인다(P01).
class StandScreen extends StatefulWidget {
  final StandController controller;
  final SameColorViewer viewer;
  final String? viewerId;
  final void Function(PublicIssue issue) onSelectCover;
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
  StandController get controller => widget.controller;
  SameColorViewer get viewer => widget.viewer;

  @override
  void initState() {
    super.initState();
    controller.configure(viewer: viewer, viewerId: widget.viewerId);
  }

  @override
  void didUpdateWidget(StandScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 발행·자정·로그인으로 보는 사람이 바뀌면 다시 받는다(잠금이 풀리거나 다시 잠김).
    controller.configure(viewer: viewer, viewerId: widget.viewerId);
  }

  List<EselPaint> get _chipOrder => [
    ...viewer.candidates,
    ...EselPaints.order.where((c) => !viewer.candidates.contains(c)),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final shelf = controller.shelf;
        return Scaffold(
          backgroundColor: EselColors.paper,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                _buildChips(),
                Expanded(
                  child: shelf == null
                      ? _buildStatus()
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 120),
                          children: [
                            if (shelf.color != null) _buildRoomHeader(shelf),
                            if (shelf.isPreview)
                              ..._buildPreviewRoom(shelf)
                            else
                              ..._buildOpenShelves(shelf),
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

  /// 처음 받는 중이거나 받지 못했을 때.
  Widget _buildStatus() {
    final error = controller.errorMessage;
    if (error == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error,
              textAlign: TextAlign.center,
              style: EselTypography.body(color: EselColors.muted),
            ),
            const SizedBox(height: 12),
            EselPressable(
              semanticsLabel: '다시 불러오기',
              onTap: controller.load,
              child: Text('다시 불러오기', style: EselTypography.label()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                '가판대',
                style: EselTypography.heading(fontSize: 32).copyWith(height: 1),
              ),
            ),
          ),
          Text(
            '${viewer.today.shortLabel} ${viewer.today.weekdayLabel}',
            style: EselTypography.name(fontSize: 17),
          ),
        ],
      ),
    );
  }

  Widget _buildChips() {
    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
        children: [
          _chip(
            label: '전체',
            selected: controller.selected == null,
            onTap: () => controller.select(null),
          ),
          for (final color in _chipOrder) ...[
            const SizedBox(width: 8),
            _colorChip(color),
          ],
        ],
      ),
    );
  }

  Widget _colorChip(EselPaint color) {
    final info = EselPaints.of(color);
    final locked = SameColorRule.isLockedToday(color, viewer);
    return _chip(
      label: info.nameKo,
      paint: color,
      locked: locked,
      selected: controller.selected == color,
      semanticsLabel: locked
          ? '${info.nameKo} · 오늘 발행 전이라 세 장만 먼저 보여요'
          : info.nameKo,
      onTap: () => controller.select(color),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    EselPaint? paint,
    bool locked = false,
    String? semanticsLabel,
  }) {
    final fg = selected ? EselColors.paper : EselColors.ink;
    return EselPressable(
      semanticsLabel: semanticsLabel ?? label,
      onTap: onTap,
      child: Container(
        height: EselSizes.chip,
        padding: EdgeInsets.only(
          left: paint == null ? 16 : 8,
          right: paint == null ? 16 : (locked ? 12 : 14),
        ),
        decoration: BoxDecoration(
          color: selected ? EselColors.ink : Colors.white,
          borderRadius: BorderRadius.circular(EselSizes.chip / 2),
          border: selected
              ? null
              : Border.all(
                  color: locked ? EselColors.ink : EselColors.hairline,
                  width: locked ? 1.5 : 1,
                ),
        ),
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (paint != null) ...[
                EselPaintAsset(paint: paint, width: 40),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: EselTypography.label(
                  fontSize: 14,
                  color: fg,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (locked) ...[
                const SizedBox(width: 4),
                Icon(Icons.lock_outline, size: 15, color: fg),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 색 하나를 고르면: 물감 · "오늘의 카멜 · n명" · (발행 전) 먼저 3장.
  Widget _buildRoomHeader(StandShelf shelf) {
    final info = EselPaints.of(shelf.color!);
    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            EselPaintAsset(paint: shelf.color!, width: 56),
            const SizedBox(width: 6),
            Text(
              '오늘의 ${info.nameKo} · ${shelf.total}명',
              style: EselTypography.label(fontSize: 15),
            ),
            const Spacer(),
            if (shelf.isPreview)
              Text(
                '먼저 ${shelf.items.length}장',
                style: EselTypography.body(
                  fontSize: 13,
                  color: EselColors.muted,
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOpenShelves(StandShelf shelf) {
    if (shelf.items.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
          child: Text(
            shelf.color == null
                ? '오늘 가판대에 꽂힌 표지가 아직 없어요.'
                : '오늘 ${EselPaints.of(shelf.color!).nameKo} 표지는 아직 없어요.',
            textAlign: TextAlign.center,
            style: EselTypography.body(color: EselColors.muted),
          ),
        ),
      ];
    }
    final rows = <Widget>[];
    for (var i = 0; i < shelf.items.length; i += 2) {
      final pair = shelf.items.skip(i).take(2).toList();
      rows.add(
        LayoutBuilder(
          builder: (context, c) {
            final w = ((c.maxWidth - 32 - 14) / 2).floorToDouble();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final item in pair)
                        _miniCover(item, w, (w * 250 / 174).roundToDouble()),
                    ],
                  ),
                ),
                const _ShelfLine(),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      );
    }
    return rows;
  }

  List<Widget> _buildPreviewRoom(StandShelf shelf) {
    final info = EselPaints.of(shelf.color!);
    return [
      LayoutBuilder(
        builder: (context, c) {
          final w = ((c.maxWidth - 32 - 2 * 8) / 3).floorToDouble();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final item in shelf.items)
                  _miniCover(item, w, (w * 1.437).roundToDouble()),
              ],
            ),
          );
        },
      ),
      const _ShelfLine(),
      const SizedBox(height: 14),
      if (shelf.hiddenCount > 0)
        _LockedSpines(
          color: info,
          count: shelf.hiddenCount,
          message:
              '${info.nameKo} 표지 ${shelf.hiddenCount}장이 더 있어요.\n자정이 지나면 모두 펼쳐져요.',
        ),
      const SizedBox(height: 18),
      Center(
        child: EselPressable(
          semanticsLabel: '오늘 호 만들기',
          onTap: widget.onMakeTodayIssue,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 26),
            decoration: BoxDecoration(
              color: EselColors.ink,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, size: 18, color: EselColors.paper),
                const SizedBox(width: 6),
                Text(
                  '오늘 호 만들기',
                  style: EselTypography.label(
                    fontSize: 15,
                    color: EselColors.paper,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _miniCover(PublicIssue item, double w, double h) {
    return EselCoverMini(
      author: item.masthead,
      masthead: 'Esel',
      photo: issuePhotoProvider(item.photo),
      alt: item.alt,
      width: w,
      height: h,
      photoAlignment: const Alignment(0, -0.4),
      onTap: () => widget.onSelectCover(item),
    );
  }
}

class _ShelfLine extends StatelessWidget {
  const _ShelfLine();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 2, child: ColoredBox(color: EselColors.ink));
}

/// 잠긴 표지는 이름·사진 없이 그날 색의 흐린 책등으로만 그린다. 개수만 안다.
class _LockedSpines extends StatelessWidget {
  final EselPaintInfo color;
  final int count;
  final String message;

  const _LockedSpines({
    required this.color,
    required this.count,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final shown = count.clamp(1, 14);
    return Semantics(
      label: '${color.nameKo} 표지 $count장 · 오늘 호를 발행하면 펼쳐져요',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            ExcludeSemantics(
              child: Column(
                children: [
                  ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                    child: SizedBox(
                      height: 220,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var i = 0; i < shown; i++) ...[
                            if (i > 0) const SizedBox(width: 4),
                            Opacity(
                              opacity: 0.55 + ((i * 3) % 4) * 0.1,
                              child: Container(
                                width: 22,
                                height: 196.0 + ((i * 37) % 5) * 6,
                                color: color.color,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const _ShelfLine(),
                ],
              ),
            ),
            Positioned(
              top: 60,
              child: Container(
                width: 280,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                decoration: BoxDecoration(
                  color: const Color(0xF0F9F9FB),
                  borderRadius: BorderRadius.circular(EselRadius.colorPick),
                  border: Border.all(color: EselColors.hairline),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 28,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: ExcludeSemantics(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 20,
                        color: EselColors.ink,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        SameColorRule.bannerMessage,
                        textAlign: TextAlign.center,
                        style: EselTypography.heading(
                          fontSize: 22,
                        ).copyWith(height: 1.2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: EselTypography.body(
                          fontSize: 13,
                          color: EselColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
