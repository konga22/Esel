import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../drafts/data/local_library.dart';
import '../../../drafts/domain/cover_draft.dart';
import '../../../drafts/presentation/cover_editor_screen.dart';

/// Shared editor. Publishing is delegated to the selected data source.
class PublishScreen extends StatefulWidget {
  final String masthead, ownerId;
  final String? challengeId, previousIssueId;
  final int currentIssueCount;
  final bool hasPublishedToday;
  final bool localDemo;
  final ValueChanged<int> onPublishSuccess;
  final VoidCallback onClose;
  final LocalLibrary library;

  /// 오늘의 후보 3색(P17). 이 밖의 색으로는 올리지 않는다.
  final List<EselPaint> candidates;

  /// 서비스 날짜로 오늘의 캔버스를 올린다(TodayController.publish).
  final Future<CoverDraft> Function(CoverDraft draft) publish;
  const PublishScreen({
    super.key,
    this.challengeId,
    this.previousIssueId,
    this.localDemo = false,
    required this.masthead,
    required this.ownerId,
    required this.currentIssueCount,
    required this.hasPublishedToday,
    required this.onPublishSuccess,
    required this.onClose,
    required this.library,
    required this.candidates,
    required this.publish,
  });
  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  late CoverDraft _initial;
  late final bool _blockedAtEntry;
  @override
  void initState() {
    super.initState();
    _blockedAtEntry = widget.hasPublishedToday;
    final drafts = widget.library.drafts.where(
      (d) => d.ownerId == widget.ownerId && d.issueNumber == 0,
    );
    // 어제 고른 색으로 저장된 초안은 오늘 후보 색으로 바꿔서 연다(P17).
    _initial = drafts.isNotEmpty
        ? (widget.candidates.contains(drafts.first.color)
              ? drafts.first
              : drafts.first.copyWith(color: widget.candidates.first))
        : CoverDraft(
            id: widget.library.newId(),
            photoPath: '',
            masthead: widget.masthead,
            ownerId: widget.ownerId,
            color: widget.candidates.first,
            updatedAt: DateTime.now(),
          );
    final previous = widget.library
        .issuesFor(widget.ownerId)
        .where((v) => v.id == widget.previousIssueId)
        .firstOrNull;
    if (previous != null && _initial.garments.isEmpty) {
      _initial = _initial.copyWith(
        garments: previous.garments
            .map((v) => v.at(null, null).forColor(false))
            .toList(),
      );
    }
    if (widget.challengeId != null) {
      _initial = _initial
          .copyWith(clearChallenge: true)
          .copyWith(
            challengeId: widget.challengeId,
            previousIssueId: widget.previousIssueId,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_blockedAtEntry) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) widget.onClose();
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: widget.onClose,
              icon: const Icon(Icons.close),
            ),
            title: const Text('오늘의 캔버스 만들기'),
          ),
          body: const Center(child: Text('오늘은 이미 한 호를 올렸어요.')),
        ),
      );
    }
    return CoverEditorScreen(
      library: widget.library,
      localDemo: widget.localDemo,
      initial: _initial,
      candidates: widget.candidates,
      onClose: widget.onClose,
      onPublish: (draft) async {
        final issue = await widget.publish(draft);
        if (mounted) widget.onPublishSuccess(issue.issueNumber);
      },
    );
  }
}
