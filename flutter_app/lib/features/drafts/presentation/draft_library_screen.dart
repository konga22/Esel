import 'package:flutter/material.dart';
import '../../../core/time/service_clock.dart';
import '../../../core/time/service_date.dart';
import '../data/local_library.dart';
import '../domain/cover_draft.dart';
import 'local_calendar_screen.dart';

/// 현재 계정의 기기 초안만 표시한다. 소유자가 없는 이전 자료는 자동 인계하지 않는다.
class DraftLibraryScreen extends StatefulWidget {
  final LocalLibrary library;
  final String ownerId;
  final ServiceClock clock;
  final ValueChanged<CoverDraft> onEdit;
  const DraftLibraryScreen({
    super.key,
    required this.library,
    required this.ownerId,
    required this.clock,
    required this.onEdit,
  });
  @override
  State<DraftLibraryScreen> createState() => _DraftLibraryScreenState();
}

class _DraftLibraryScreenState extends State<DraftLibraryScreen> {
  ServiceDate? _date;
  Future<void> _delete(CoverDraft draft) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이 초안을 지울까요?'),
        content: const Text('이 초안의 편집 내용이 지워져요. 사진첩 원본은 남아요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('초안 삭제'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    if (draft.ownerId != widget.ownerId || draft.issueNumber != 0) return;
    try {
      await widget.library.delete(draft.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('초안을 지우지 못했어요. 다시 시도해 주세요.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.library,
    builder: (context, _) {
      final drafts =
          widget.library.drafts
              .where(
                (v) =>
                    v.ownerId == widget.ownerId &&
                    v.issueNumber == 0 &&
                    (_date == null || ServiceDate.of(v.updatedAt) == _date),
              )
              .toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      final legacy = widget.library.drafts
          .where((v) => v.ownerId.isEmpty)
          .length;
      return Scaffold(
        appBar: AppBar(title: const Text('기기 초안')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('현재 계정이 이 기기에 저장한 초안이에요. 서버에 올린 캔버스와는 별도예요.'),
            if (widget.library.loadError case final message?) ...[
              Text(message),
              TextButton(
                onPressed: widget.library.directory == null
                    ? null
                    : widget.library.loadForStartup,
                child: const Text('보관함 다시 읽기'),
              ),
            ] else ...[
              TextButton(
                onPressed: () async {
                  final date = await Navigator.push<DateTime>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LocalCalendarScreen(
                        library: widget.library,
                        ownerId: widget.ownerId,
                        clock: widget.clock,
                      ),
                    ),
                  );
                  if (mounted) {
                    setState(
                      () => _date = date == null
                          ? null
                          : ServiceDate(date.year, date.month, date.day),
                    );
                  }
                },
                child: const Text('초안 달력'),
              ),
              if (_date != null)
                TextButton(
                  onPressed: () => setState(() => _date = null),
                  child: const Text('날짜 필터 해제'),
                ),
              if (drafts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('저장한 초안이 없어요. 만들기에서 사진을 편집하고 저장해 보세요.'),
                ),
              for (final draft in drafts)
                ListTile(
                  key: ValueKey('draft-${draft.id}'),
                  title: Text(draft.masthead),
                  subtitle: Text(
                    '${ServiceDate.of(draft.updatedAt).label} · ${draft.caption}',
                  ),
                  onTap: () => widget.onEdit(draft),
                  trailing: IconButton(
                    tooltip: '초안 삭제',
                    onPressed: () => _delete(draft),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              if (legacy > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    '소유자를 확인할 수 없는 이전 기기 자료 $legacy개는 원본을 보존했어요. 현재 계정에 자동으로 연결하거나 삭제하지 않아요.',
                  ),
                ),
            ],
          ],
        ),
      );
    },
  );
}
