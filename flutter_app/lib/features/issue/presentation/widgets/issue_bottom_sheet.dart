import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/ui/esel_paint_asset.dart';
import '../../../../core/ui/esel_pressable.dart';
import '../../../reactions/presentation/controllers/reactions_controller.dart';
import '../../domain/models/public_issue.dart';
import '../issue_photo.dart';

class IssueBottomSheet extends StatefulWidget {
  final PublicIssue issue;
  final bool isOwner;

  /// 한 줄을 남기는 사람(로그인한 나)의 제호.
  final String readerMasthead;
  final ReactionsController reactionsController;
  final VoidCallback onOpenAuthorShelf;
  final VoidCallback onShare;
  final VoidCallback onReport;

  const IssueBottomSheet({
    super.key,
    required this.issue,
    required this.isOwner,
    required this.readerMasthead,
    required this.reactionsController,
    required this.onOpenAuthorShelf,
    required this.onShare,
    required this.onReport,
  });

  static Future<void> show(
    BuildContext context, {
    required PublicIssue issue,
    required bool isOwner,
    required String readerMasthead,
    required ReactionsController reactionsController,
    required VoidCallback onOpenAuthorShelf,
    required VoidCallback onShare,
    required VoidCallback onReport,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.92,
        child: IssueBottomSheet(
          issue: issue,
          isOwner: isOwner,
          readerMasthead: readerMasthead,
          reactionsController: reactionsController,
          onOpenAuthorShelf: onOpenAuthorShelf,
          onShare: onShare,
          onReport: onReport,
        ),
      ),
    );
  }

  @override
  State<IssueBottomSheet> createState() => _IssueBottomSheetState();
}

class _IssueBottomSheetState extends State<IssueBottomSheet> {
  final _lineTextController = TextEditingController();

  @override
  void dispose() {
    _lineTextController.dispose();
    super.dispose();
  }

  void _submitReaderLine() {
    final text = _lineTextController.text;
    final success = widget.reactionsController.addReaderLine(
      issueId: widget.issue.id,
      text: text,
      authorMasthead: widget.readerMasthead,
    );
    if (success) {
      _lineTextController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.reactionsController,
      builder: (context, _) {
        final rc = widget.reactionsController;
        final isLiked = rc.isLiked(widget.issue.id);
        final isScrapped = rc.isScrapped(widget.issue.id);
        final readerLines = rc.getReaderLines(widget.issue.id);

        return Container(
          decoration: const BoxDecoration(
            color: EselTokens.paper,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(EselTokens.radius24),
            ),
          ),
          child: Column(
            children: [
              _buildTopHandle(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: EselTokens.space24,
                  ),
                  children: [
                    _buildSpreadHeader(),
                    const SizedBox(height: EselTokens.space20),
                    _buildTwoPhotos(),
                    const SizedBox(height: EselTokens.space20),
                    _buildCaptionAndActions(isLiked, isScrapped),
                    const SizedBox(height: EselTokens.space20),
                    if (widget.isOwner) _buildOwnerStatsCard(rc),
                    const SizedBox(height: EselTokens.space24),
                    _buildReaderLinesSection(readerLines),
                    const SizedBox(height: EselTokens.space40),
                  ],
                ),
              ),
              _buildInputBar(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopHandle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: EselTokens.borderDefault,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildSpreadHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        EselPressable(
          onTap: () {
            Navigator.of(context).pop();
            widget.onOpenAuthorShelf();
          },
          child: Row(
            children: [
              Text(
                widget.issue.masthead,
                style: EselTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: EselTokens.ink,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: EselTokens.inkSubtle,
              ),
            ],
          ),
        ),
        Row(
          children: [
            EselPaintAsset(paint: widget.issue.color, width: 24),
            const SizedBox(width: 8),
            Text(widget.issue.issueLabel, style: EselTypography.monoSmall),
            const SizedBox(width: 12),
            EselPressable(
              onTap: widget.onReport,
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(
                  Icons.more_horiz,
                  size: 22,
                  color: EselTokens.inkMuted,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 펼침면 사진 2장: 표지 사진과 같은 사진의 디테일(디자인 C3).
  Widget _buildTwoPhotos() {
    final photo = issuePhotoProvider(widget.issue.photo);
    Widget frame(Widget child) => Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(EselRadius.spreadPhoto),
        child: child,
      ),
    );
    return SizedBox(
      height: 280,
      child: Row(
        children: [
          frame(
            Image(
              image: photo,
              fit: BoxFit.cover,
              height: double.infinity,
              semanticLabel: widget.issue.alt,
              errorBuilder: (_, _, _) =>
                  const ColoredBox(color: EselColors.photo),
            ),
          ),
          const SizedBox(width: 8),
          frame(
            ClipRect(
              child: Transform.scale(
                scale: 2.6,
                alignment: const Alignment(0.1, 0.6),
                child: Image(
                  image: photo,
                  fit: BoxFit.cover,
                  height: double.infinity,
                  width: double.infinity,
                  semanticLabel: '${widget.issue.alt}의 디테일',
                  errorBuilder: (_, _, _) =>
                      const ColoredBox(color: EselColors.photo),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptionAndActions(bool isLiked, bool isScrapped) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            widget.issue.caption,
            style: EselTypography.bodyLarge.copyWith(height: 1.5),
          ),
        ),
        const SizedBox(width: 16),
        Row(
          children: [
            EselPressable(
              onTap: () =>
                  widget.reactionsController.toggleLike(widget.issue.id),
              child: AnimatedScale(
                scale: isLiked ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 160),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? EselTokens.semanticRed : EselTokens.ink,
                    size: 24,
                  ),
                ),
              ),
            ),
            EselPressable(
              onTap: () =>
                  widget.reactionsController.toggleScrap(widget.issue.id),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  isScrapped ? Icons.bookmark : Icons.bookmark_border,
                  color: isScrapped ? EselTokens.ink : EselTokens.ink,
                  size: 24,
                ),
              ),
            ),
            EselPressable(
              onTap: widget.onShare,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.share_outlined,
                  color: EselTokens.ink,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOwnerStatsCard(ReactionsController rc) {
    final stats = rc.getOwnerStats(widget.issue.id);
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('좋아요', stats.likeCount.toString()),
              _buildStatItem('스크랩', stats.scrapCount.toString()),
              _buildStatItem('독자 한 줄', stats.readerLineCount.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
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

  Widget _buildReaderLinesSection(List<dynamic> readerLines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '독자 한 줄 (${readerLines.length})',
          style: EselTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (readerLines.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              '첫 독자 한 줄을 남겨보세요.',
              style: EselTypography.bodySmall.copyWith(
                color: EselTokens.inkSubtle,
              ),
            ),
          )
        else
          ...readerLines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EselTokens.paperWarm,
                  borderRadius: BorderRadius.circular(EselTokens.radius12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          line.authorMasthead,
                          style: EselTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '방금 전',
                          style: EselTypography.caption.copyWith(
                            color: EselTokens.inkSubtle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(line.text, style: EselTypography.bodyMedium),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: EselTokens.space20,
        right: EselTokens.space20,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: EselTokens.paper,
        border: Border(top: BorderSide(color: EselTokens.borderDefault)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _lineTextController,
              maxLength: 60,
              decoration: InputDecoration(
                hintText: '이 호에 독자 한 줄 남기기...',
                counterText: '',
                filled: true,
                fillColor: EselTokens.paperWarm,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(EselTokens.radiusPill),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          EselPressable(
            onTap: _submitReaderLine,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: EselTokens.ink,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_upward,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
