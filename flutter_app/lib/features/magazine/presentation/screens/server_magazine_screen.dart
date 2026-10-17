import 'package:flutter/material.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/http_client.dart';
import '../../../../core/ui/esel_paint_asset.dart';
import '../../data/sources/magazine_remote_source.dart';
import '../../domain/models/server_magazine.dart';
import '../../../issue/domain/models/server_issue.dart';
import '../../../issue/presentation/screens/server_issue_screen.dart';

class ServerMagazineScreen extends StatefulWidget {
  final AppHttpClient http;
  final bool mine;
  final String? masthead;
  const ServerMagazineScreen({
    super.key,
    required this.http,
    required this.mine,
    this.masthead,
  });
  @override
  State<ServerMagazineScreen> createState() => _ServerMagazineScreenState();
}

class _ServerMagazineScreenState extends State<ServerMagazineScreen> {
  late final source = MagazineRemoteSource(widget.http);
  ServerMagazine? _magazine;
  List<ServerIssue> _issues = [];
  String? _error;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      if (!more) {
        _magazine = null;
        _issues = [];
      }
    });
    try {
      final result = await source.page(
        mine: widget.mine,
        masthead: widget.masthead,
        cursor: more ? _magazine?.page.nextCursor : null,
      );
      if (!mounted) return;
      setState(() {
        _magazine = result;
        final incoming = [
          if (!more && result.today != null) result.today!,
          ...result.page.items,
        ];
        final unique = {
          for (final v in [..._issues, ...incoming]) v.id: v,
        };
        _issues = unique.values.toList();
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _magazine = null;
          _issues = [];
          _error = e is Failure ? e.message : '스케치북을 불러오지 못했어요.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _subscribe() async {
    final previous = _magazine;
    if (previous == null || _busy) return;
    setState(() => _busy = true);
    try {
      await source.subscribe(previous.masthead, !previous.subscribed);
    } catch (e) {
      if (mounted) {
        setState(() {
          _magazine = null;
          _issues = [];
          _error = e is Failure ? e.message : '구독을 저장하지 못했어요.';
        });
      }
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.mine ? '내 스케치북' : widget.masthead ?? '스케치북'),
      actions: [
        IconButton(
          tooltip: '새로고침',
          onPressed: _busy ? null : () => _load(),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_magazine != null) ...[
            Text(_magazine!.masthead, style: EselTypography.headlineLarge),
            Text('발행한 호 ${_magazine!.issueCount}권'),
            if (!widget.mine)
              OutlinedButton(
                onPressed: _busy ? null : _subscribe,
                child: Text(_magazine!.subscribed ? '구독 취소' : '구독하기'),
              ),
          ],
          if (_busy) const Center(child: CircularProgressIndicator()),
          if (_error != null) ...[
            Text(_error!),
            TextButton(
              onPressed: _busy ? null : () => _load(more: _magazine != null),
              child: const Text('다시 시도'),
            ),
          ],
          if (!_busy && _error == null && _issues.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text('지금 볼 수 있는 표지가 없어요. 잠긴 표지는 서버 공개 규칙에 따라 숨겨져요.'),
            ),
          for (final issue in _issues)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              leading: EselPaintAsset(paint: issue.color, width: 40),
              title: Text(
                'Nº ${issue.number.toString().padLeft(3, '0')} · ${issue.date.shortLabel}',
              ),
              subtitle: Text(
                issue.caption.isEmpty ? '표지 펼쳐 보기' : issue.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => ServerIssueScreen(
                      http: widget.http,
                      id: issue.id,
                      isOwner: widget.mine,
                    ),
                  ),
                );
                if (mounted) _load();
              },
            ),
          if (_magazine?.page.nextCursor != null)
            TextButton(
              onPressed: _busy ? null : () => _load(more: true),
              child: const Text('이전 호 더 보기'),
            ),
          const SizedBox(height: 16),
          const Text('사진 제공은 준비 중이에요. 다른 예시 사진으로 대신 표시하지 않아요.'),
        ],
      ),
    ),
  );
}
