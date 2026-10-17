import 'package:flutter/material.dart';
import '../../../core/design/tokens.g.dart';
import '../../../core/design/typography.dart';
import '../../../core/time/service_clock.dart';
import '../../../core/ui/esel_button.dart';
import '../../drafts/data/local_library.dart';
import '../../drafts/domain/cover_draft.dart';
import '../../media/presentation/cover_preview.dart';
import '../../stand/domain/rules/same_color_rule.dart';
import '../data/collection_source.dart';
import '../domain/cover_collection.dart';

class CollectionScreen extends StatefulWidget {
  final String ownerId;
  final CollectionSource source;
  final LocalLibrary library;
  final SameColorViewer viewer;
  final ServiceClock clock;
  final VoidCallback onBack;
  const CollectionScreen({
    super.key,
    required this.ownerId,
    required this.source,
    required this.library,
    required this.viewer,
    required this.clock,
    required this.onBack,
  });
  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  late CollectionPeriod _period;
  List<FeaturedCover>? _selected;
  List<CoverDraft> _available = [];
  String? _error;
  bool _busy = false, _editing = false;
  int _request = 0;
  final Map<String, String> _draftReasons = {};
  @override
  void initState() {
    super.initState();
    _period = CollectionPeriod.at(CollectionUnit.day, widget.clock.today);
    widget.library.addListener(_reload);
    _reload();
  }

  @override
  void didUpdateWidget(CollectionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ownerId != widget.ownerId ||
        oldWidget.viewer != widget.viewer) {
      _reload();
    }
  }

  @override
  void dispose() {
    widget.library.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    final request = ++_request;
    setState(() {
      _selected = null;
      _available = [];
      _error = null;
    });
    try {
      final available = await widget.source.available(
        widget.ownerId,
        widget.viewer,
        _period,
      );
      final selected = await widget.source.selected(
        widget.ownerId,
        widget.viewer,
        _period,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _available = available;
        _selected = selected;
      });
    } catch (_) {
      if (mounted && request == _request) {
        setState(() => _error = '특집을 불러오지 못했어요. 다시 시도해 주세요.');
      }
    }
  }

  void _move(CollectionPeriod period) {
    if (_busy || period.start.isAfter(widget.clock.today)) return;
    setState(() => _period = period);
    _reload();
  }

  Future<void> _select(CoverDraft issue, String? existing) async {
    if (_busy) return;
    final reasonKey = '${_period.key}:${issue.id}';
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _SelectionReasonSheet(
        initial: _draftReasons[reasonKey] ?? existing ?? '',
      ),
    );
    if (reason == null || !mounted) return;
    _draftReasons[reasonKey] = reason;
    setState(() => _busy = true);
    try {
      await widget.source.select(
        widget.ownerId,
        widget.viewer,
        _period,
        issue.id,
        reason,
      );
      _draftReasons.remove(reasonKey);
      await _reload();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('저장하지 못했어요. 표지의 공개 상태를 확인하고 다시 시도해 주세요.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(FeaturedCover entry) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.source.remove(widget.ownerId, _period, entry.issue.id);
      await _reload();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('특집에서 빼지 못했어요. 다시 시도해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _cover(CoverDraft issue) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '${issue.masthead} · ${issue.publishedOn} · Nº ${issue.issueNumber}',
      ),
      const SizedBox(height: 8),
      AspectRatio(aspectRatio: .75, child: CoverPreview(draft: issue)),
      if (issue.caption.isNotEmpty) Text(issue.caption),
    ],
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: EselColors.paper,
    appBar: AppBar(
      leading: IconButton(
        onPressed: widget.onBack,
        icon: const Icon(Icons.arrow_back),
        tooltip: '뒤로',
      ),
      title: const Text('표지 특집'),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(_period.title, style: EselTypography.heading(fontSize: 30)),
          const SizedBox(height: 8),
          const Text(
            '일·주·월의 착장을 이유와 함께 소개해요.\n내가 엮는 로컬 특집 · 기기의 공개 발행 기록만 사용해요. 서버 운영자의 공식 선정이나 공개 발행은 아니에요.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final unit in CollectionUnit.values)
                ChoiceChip(
                  label: Text(switch (unit) {
                    CollectionUnit.day => '일간',
                    CollectionUnit.week => '주간',
                    CollectionUnit.month => '월간',
                  }),
                  selected: _period.unit == unit,
                  onSelected: _busy
                      ? null
                      : (_) => _move(
                          CollectionPeriod.at(unit, widget.clock.today),
                        ),
                ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: _busy ? null : () => _move(_period.move(-1)),
                icon: const Icon(Icons.chevron_left),
                tooltip: '이전 기간',
              ),
              Expanded(child: Text(_period.label, textAlign: TextAlign.center)),
              IconButton(
                onPressed:
                    _busy || _period.move(1).start.isAfter(widget.clock.today)
                    ? null
                    : () => _move(_period.move(1)),
                icon: const Icon(Icons.chevron_right),
                tooltip: '다음 기간',
              ),
            ],
          ),
          const Text('서울 시간 기준 · 공개 규칙을 먼저 적용하며 좋아요·구독자 수는 선정에 사용하지 않아요.'),
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() => _editing = !_editing),
            child: Text(_editing ? '특집 보기로 돌아가기' : '공개 표지 골라 특집 편집'),
          ),
          if (_error != null) ...[
            Text(_error!),
            EselButton(label: '다시 불러오기', onTap: _reload),
          ] else if (_selected == null)
            const Center(child: CircularProgressIndicator())
          else if (_editing) ...[
            if (_available.isEmpty)
              const Text(
                '이 기간에 볼 수 있는 발행 표지가 없어요. 먼저 착장을 발행하거나 지난 기간을 골라 보세요.',
              ),
            for (final issue in _available) ...[
              const SizedBox(height: 24),
              _cover(issue),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _select(
                        issue,
                        _selected!
                            .where((e) => e.issue.id == issue.id)
                            .firstOrNull
                            ?.reason,
                      ),
                child: Text(
                  _selected!.any((e) => e.issue.id == issue.id)
                      ? '선정 이유 수정'
                      : '이 표지를 특집에 담기',
                ),
              ),
            ],
          ] else ...[
            if (_selected!.isEmpty)
              const Text(
                '아직 엮은 표지가 없어요. 공개 표지를 고르고 소개할 이유를 남겨 보세요. 삭제되거나 공개되지 않는 표지는 표시하지 않아요.',
              ),
            for (final entry in _selected!) ...[
              const SizedBox(height: 24),
              _cover(entry.issue),
              const SizedBox(height: 8),
              Text('선정 이유 · ${entry.reason}'),
              Wrap(
                children: [
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => _select(entry.issue, entry.reason),
                    child: const Text('이유 수정'),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => _remove(entry),
                    child: const Text('특집에서 빼기 · 발행본 유지'),
                  ),
                ],
              ),
            ],
          ],
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

class _SelectionReasonSheet extends StatefulWidget {
  final String initial;
  const _SelectionReasonSheet({required this.initial});
  @override
  State<_SelectionReasonSheet> createState() => _SelectionReasonSheetState();
}

class _SelectionReasonSheetState extends State<_SelectionReasonSheet> {
  late final TextEditingController text;
  @override
  void initState() {
    super.initState();
    text = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      20 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('이 표지를 소개하는 이유', style: EselTypography.heading(fontSize: 26)),
        const SizedBox(height: 12),
        const Text(
          '주제 적합성·색 활용·스타일 다양성 등을 직접 판단해 적어요. 자동 점수나 좋아요 순위는 사용하지 않아요.',
        ),
        Wrap(
          spacing: 6,
          children: [
            for (final reason in selectionReasons)
              ActionChip(
                label: Text(reason),
                onPressed: () => text.text = reason,
              ),
          ],
        ),
        TextField(
          key: const Key('collection-reason'),
          controller: text,
          maxLength: 120,
          maxLines: 3,
          decoration: const InputDecoration(labelText: '선정 이유'),
        ),
        EselButton(
          label: '특집에 저장',
          onTap: () {
            try {
              Navigator.pop(context, validateSelectionReason(text.text));
            } on FormatException catch (e) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(e.message)));
            }
          },
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
      ],
    ),
  );
}
