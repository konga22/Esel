import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../drafts/data/local_library.dart';
import '../../../drafts/domain/cover_draft.dart';
import '../../../drafts/presentation/cover_editor_screen.dart';
import '../controllers/publishing_controller.dart';

/// DEV-03 local adapter. The real server entry point is kept separately.
class PublishScreen extends StatefulWidget {
  final PublishingController controller;
  final String masthead, ownerId;
  final int currentIssueCount;
  final bool hasPublishedToday;
  final ValueChanged<int> onPublishSuccess;
  final VoidCallback onClose;
  final LocalLibrary library;
  const PublishScreen({
    super.key,
    required this.controller,
    required this.masthead,
    required this.ownerId,
    required this.currentIssueCount,
    required this.hasPublishedToday,
    required this.onPublishSuccess,
    required this.onClose,
    required this.library,
  });
  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  late final CoverDraft _initial;
  @override
  void initState() {
    super.initState();
    final drafts = widget.library.drafts.where(
      (d) => d.ownerId == widget.ownerId && d.issueNumber == 0,
    );
    _initial = drafts.isNotEmpty
        ? drafts.first
        : CoverDraft(
            id: widget.library.newId(),
            photoPath: '',
            masthead: widget.masthead,
            ownerId: widget.ownerId,
            color: EselPaint.camel,
            updatedAt: DateTime.now(),
          );
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
      candidates: const [EselPaint.camel, EselPaint.lilac, EselPaint.olive],
      onClose: widget.onClose,
      onPublish: (draft) async {
        final issue = await widget.library.publish(draft, widget.ownerId);
        widget.controller.setColor(issue.color.name);
        widget.controller.setCaption(issue.caption);
        if (mounted) widget.onPublishSuccess(issue.issueNumber);
      },
    );
  }
}
