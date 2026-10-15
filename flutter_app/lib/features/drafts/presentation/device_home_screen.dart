import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/design/tokens.g.dart';
import '../../../core/design/typography.dart';
import '../../../core/ui/esel_button.dart';
import '../../../core/ui/esel_glass.dart';
import '../../../core/ui/esel_paint_asset.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../auth/presentation/screens/server_account_screen.dart';
import '../../../core/network/http_client.dart';
import '../data/local_library.dart';
import '../domain/cover_draft.dart';
import 'cover_editor_screen.dart';
import 'local_calendar_screen.dart';
import '../../settings/presentation/screens/device_settings_screen.dart';
import '../../settings/presentation/device_preferences.dart';
import '../../media/presentation/cover_preview.dart';

class DeviceHomeScreen extends StatefulWidget {
  final AuthController auth;
  final AppHttpClient http;
  const DeviceHomeScreen({super.key, required this.auth, required this.http});
  @override
  State<DeviceHomeScreen> createState() => _DeviceHomeScreenState();
}

class _DeviceHomeScreenState extends State<DeviceHomeScreen> {
  LocalLibrary? _library;
  String? _loadError;
  int _tab = 0;
  EselPaint _color = EselPaint.powder;
  EselPaint? _filter;
  DateTime? _date;
  String _query = '';
  bool _newest = true;
  final _search = TextEditingController();
  final _scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    _library?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final library = await LocalLibrary.open();
      if (!mounted) {
        library.dispose();
        return;
      }
      setState(() => _library = library);
      if (library.recoveryNotice != null) _message(library.recoveryNotice!);
      if (!kIsWeb && Platform.isAndroid) {
        final lost = await ImagePicker().retrieveLostData();
        if (!mounted || lost.isEmpty) return;
        if (lost.files?.isNotEmpty == true) {
          final path = await library.importPhoto(lost.files!.first.path);
          if (mounted) {
            await _edit(
              CoverDraft(
                id: library.newId(),
                photoPath: path,
                updatedAt: DateTime.now(),
              ),
            );
          }
        } else if (lost.exception != null) {
          _message('중단된 사진 선택을 복구하지 못했어요. 다시 골라 주세요.');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _loadError = '기기의 초안을 불러오지 못했어요. 저장 공간과 파일 접근을 확인해 주세요.',
        );
      }
    }
  }

  void _message(String value) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(value)));
    }
  }

  Route<T> _page<T>(Widget child) => PageRouteBuilder<T>(
    pageBuilder: (_, _, _) =>
        DevicePreferences(library: _library!, child: child),
    transitionDuration: _library!.reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 200),
    reverseTransitionDuration: _library!.reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 200),
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );

  Future<void> _edit([CoverDraft? draft]) async {
    final library = _library;
    if (library == null) return;
    await Navigator.push<void>(
      context,
      _page<void>(
        CoverEditorScreen(
          library: library,
          initial:
              draft ??
              CoverDraft(
                id: library.newId(),
                photoPath: '',
                color: _color,
                updatedAt: DateTime.now(),
              ),
        ),
      ),
    );
    if (mounted) setState(() => _tab = 2);
  }

  Future<void> _calendar() async {
    final selected = await Navigator.push<DateTime>(
      context,
      _page<DateTime>(LocalCalendarScreen(library: _library!)),
    );
    if (selected != null && mounted) {
      setState(() {
        _date = selected;
        _tab = 2;
      });
    }
  }

  Future<void> _delete(CoverDraft draft) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('이 초안을 지울까요?'),
        content: Text('${draft.masthead} 초안이 기기 보관함에서 삭제돼요. 원본 앨범 사진은 유지돼요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('초안 삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _library!.delete(draft.id);
      _message('초안을 삭제했어요.');
    } catch (_) {
      _message('삭제하지 못했어요. 다시 시도해 주세요.');
    }
  }

  Future<void> _viewMode() async {
    try {
      await _library!.settings(grid: !_library!.gridView);
    } catch (_) {
      _message('보기 설정을 저장하지 못했어요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final library = _library;
    if (library == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: _loadError == null
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_loadError!),
                      TextButton(
                        onPressed: _load,
                        child: const Text('다시 불러오기'),
                      ),
                    ],
                  ),
          ),
        ),
      );
    }
    return AnimatedBuilder(
      animation: library,
      builder: (context, _) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            disableAnimations: media.disableAnimations || library.reduceMotion,
            highContrast: media.highContrast || library.reduceTransparency,
            textScaler: library.largeText && media.textScaler.scale(1) < 1.2
                ? const TextScaler.linear(1.2)
                : media.textScaler,
          ),
          child: Builder(
            builder: (context) => Scaffold(
              backgroundColor: EselColors.paper,
              appBar: AppBar(
                title: TextButton(
                  onPressed: () {
                    if (_scroll.hasClients) {
                      _scroll.animateTo(
                        0,
                        duration: library.reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Text('Esel', style: EselTypography.headlineLarge),
                ),
                actions: [
                  IconButton(
                    tooltip: '계정 · 로그인',
                    onPressed: () => Navigator.push<void>(
                      context,
                      _page<void>(
                        Scaffold(
                          appBar: AppBar(title: const Text('계정')),
                          body: ServerAccountScreen(
                            auth: widget.auth,
                            http: widget.http,
                          ),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.person_outline),
                  ),
                  IconButton(
                    tooltip: '기기 설정',
                    onPressed: () => Navigator.push<void>(
                      context,
                      _page<void>(DeviceSettingsScreen(library: library)),
                    ),
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
              body: _tab == 2 ? _libraryView(library) : _palette(),
              bottomNavigationBar: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: EselGlass(
                    borderRadius: 40,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        _tabButton(
                          '오늘의 색',
                          Icons.palette_outlined,
                          0,
                          () => setState(() => _tab = 0),
                        ),
                        _tabButton('만들기', Icons.add, 1, () => _edit()),
                        _tabButton(
                          '내 잡지',
                          Icons.menu_book_outlined,
                          2,
                          () => setState(() => _tab = 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _tabButton(String label, IconData icon, int index, VoidCallback tap) =>
      Expanded(
        child: Semantics(
          selected: _tab == index,
          child: TextButton(
            onPressed: tap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: EselColors.ink),
                Text(
                  label,
                  style: TextStyle(
                    color: EselColors.ink,
                    fontWeight: _tab == index
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  Widget _palette() => ListView(
    controller: _scroll,
    padding: const EdgeInsets.all(24),
    children: [
      Text('평범한 하루의 착장이\n한 권의 잡지가 되는 곳.', style: EselTypography.headlineSmall),
      const SizedBox(height: 24),
      const Text(
        '오늘의 추천 세 가지 색은 서비스 연결 후 확인할 수 있어요. 지금은 초안에 사용할 색을 자유롭게 골라보세요.',
      ),
      const SizedBox(height: 24),
      Text('초안 팔레트', style: EselTypography.headlineSmall),
      const SizedBox(height: 12),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: EselPaint.values
            .map(
              (color) => Semantics(
                selected: color == _color,
                child: OutlinedButton(
                  onPressed: () => setState(() => _color = color),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: color == _color
                          ? EselColors.ink
                          : EselColors.hairline,
                      width: color == _color ? 2 : 1,
                    ),
                    padding: const EdgeInsets.all(12),
                    minimumSize: const Size(140, 64),
                  ),
                  child: EselPaintAsset(
                    paint: color,
                    width: 35,
                    showLabel: true,
                  ),
                ),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 24),
      EselButton(
        label: '${EselPaints.of(_color).nameKo}로 초안 만들기',
        onTap: () => _edit(),
      ),
      const SizedBox(height: 16),
      const Text('사진 편집과 초안 보관은 로그인 없이 이용할 수 있어요.'),
    ],
  );
  Widget _libraryView(LocalLibrary library) {
    final drafts = library.drafts
        .where(
          (d) =>
              (_filter == null || d.color == _filter) &&
              (_date == null ||
                  (d.updatedAt.year == _date!.year &&
                      d.updatedAt.month == _date!.month &&
                      d.updatedAt.day == _date!.day)) &&
              ('${d.masthead} ${d.caption}'.toLowerCase().contains(
                _query.toLowerCase(),
              )),
        )
        .toList();
    if (!_newest) drafts.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.all(20),
      children: [
        Text('기기에 보관한 초안', style: EselTypography.headlineSmall),
        const SizedBox(height: 8),
        const Text('아직 발행되지 않은 나만의 표지예요.'),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: _calendar,
                icon: const Icon(Icons.calendar_month_outlined),
                label: const Text('월별 보기'),
              ),
            ),
            IconButton(
              tooltip: library.gridView ? '목록으로 보기' : '표지로 보기',
              onPressed: _viewMode,
              icon: Icon(
                library.gridView ? Icons.view_list_outlined : Icons.grid_view,
              ),
            ),
            IconButton(
              tooltip: _newest ? '오래된 순으로 보기' : '최근 편집 순으로 보기',
              onPressed: () => setState(() => _newest = !_newest),
              icon: const Icon(Icons.sort),
            ),
          ],
        ),
        TextField(
          controller: _search,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            labelText: '제호 · 문구 검색',
            suffixIcon: IconButton(
              tooltip: '검색어 지우기',
              onPressed: () {
                _search.clear();
                setState(() => _query = '');
              },
              icon: const Icon(Icons.clear),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('전체'),
                selected: _filter == null,
                onSelected: (_) => setState(() => _filter = null),
              ),
              ...EselPaint.values.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: ChoiceChip(
                    label: Text(EselPaints.of(c).nameKo),
                    selected: _filter == c,
                    onSelected: (_) => setState(() => _filter = c),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_date != null)
          InputChip(
            label: Text('${_date!.year}.${_date!.month}.${_date!.day}'),
            onDeleted: () => setState(() => _date = null),
          ),
        const SizedBox(height: 16),
        if (drafts.isEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Text(
              '조건에 맞는 초안이 없어요. 사진을 골라 첫 표지를 만들어 보세요.',
              textAlign: TextAlign.center,
            ),
          ),
          EselButton(label: '새 초안 만들기', onTap: () => _edit()),
        ] else if (library.gridView)
          LayoutBuilder(
            builder: (context, constraints) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: drafts.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: constraints.maxWidth < 320 ? 1 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: .6,
              ),
              itemBuilder: (context, i) => _tile(drafts[i], true),
            ),
          )
        else
          ...drafts.map((d) => _tile(d, false)),
      ],
    );
  }

  Widget _tile(CoverDraft draft, bool grid) {
    final photo = FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 360,
        height: 480,
        child: CoverPreview(draft: draft),
      ),
    );
    final menu = IconButton(
      tooltip: '${draft.masthead} 초안 삭제',
      onPressed: () => _delete(draft),
      icon: const Icon(Icons.delete_outline),
    );
    if (!grid) {
      return ListTile(
        onTap: () => _edit(draft),
        leading: SizedBox(width: 48, height: 64, child: photo),
        title: Text(draft.masthead),
        subtitle: Text(
          '${EselPaints.of(draft.color).nameKo} · ${draft.caption}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: menu,
      );
    }
    return Column(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _edit(draft),
            child: SizedBox.expand(child: photo),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Text(draft.masthead, overflow: TextOverflow.ellipsis),
            ),
            menu,
          ],
        ),
      ],
    );
  }
}
