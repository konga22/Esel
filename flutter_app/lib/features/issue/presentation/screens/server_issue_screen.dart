import 'package:flutter/material.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/http_client.dart';
import '../../../../core/ui/esel_paint_asset.dart';
import '../../data/sources/issue_remote_source.dart';
import '../../domain/models/server_issue.dart';
import '../../../reactions/domain/models/reaction_state.dart';
import '../../../magazine/presentation/screens/server_magazine_screen.dart';

class ServerIssueScreen extends StatefulWidget {
  final AppHttpClient http;
  final String id;
  final bool isOwner;
  const ServerIssueScreen({
    super.key,
    required this.http,
    required this.id,
    this.isOwner = false,
  });
  @override
  State<ServerIssueScreen> createState() => _ServerIssueScreenState();
}

class _ServerIssueScreenState extends State<ServerIssueScreen> {
  late final source = IssueRemoteSource(widget.http);
  final _text = TextEditingController();
  ServerIssue? _issue;
  List<ReaderLine> _lines = [];
  String? _cursor, _error;
  OwnerIssueReactions? _owner;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  String _message(Object e) =>
      e is Failure ? e.message : '요청을 완료하지 못했어요. 다시 시도해 주세요.';
  Future<void> _load() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _issue = null;
      _lines = [];
      _owner = null;
      _cursor = null;
    });
    try {
      final issue = await source.issue(widget.id);
      final page = await source.lines(widget.id);
      final owner = widget.isOwner
          ? await source.ownerReactions(widget.id)
          : null;
      if (mounted) {
        setState(() {
          _issue = issue;
          _lines = page.items;
          _cursor = page.nextCursor;
          _owner = owner;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _react(bool like) async {
    final issue = _issue;
    if (issue == null || _busy) return;
    setState(() => _busy = true);
    try {
      await source.setReaction(
        issue.id,
        like: like,
        enabled: !(like ? issue.liked : issue.scrapped),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _issue = null;
          _lines = [];
          _owner = null;
          _error = _message(e);
        });
      }
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await _load();
  }

  Future<void> _more() async {
    if (_busy || _cursor == null) return;
    setState(() => _busy = true);
    try {
      final page = await source.lines(widget.id, cursor: _cursor);
      if (mounted) {
        setState(() {
          _lines = {
            for (final line in [..._lines, ...page.items]) line.id: line,
          }.values.toList();
          _cursor = page.nextCursor;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _issue = null;
          _lines = [];
          _owner = null;
          _error = _message(e);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (_busy || text.isEmpty || text.runes.length > 60) return;
    setState(() => _busy = true);
    try {
      await source.addLine(widget.id, text);
      _text.clear();
    } catch (e) {
      if (mounted) {
        setState(() => _error = _message(e));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_message(e))));
      }
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (mounted) FocusScope.of(context).unfocus();
    await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('표지 펼쳐 보기')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_busy) const Center(child: CircularProgressIndicator()),
          if (_error != null) ...[
            Text(_error!),
            TextButton(
              onPressed: _busy ? null : _load,
              child: const Text('다시 시도'),
            ),
          ],
          if (_issue case final issue?) ...[
            Text(issue.masthead, style: EselTypography.headlineLarge),
            Text(
              'Nº ${issue.number.toString().padLeft(3, '0')} · ${issue.date.label}',
            ),
            const SizedBox(height: 24),
            EselPaintAsset(paint: issue.color, width: 56, showLabel: true),
            const SizedBox(height: 24),
            const AspectRatio(
              aspectRatio: 3 / 2,
              child: Center(child: Text('사진 제공 준비 중')),
            ),
            Text(issue.caption, style: EselTypography.bodyMedium),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: _busy ? null : () => _react(true),
                  child: Text(issue.liked ? '좋아요 취소' : '좋아요'),
                ),
                OutlinedButton(
                  onPressed: _busy ? null : () => _react(false),
                  child: Text(issue.scrapped ? '스크랩 취소' : '스크랩'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => ServerMagazineScreen(
                        http: widget.http,
                        mine: widget.isOwner,
                        masthead: issue.masthead,
                      ),
                    ),
                  ),
                  child: const Text('스케치북 보기'),
                ),
              ],
            ),
            if (_owner case final stats?) ...[
              const Divider(),
              const Text('내 표지의 반응 · 나에게만 보여요'),
              Text(
                '좋아요 ${stats.likes} · 스크랩 ${stats.scraps} · 독자 한 줄 ${stats.lines}',
              ),
              if (stats.likeMastheads.isNotEmpty)
                Text('좋아요: ${stats.likeMastheads.join(', ')}'),
              if (stats.scrapMastheads.isNotEmpty)
                Text('스크랩: ${stats.scrapMastheads.join(', ')}'),
            ],
            const Divider(),
            Text('독자 한 줄', style: EselTypography.headlineSmall),
            if (_lines.isEmpty) const Text('아직 한 줄이 없어요.'),
            for (final line in _lines)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(line.text),
                subtitle: Text(line.authorMasthead),
              ),
            if (_cursor != null)
              TextButton(
                onPressed: _busy ? null : _more,
                child: const Text('한 줄 더 보기'),
              ),
            TextField(
              controller: _text,
              maxLength: 60,
              decoration: const InputDecoration(labelText: '한 줄 남기기'),
            ),
            TextButton(
              onPressed: _busy ? null : _send,
              child: const Text('남기기'),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    ),
  );
}
