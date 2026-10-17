import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../drafts/data/local_library.dart';
import '../../../drafts/domain/cover_draft.dart';
import '../../../drafts/presentation/cover_editor_screen.dart';

/// DEV-03 local adapter. The real server entry point is kept separately.
class PublishScreen extends StatefulWidget {
  final String masthead, ownerId;
  final String? challengeId, previousIssueId;
  final int currentIssueCount;
  final bool hasPublishedToday;
  final ValueChanged<int> onPublishSuccess;
  final VoidCallback onClose;
  final LocalLibrary library;

  /// 오늘의 후보 3색(P17). 이 밖의 색으로는 발행하지 않는다.
  final List<EselPaint> candidates;

  /// 서비스 날짜로 오늘 호를 발행한다(TodayController.publish).
  final Future<CoverDraft> Function(CoverDraft draft) publish;
  const PublishScreen({
    super.key,
    this.challengeId,
    this.previousIssueId,
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
  @override
  void initState() {
    super.initState();
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
    if (widget.hasPublishedToday) {
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
            title: const Text('오늘 호 만들기'),
          ),
          body: const Center(child: Text('오늘은 이미 한 호를 발행했어요.')),
        ),
      );
    }
    return CoverEditorScreen(
      library: widget.library,
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
