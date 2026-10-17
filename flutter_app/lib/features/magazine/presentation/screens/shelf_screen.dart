import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/ui/esel_cover_mini.dart';
import '../../../../core/ui/esel_paint_asset.dart';
import '../../../../core/ui/esel_pressable.dart';
import '../../../drafts/domain/cover_draft.dart';
import '../../../issue/domain/models/public_issue.dart';
import '../../../issue/presentation/issue_photo.dart';
import '../../../media/presentation/cover_photo.dart';
import '../../../media/presentation/cover_preview.dart';
import '../../../reactions/presentation/controllers/reactions_controller.dart';
import '../../../stand/domain/rules/same_color_rule.dart';
import '../controllers/magazine_controller.dart';

/// C5 서가(개인 잡지). 누른 사람의 잡지를 연다. 구독자 수 같은 숫자는 없다(P18).
/// 지난 호는 결호 없이 하나씩 내려가고(P04), 표지/책등으로 본다.
class ShelfScreen extends StatefulWidget {
  final String ownerId;

  /// 아직 호가 없는 내 잡지의 이름.
  final String? masthead;
  final bool isOwner;
  final MagazineController controller;
  final ReactionsController reactionsController;
  final SameColorViewer viewer;
  final String? viewerId;
  final void Function(PublicIssue issue, CoverDraft? local) onSelectIssue;
  final VoidCallback onBack;

  const ShelfScreen({
    super.key,
    required this.ownerId,
    required this.controller,
    required this.reactionsController,
    required this.viewer,
    required this.onSelectIssue,
    required this.onBack,
    this.viewerId,
    this.masthead,
    this.isOwner = false,
  });

  @override
  State<ShelfScreen> createState() => _ShelfScreenState();
}

class _ShelfScreenState extends State<ShelfScreen> {
  MagazineController get controller => widget.controller;

  void _configure() => controller.configure(
    ownerId: widget.ownerId,
    viewer: widget.viewer,
    viewerId: widget.viewerId,
    masthead: widget.masthead,
  );

  @override
  void initState() {
    super.initState();
    _configure();
  }

  @override
  void didUpdateWidget(ShelfScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _configure();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller, widget.reactionsController]),
      builder: (context, _) {
        final profile = controller.profile;
        return Scaffold(
          backgroundColor: EselColors.paper,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopBar(),
                Expanded(
                  child: profile == null
                      ? _buildStatus()
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 120),
                          children: [
                            _buildHeader(profile),
                            _buildShelfTitle(),
                            const SizedBox(height: 8),
                            if (profile.issues.isEmpty)
                              _buildEmpty()
                            else if (controller.viewMode ==
                                ShelfViewMode.spines)
                              _buildSpines(profile)
                            else
                              _buildCovers(profile),
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

  Widget _buildTopBar() {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          const SizedBox(width: 6),
          EselPressable(
            semanticsLabel: '뒤로',
            onTap: widget.onBack,
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: EselColors.ink,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'ESEL · 개인 잡지',
            style: EselTypography.meta(color: EselColors.ink),
          ),
          const SizedBox(width: 18),
        ],
      ),
    );
  }

  Widget _buildStatus() {
    final error = controller.errorMessage;
    return Center(
      child: error == null
          ? const CircularProgressIndicator(strokeWidth: 2)
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: EselTypography.body(color: EselColors.muted),
              ),
            ),
    );
  }

  Widget _buildHeader(MagazineProfile profile) {
    final subscribed = widget.reactionsController.isSubscribed(profile.ownerId);
    final today = profile.todayColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            label: '${profile.masthead}의 잡지',
            child: ExcludeSemantics(
              child: FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  profile.masthead,
                  maxLines: 1,
                  style: EselTypography.name(
                    fontSize: 92,
                  ).copyWith(height: 0.95, letterSpacing: -0.03 * 92),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (today != null)
                      Row(
                        children: [
                          EselPaintAsset(paint: today, width: 52),
                          const SizedBox(width: 6),
                          Text(
                            '오늘은 ${EselPaints.of(today).nameKo}',
                            style: EselTypography.body(fontSize: 14),
                          ),
                        ],
                      ),
                    Text(
                      '${profile.totalIssues}호 발행',
                      style: EselTypography.body(
                        fontSize: 14,
                        color: EselColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (!widget.isOwner)
                EselPressable(
                  semanticsLabel: subscribed ? '구독 중' : '구독',
                  onTap: () => widget.reactionsController.toggleSubscription(
                    profile.ownerId,
                  ),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: subscribed ? Colors.transparent : EselColors.ink,
                      borderRadius: BorderRadius.circular(22),
                      border: subscribed
                          ? Border.all(color: EselColors.ink, width: 1.5)
                          : null,
                    ),
                    child: Text(
                      subscribed ? '구독 중' : '구독',
                      style: EselTypography.label(
                        fontSize: 15,
                        color: subscribed ? EselColors.ink : EselColors.paper,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShelfTitle() {
    final spines = controller.viewMode == ShelfViewMode.spines;
    Widget toggle(String label, bool active) => EselPressable(
      semanticsLabel: '$label로 보기',
      onTap: active ? null : controller.toggleViewMode,
      child: SizedBox(
        height: 44,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Center(
            child: Text(
              label,
              style: EselTypography.label(
                fontSize: 14,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? EselColors.ink : EselColors.muted,
              ),
            ),
          ),
        ),
      ),
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: EselColors.ink, width: 2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('지난 호', style: EselTypography.heading(fontSize: 21)),
          ),
          toggle('표지', !spines),
          toggle('책등', spines),
        ],
      ),
    );
  }

  Widget _buildEmpty() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
    child: Text(
      widget.isOwner
          ? '아직 발행한 호가 없어요. 오늘 호를 만들면 첫 호가 여기에 꽂혀요.'
          : '아직 보여 줄 호가 없어요.',
      textAlign: TextAlign.center,
      style: EselTypography.body(color: EselColors.muted),
    ),
  );

  Widget _buildCovers(MagazineProfile profile) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = ((box.maxWidth - 40 - 2 * 8) / 3).floorToDouble();
        final h = (w * 166 / 113).roundToDouble();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final issue in profile.issues)
                SizedBox(
                  width: w,
                  child: Column(
                    children: [
                      _cover(profile, issue, w, h),
                      SizedBox(
                        height: 26,
                        child: Row(
                          children: [
                            Text(
                              issue.issueLabel,
                              style: EselTypography.meta(
                                fontSize: 11,
                                color: EselColors.ink,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: 22,
                              height: 4,
                              decoration: BoxDecoration(
                                color: EselPaints.of(issue.color).color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _cover(
    MagazineProfile profile,
    PublicIssue issue,
    double w,
    double h,
  ) {
    final local = profile.localCovers[issue.id];
    final label = '${issue.issueLabel} 표지 보기';
    if (local != null) {
      return EselPressable(
        semanticsLabel: label,
        onTap: () => widget.onSelectIssue(issue, local),
        child: SizedBox(
          width: w,
          height: h,
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: 360,
              height: 480,
              child: CoverPreview(draft: local),
            ),
          ),
        ),
      );
    }
    return EselCoverMini(
      author: issue.masthead,
      masthead: issue.masthead,
      photo: issuePhotoProvider(issue.photo),
      alt: issue.alt,
      width: w,
      height: h,
      showAuthor: false,
      semanticsLabel: label,
      photoChild: CoverPhoto(
        image: issuePhotoProvider(issue.photo),
        photoRatio: issue.photoRatio,
        face: issue.face,
        mode: issue.faceMode,
        effects: issue.faceEffects,
        paint: issue.color,
        semanticLabel: issue.alt,
      ),
      onTap: () => widget.onSelectIssue(issue, null),
    );
  }

  Widget _buildSpines(MagazineProfile profile) {
    const dark = {
      EselPaint.burgundy,
      EselPaint.olive,
      EselPaint.charcoal,
      EselPaint.cobalt,
      EselPaint.terracotta,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 5,
        runSpacing: 18,
        children: [
          for (final issue in profile.issues)
            EselPressable(
              semanticsLabel:
                  '${issue.issueLabel} · ${EselPaints.of(issue.color).nameKo} · ${issue.date.shortLabel}',
              onTap: () =>
                  widget.onSelectIssue(issue, profile.localCovers[issue.id]),
              child: Container(
                width: 22,
                height: 196,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: EselPaints.of(issue.color).color,
                  border: const Border(
                    right: BorderSide(color: Color(0x1F000000)),
                    left: BorderSide(color: Color(0x59FFFFFF)),
                  ),
                ),
                child: ExcludeSemantics(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RotatedBox(
                        quarterTurns: 1,
                        child: Text(
                          profile.masthead,
                          maxLines: 1,
                          style: EselTypography.spineOwner(
                            color: dark.contains(issue.color)
                                ? Colors.white
                                : EselColors.ink,
                          ),
                        ),
                      ),
                      RotatedBox(
                        quarterTurns: 1,
                        child: Text(
                          issue.issueLabel,
                          style: EselTypography.spineIssue(
                            color: dark.contains(issue.color)
                                ? Colors.white
                                : EselColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
