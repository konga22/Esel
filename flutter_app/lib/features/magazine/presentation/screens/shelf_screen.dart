import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/ui/esel_paint_asset.dart';
import '../../../drafts/domain/cover_draft.dart';
import '../../../issue/domain/models/public_issue.dart';
import '../../../issue/presentation/canvas_photo.dart';
import '../../../reactions/presentation/controllers/reactions_controller.dart';
import '../../../stand/domain/rules/same_color_rule.dart';
import '../controllers/magazine_controller.dart';

/// C5·M1 공통 스케치북. 서버/로컬에 따라 다른 화면을 만들지 않는다.
class ShelfScreen extends StatefulWidget {
  final String ownerId;
  final String? masthead;
  final bool isOwner;
  final MagazineController controller;
  final ReactionsController reactionsController;
  final SameColorViewer viewer;
  final String? viewerId;
  final void Function(PublicIssue, CoverDraft?) onSelectIssue;
  final VoidCallback onBack;
  final ValueChanged<PublicIssue>? onShareIssue;
  final Map<String, VoidCallback> actions;
  const ShelfScreen({
    super.key,
    required this.ownerId,
    required this.controller,
    required this.reactionsController,
    required this.viewer,
    required this.onSelectIssue,
    required this.onBack,
    this.onShareIssue,
    this.viewerId,
    this.masthead,
    this.isOwner = false,
    this.actions = const {},
  });
  @override
  State<ShelfScreen> createState() => _ShelfScreenState();
}

class _ShelfScreenState extends State<ShelfScreen> {
  MagazineProfile? _last;
  void _configure() => widget.controller.configure(
    ownerId: widget.ownerId,
    viewer: widget.viewer,
    viewerId: widget.viewerId,
    masthead: widget.masthead,
  );
  void _profileChanged() {
    final profile = widget.controller.profile;
    if (profile != null && !identical(profile, _last)) {
      _last = profile;
      if (profile.subscribed != null) {
        widget.reactionsController.seedSubscription(
          profile.ownerId,
          profile.subscribed!,
        );
      }
      for (final issue in profile.issues) {
        widget.reactionsController.seedIssue(issue);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_profileChanged);
    _configure();
    _profileChanged();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_profileChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(ShelfScreen old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_profileChanged);
      widget.controller.addListener(_profileChanged);
      _last = null;
    }
    _configure();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([
      widget.controller,
      widget.reactionsController,
    ]),
    builder: (context, _) {
      final profile = widget.controller.profile;
      final first = profile?.issues.firstOrNull;
      return Scaffold(
        backgroundColor: EselColors.paper,
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 130),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: '뒤로',
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back_ios_new),
                    ),
                    const Spacer(),
                    const Text('ESEL · 스케치북'),
                    IconButton(
                      tooltip: '새로고침',
                      onPressed: () => widget.controller.load(),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
              if (widget.controller.isLoading)
                const Center(child: CircularProgressIndicator()),
              if (widget.controller.errorMessage case final error?)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(error),
                      TextButton(
                        onPressed: () => widget.controller.load(),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
              if (profile != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: EselColors.photo,
                            child: Text(
                              profile.masthead.isEmpty
                                  ? 'E'
                                  : profile.masthead[0].toUpperCase(),
                              style: EselTypography.name(fontSize: 30),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              profile.masthead,
                              style: EselTypography.name(fontSize: 64),
                              maxLines: 2,
                            ),
                          ),
                          if (!widget.isOwner)
                            OutlinedButton(
                              onPressed: () => widget.reactionsController
                                  .toggleSubscription(profile.ownerId),
                              child: Text(
                                widget.reactionsController.isSubscribed(
                                      profile.ownerId,
                                    )
                                    ? '구독중'
                                    : '구독',
                              ),
                            ),
                        ],
                      ),
                      if (profile.bio.isNotEmpty) Text(profile.bio),
                      const SizedBox(height: 12),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          if (profile.todayColor != null)
                            EselPaintAsset(
                              paint: profile.todayColor!,
                              width: 36,
                            ),
                          Text(
                            '${profile.todayColor == null ? '오늘의 색은 아직 없어요' : '오늘은 ${EselPaints.of(profile.todayColor!).nameKo}'} · 캔버스 ${profile.totalIssues}장',
                          ),
                        ],
                      ),
                      if (widget.isOwner)
                        Wrap(
                          spacing: 8,
                          children: [
                            if (first != null)
                              TextButton(
                                onPressed: () => widget.onSelectIssue(
                                  first,
                                  profile.localCovers[first.id],
                                ),
                                child: const Text('내 캔버스의 반응 보기'),
                              ),
                            for (final entry in widget.actions.entries)
                              TextButton(
                                onPressed: entry.value,
                                child: Text(entry.key),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (profile.issues.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('아직 볼 수 있는 캔버스가 없어요.'),
                  ),
                for (final issue in profile.issues) ...[
                  InkWell(
                    onTap: () => widget.onSelectIssue(
                      issue,
                      profile.localCovers[issue.id],
                    ),
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: CanvasPhoto(issue: issue),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    '${issue.issueLabel} · ${issue.date.shortLabel}',
                                  ),
                                  EselPaintAsset(paint: issue.color, width: 28),
                                ],
                              ),
                            ),
                            if (widget.isOwner)
                              IconButton(
                                tooltip: '공유',
                                onPressed: widget.onShareIssue == null
                                    ? null
                                    : () => widget.onShareIssue!(issue),
                                icon: const Icon(Icons.ios_share),
                              )
                            else ...[
                              IconButton(
                                tooltip: '좋아요',
                                onPressed: () => widget.reactionsController
                                    .toggleLike(issue.id),
                                icon: Icon(
                                  widget.reactionsController.isLiked(issue.id)
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                ),
                              ),
                              IconButton(
                                tooltip: '자세히 보기',
                                onPressed: () => widget.onSelectIssue(
                                  issue,
                                  profile.localCovers[issue.id],
                                ),
                                icon: const Icon(Icons.chat_bubble_outline),
                              ),
                              IconButton(
                                tooltip: '저장',
                                onPressed: () => widget.reactionsController
                                    .toggleScrap(issue.id),
                                icon: Icon(
                                  widget.reactionsController.isScrapped(
                                        issue.id,
                                      )
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          issue.caption,
                          style: EselTypography.body(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
                if (widget.controller.moreError case final message?)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(message, key: const Key('magazine-more-error')),
                  ),
                if (profile.nextCursor != null)
                  TextButton(
                    onPressed: widget.controller.isLoadingMore
                        ? null
                        : () => widget.controller.load(more: true),
                    child: Text(
                      widget.controller.moreError != null
                          ? '더 보기 다시 시도'
                          : widget.controller.isLoadingMore
                          ? '불러오는 중…'
                          : '이전 캔버스 더 보기',
                    ),
                  ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
