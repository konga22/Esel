import 'package:flutter/material.dart';
import '../../../core/design/tokens.g.dart';
import '../../../core/design/typography.dart';
import '../../../core/time/service_clock.dart';
import '../../../core/time/service_date.dart';
import '../../../core/ui/esel_button.dart';
import '../../drafts/data/local_library.dart';
import '../../drafts/domain/cover_draft.dart';
import '../../media/presentation/cover_preview.dart';
import '../data/challenge_source.dart';
import '../../stand/domain/rules/same_color_rule.dart';
import '../../today/domain/rules/daily_candidates.dart';
import '../domain/challenge.dart';

/// An account-private local journal, never an alternative public colour room.
class ChallengeScreen extends StatefulWidget {
  final String ownerId;
  final LocalLibrary library;
  final ChallengeSource source;
  final ServiceClock clock;
  final VoidCallback onBack;
  final Future<void> Function(StyleChallenge, String?) onBegin;
  final SameColorViewer? viewer;
  const ChallengeScreen({
    super.key,
    required this.ownerId,
    required this.library,
    required this.source,
    required this.clock,
    required this.onBack,
    required this.onBegin,
    this.viewer,
  });
  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  List<CoverDraft>? _entries;
  List<StyleChallenge> _challenges = [];
  Map<String, List<CoverDraft>> _participants = {};
  String? _expanded;
  ServiceDate? _loadedOn;
  String? _error;
  bool _busy = false;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    widget.library.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    widget.library.removeListener(_reload);
    super.dispose();
  }

  @override
  void didUpdateWidget(ChallengeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_loadedOn != widget.clock.today ||
        oldWidget.ownerId != widget.ownerId ||
        oldWidget.viewer != widget.viewer) {
      _reload();
    }
  }

  Future<void> _reload() async {
    final request = ++_request;
    final today = widget.clock.today;
    _loadedOn = today;
    setState(() {
      _entries = null;
      _participants = {};
      _error = null;
    });
    try {
      final entries = await widget.source.mine(widget.ownerId);
      final challenges = await widget.source.current(today);
      final viewer =
          widget.viewer ??
          SameColorViewer(
            today: today,
            candidates: DailyCandidates.forDate(today),
            hasPublishedToday: widget.library.hasPublishedOn(
              widget.ownerId,
              today,
            ),
            isMinor: false,
          );
      final participants = <String, List<CoverDraft>>{};
      for (final challenge in challenges) {
        participants[challenge.id] = await widget.source.participants(
          widget.ownerId,
          viewer,
          challenge.id,
        );
      }
      if (mounted && request == _request) {
        setState(() {
          _entries = entries;
          _challenges = challenges;
          _participants = participants;
        });
      }
    } catch (_) {
      if (mounted && request == _request) {
        setState(() => _error = '참여 기록을 읽지 못했어요. 다시 불러와 주세요.');
      }
    }
  }

  Future<void> _begin(StyleChallenge challenge) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      String? previousId;
      if (challenge.restyle) {
        final past = widget.library.issuesFor(widget.ownerId).where((p) {
          final date = ServiceDate.tryParse(p.publishedOn);
          return date != null && date.isBefore(widget.clock.today);
        }).toList();
        if (past.isEmpty) {
          _message('지난 날짜의 올린 표지가 아직 없어요. 오늘의 캔버스를 남긴 뒤 다음 날 참여해 보세요.');
          return;
        }
        if (!mounted) return;
        previousId = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (ctx) => SizedBox(
            height: MediaQuery.sizeOf(ctx).height * .75,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    '같은 옷이 있는 내 지난 표지',
                    style: EselTypography.heading(fontSize: 24),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('같은 옷인지는 직접 확인해 주세요. 사진은 복제하지 않아요.'),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      for (final issue in past)
                        ListTile(
                          minVerticalPadding: 16,
                          minTileHeight: 110,
                          leading: SizedBox(
                            width: 56,
                            height: 76,
                            child: FittedBox(
                              child: SizedBox(
                                width: 240,
                                height: 320,
                                child: CoverPreview(draft: issue),
                              ),
                            ),
                          ),
                          title: Text(
                            '${issue.publishedOn} · Nº ${issue.issueNumber}',
                          ),
                          subtitle: Text(
                            [
                              issue.caption.isEmpty
                                  ? issue.masthead
                                  : issue.caption,
                              ...issue.garments.map((g) => g.label),
                            ].join(' · '),
                          ),
                          onTap: () => Navigator.pop(ctx, issue.id),
                        ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('취소'),
                ),
              ],
            ),
          ),
        );
        if (previousId == null || !mounted) return;
      }
      await widget.onBegin(challenge, previousId);
      if (mounted) await _reload();
    } on FormatException catch (error) {
      _message(error.message);
    } catch (_) {
      _message('참여를 저장하지 못했어요. 기록은 유지돼요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _detach(CoverDraft issue) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.source.detach(widget.ownerId, issue.id);
      if (mounted) await _reload();
    } catch (_) {
      _message('참여를 해제하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: EselColors.paper,
    appBar: AppBar(
      title: const Text('이번 주 주제'),
      leading: IconButton(
        tooltip: '이전 화면',
        onPressed: _busy ? null : widget.onBack,
        icon: const Icon(Icons.arrow_back),
      ),
    ),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('옷을 입는 작은 이유', style: EselTypography.heading(fontSize: 30)),
          const SizedBox(height: 12),
          const Text(
            '오늘 후보 3색과 함께, 스케치북에 새로운 이야기를 남겨요.\n로컬 시연 · 이 기기에 저장된 공개 참여 표지를 함께 봐요. 서버 사용자 목록은 아니에요.',
          ),
          for (final challenge in _challenges) ...[
            const SizedBox(height: 24),
            const Divider(),
            Text(challenge.title, style: EselTypography.heading(fontSize: 24)),
            const SizedBox(height: 8),
            Text(challenge.topic, style: EselTypography.name(fontSize: 18)),
            const SizedBox(height: 8),
            Text(challenge.period),
            const SizedBox(height: 12),
            Text(challenge.instruction),
            const SizedBox(height: 12),
            Text(
              _entries?.any((p) => p.challengeId == challenge.id) == true
                  ? '내 참여 표지가 있어요 · 아래에서 확인'
                  : '아직 참여하지 않았어요',
            ),
            const SizedBox(height: 12),
            EselButton(
              label: challenge.restyle ? '지난 표지 골라 참여하기' : '이번 주 주제에 참여하기',
              enabled: !_busy && _error == null && _entries != null,
              onTap: () => _begin(challenge),
            ),
            TextButton(
              onPressed: _error != null || _entries == null
                  ? null
                  : () => setState(() {
                      _expanded = _expanded == challenge.id
                          ? null
                          : challenge.id;
                    }),
              child: Text(
                _expanded == challenge.id
                    ? '참여 표지 접기'
                    : '${challenge.title} 참여 표지 보기',
              ),
            ),
            if (_expanded == challenge.id) ...[
              const Text('같은 색 공개 규칙을 적용한 기기 내 기록이에요. 잠긴 색은 올리기 후 확인할 수 있어요.'),
              if ((_participants[challenge.id] ?? []).isEmpty)
                const Text('지금 볼 수 있는 참여 표지가 없어요. 오늘의 캔버스로 첫 기록을 남겨 보세요.'),
              for (final issue in _participants[challenge.id] ?? <CoverDraft>[])
                _cover(issue),
            ],
          ],
          const SizedBox(height: 32),
          Text('내 참여 표지', style: EselTypography.heading(fontSize: 24)),
          const SizedBox(height: 12),
          if (_error != null) ...[
            Text(_error!),
            EselButton(label: '다시 불러오기', onTap: _reload),
          ] else if (_entries == null)
            const Center(child: CircularProgressIndicator())
          else if (_entries!.isEmpty)
            const Text(
              '첫 참여를 기다리고 있어요. 오늘 올린 호도 연결할 수 있어요.\n호수는 늘어나지 않아요. 한 호에는 한 가지 참여를 연결해요.',
            )
          else
            for (final entry in _entries!) ...[
              const SizedBox(height: 20),
              Text(
                '${StyleChallenge.resolve(entry.challengeId)?.title ?? '지난 참여'} · ${entry.publishedOn}',
              ),
              const SizedBox(height: 8),
              if (StyleChallenge.resolve(entry.challengeId)
                  case final challenge?)
                Text(
                  '${challenge.topic} · ${challenge.isOpen(widget.clock.today) ? '진행 중' : '마감'}',
                ),
              const SizedBox(height: 12),
              if (entry.previousIssueId case final previousId?) ...[
                const Text('지난 착장 → 오늘 착장 · 날짜와 사진, 문구로 차이를 비교해요'),
                const SizedBox(height: 8),
                if (widget.library
                        .issuesFor(widget.ownerId)
                        .where((p) => p.id == previousId)
                        .firstOrNull
                    case final previous?)
                  _cover(previous)
                else
                  const Text('연결된 표지가 없어 비교할 수 없어요.'),
              ],
              _cover(entry),
              TextButton(
                onPressed: _busy ? null : () => _detach(entry),
                child: const Text('이 호의 참여 해제 · 올리기본은 유지'),
              ),
              const Divider(),
            ],
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
  Widget _cover(CoverDraft issue) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${issue.masthead} · ${issue.publishedOn} · Nº ${issue.issueNumber}',
        ),
        const SizedBox(height: 8),
        AspectRatio(aspectRatio: .75, child: CoverPreview(draft: issue)),
        if (issue.caption.isNotEmpty) Text(issue.caption),
      ],
    ),
  );
}
