import 'package:flutter/material.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/http_client.dart';
import '../../../../core/ui/esel_paint_asset.dart';
import '../../data/sources/today_remote_source.dart';
import '../../domain/models/server_today.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../magazine/presentation/screens/server_magazine_screen.dart';

class ServerTodayScreen extends StatefulWidget {
  final AppHttpClient http;
  final ValueChanged<EselPaint> onColor;
  const ServerTodayScreen({
    super.key,
    required this.http,
    required this.onColor,
  });
  @override
  State<ServerTodayScreen> createState() => _ServerTodayScreenState();
}

class _ServerTodayScreenState extends State<ServerTodayScreen>
    with WidgetsBindingObserver {
  late final source = TodayRemoteSource(widget.http);
  final _masthead = TextEditingController();
  ServerToday? _today;
  String? _error;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _masthead.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load([EselPaint? choice]) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _today = null;
    });
    try {
      final today = choice == null
          ? await source.today()
          : await source.choose(choice);
      if (!mounted) return;
      setState(() => _today = today);
      widget.onColor(today.selected ?? today.candidates.first);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is Failure ? e.message : '오늘의 색을 확인하지 못했어요.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('오늘의 색', style: EselTypography.headlineLarge),
        if (_busy) const Center(child: CircularProgressIndicator()),
        if (_error != null) ...[
          Text(_error!),
          TextButton(onPressed: () => _load(), child: const Text('다시 시도')),
        ],
        if (_today case final today?) ...[
          Text(today.date.label),
          const SizedBox(height: 16),
          Text(
            today.published
                ? '오늘 올린 표지가 있어요. 오늘의 색은 바꿀 수 없어요.'
                : '오늘 입을 색을 골라 주세요.',
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final color in today.candidates)
                OutlinedButton(
                  onPressed: _busy || today.published
                      ? null
                      : () => _load(color),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      EselPaintAsset(paint: color, width: 40, showLabel: true),
                      if (today.selected == color) const Text('선택한 색'),
                    ],
                  ),
                ),
            ],
          ),
          TextButton(onPressed: () => _load(), child: const Text('오늘 상태 새로고침')),
        ],
        const Divider(),
        Text('다른 스케치북', style: EselTypography.headlineSmall),
        TextField(
          controller: _masthead,
          maxLength: 10,
          decoration: const InputDecoration(labelText: '찾을 사인 · 영문 소문자'),
        ),
        TextButton(
          onPressed: () {
            final name = _masthead.text.trim();
            if (!RegExp(r'^[a-z]{2,10}$').hasMatch(name)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('영문 소문자 2~10자를 입력해 주세요.')),
              );
              return;
            }
            if (RegExp(r'^[a-z]{2,10}$').hasMatch(name)) {
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => ServerMagazineScreen(
                    http: widget.http,
                    mine: false,
                    masthead: name,
                  ),
                ),
              );
            }
          },
          child: const Text('스케치북 열기'),
        ),
        const Text('사진 업로드와 새 표지 올리기는 서버 연결을 준비 중이에요. 초안 편집은 기기 안에서 유지돼요.'),
      ],
    ),
  );
}
