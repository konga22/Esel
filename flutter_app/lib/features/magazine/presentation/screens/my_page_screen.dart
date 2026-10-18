import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/ui/esel_paint_asset.dart';
import '../../../issue/domain/models/public_issue.dart';
import '../../../issue/presentation/canvas_photo.dart';
import '../../../records/domain/models/server_records.dart';
import '../../../reactions/presentation/controllers/reactions_controller.dart';
import '../../../stand/domain/rules/same_color_rule.dart';
import '../controllers/magazine_controller.dart';

enum MyPageTab { canvases, calendar, saved }

/// 내 스케치북 = 마이페이지(M1), 10-18 시안 X4-1.
/// MY SKETCHBOOK 머리와 ≡(프로필 편집 · 공유 · 설정), 얼굴·사인·소개, 숫자 줄(캔버스 · 구독 · 친구·트윈),
/// 탭 내 캔버스 · 색 달력 · 저장함. 반응 숫자와 저장함은 나만 본다(P18).
class MyPageScreen extends StatefulWidget {
  final String ownerId;
  final String masthead;
  final MagazineController controller;
  final ReactionsController reactionsController;
  final SameColorViewer viewer;
  final Widget avatar;
  final EselPaint todayColor;
  final bool publishedToday;

  /// 친구 수. 친구 기능이 없는 모드(서버)에서는 null이고 숫자 칸을 숨긴다.
  final int? friendCount;

  /// 월별 색 기록(발행 + 색 복원). 전체 색 달력과 같은 소스를 쓴다. 인자는 `2026-09` 형식.
  final Future<ServerMonthRecords> Function(String month) monthRecords;

  /// 처음 보여 줄 탭과 탭을 바꿀 때 알림. 색 달력에서 전체 달력에 다녀와도 탭이 유지된다.
  final MyPageTab initialTab;
  final ValueChanged<MyPageTab>? onTabChanged;

  /// 저장한 캔버스. 저장함 API가 연결되지 않은 모드에서는 null(준비 중).
  final List<PublicIssue> Function()? savedIssues;
  final ValueChanged<PublicIssue> onOpenCanvas;
  final ValueChanged<PublicIssue> onOpenSaved;
  final VoidCallback onMakeToday;
  final VoidCallback onChooseColor;
  final VoidCallback onOpenRecords;
  final VoidCallback onOpenSubscriptions;
  final VoidCallback? onOpenFriends;
  final VoidCallback onEditProfile;
  final VoidCallback onShare;
  final VoidCallback onOpenSettings;

  const MyPageScreen({
    super.key,
    required this.ownerId,
    required this.masthead,
    required this.controller,
    required this.reactionsController,
    required this.viewer,
    required this.avatar,
    required this.todayColor,
    required this.publishedToday,
    required this.onOpenCanvas,
    required this.onOpenSaved,
    required this.onMakeToday,
    required this.onChooseColor,
    required this.onOpenRecords,
    required this.onOpenSubscriptions,
    required this.onEditProfile,
    required this.onShare,
    required this.onOpenSettings,
    required this.monthRecords,
    this.friendCount,
    this.initialTab = MyPageTab.canvases,
    this.onTabChanged,
    this.savedIssues,
    this.onOpenFriends,
  });

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  late MyPageTab _tab = widget.initialTab;
  MagazineProfile? _last;
  Future<ServerMonthRecords>? _month;

  String get _monthKey {
    final today = widget.viewer.today;
    return '${today.year}-${today.month.toString().padLeft(2, '0')}';
  }

  void _select(MyPageTab tab) {
    setState(() {
      _tab = tab;
      if (tab == MyPageTab.calendar) _month ??= widget.monthRecords(_monthKey);
    });
    widget.onTabChanged?.call(tab);
  }

  void _configure() => widget.controller.configure(
    ownerId: widget.ownerId,
    viewer: widget.viewer,
    viewerId: widget.ownerId,
    masthead: widget.masthead,
  );

  void _profileChanged() {
    final profile = widget.controller.profile;
    if (profile != null && !identical(profile, _last)) {
      _last = profile;
      for (final issue in profile.issues) {
        widget.reactionsController.seedIssue(issue);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_profileChanged);
    _configure();
    _profileChanged();
    if (_tab == MyPageTab.calendar) _month = widget.monthRecords(_monthKey);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_profileChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(MyPageScreen old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_profileChanged);
      widget.controller.addListener(_profileChanged);
      _last = null;
    }
    _configure();
  }

  Future<void> _menu() => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (sheet) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (key, icon, label, action) in [
            (
              'my-menu-edit',
              Icons.edit_outlined,
              '프로필 편집',
              widget.onEditProfile,
            ),
            ('my-menu-share', Icons.ios_share, '내 스케치북 공유', widget.onShare),
            ('my-menu-settings', Icons.tune, '설정과 계정', widget.onOpenSettings),
          ])
            ListTile(
              key: ValueKey(key),
              leading: Icon(icon),
              title: Text(label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(sheet);
                action();
              },
            ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([
      widget.controller,
      widget.reactionsController,
    ]),
    builder: (context, _) {
      final profile = widget.controller.profile;
      return Scaffold(
        backgroundColor: EselColors.paper,
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 130),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 4, 0),
                child: Row(
                  children: [
                    Text(
                      'MY SKETCHBOOK',
                      style: EselTypography.meta(
                        fontSize: 11,
                      ).copyWith(letterSpacing: 1),
                    ),
                    const Spacer(),
                    IconButton(
                      key: const ValueKey('my-menu'),
                      tooltip: '메뉴',
                      onPressed: _menu,
                      icon: const Icon(Icons.menu),
                    ),
                  ],
                ),
              ),
              _head(profile),
              _tabs(),
              if (widget.controller.isLoading && profile == null)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (widget.controller.errorMessage case final error?
                  when profile == null)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(error),
                      TextButton(
                        onPressed: () => widget.controller.load(),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              else
                switch (_tab) {
                  MyPageTab.canvases => _canvases(profile),
                  MyPageTab.calendar => _calendar(),
                  MyPageTab.saved => _saved(),
                },
            ],
          ),
        ),
      );
    },
  );

  Widget _head(MagazineProfile? profile) {
    final bio = profile?.bio ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(width: 80, height: 80, child: widget.avatar),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.masthead,
                      style: EselTypography.name(fontSize: 38),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (bio.isNotEmpty)
                      Text(
                        bio,
                        style: EselTypography.body(
                          fontSize: 13.5,
                          color: EselColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFF111111)),
                bottom: BorderSide(color: EselColors.hairline),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  _stat('canvases', '${profile?.totalIssues ?? 0}', '캔버스'),
                  _stat(
                    'subscriptions',
                    '${widget.reactionsController.subscribedOwnerIds.length}',
                    '구독',
                    onTap: widget.onOpenSubscriptions,
                  ),
                  if (widget.friendCount != null)
                    _stat(
                      'friends',
                      '${widget.friendCount}',
                      '친구 · 트윈',
                      onTap: widget.onOpenFriends,
                    ),
                ],
              ),
            ),
          ),
          if (!widget.publishedToday)
            DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: EselColors.hairline)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      key: const ValueKey('my-today-color'),
                      onTap: widget.onChooseColor,
                      child: SizedBox(
                        height: 48,
                        child: Row(
                          children: [
                            EselPaintAsset(paint: widget.todayColor, width: 40),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '오늘은 ${EselPaints.of(widget.todayColor).nameKo} · 아직 올리지 않았어요',
                                overflow: TextOverflow.ellipsis,
                                style: EselTypography.body(fontSize: 13.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    key: const ValueKey('my-make-today'),
                    onPressed: widget.onMakeToday,
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.chevron_right, size: 18),
                    label: const Text('만들기'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _stat(String key, String value, String label, {VoidCallback? onTap}) =>
      Expanded(
        child: InkWell(
          key: ValueKey('my-stat-$key'),
          onTap: onTap,
          child: Column(
            children: [
              Text(value, style: EselTypography.label(fontSize: 17)),
              Text(label, style: EselTypography.body(fontSize: 12.5)),
            ],
          ),
        ),
      );

  Widget _tabs() => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: EselColors.hairline)),
      ),
      child: Row(
        children: [
          for (final (tab, icon, label) in [
            (MyPageTab.canvases, Icons.grid_view_outlined, '내 캔버스'),
            (MyPageTab.calendar, Icons.calendar_today_outlined, '색 달력'),
            (MyPageTab.saved, Icons.bookmark_border, '저장함'),
          ])
            Expanded(
              child: Semantics(
                selected: _tab == tab,
                button: true,
                child: InkWell(
                  key: ValueKey('my-tab-${tab.name}'),
                  onTap: () => _select(tab),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _tab == tab
                              ? EselColors.ink
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 19,
                          color: _tab == tab
                              ? EselColors.ink
                              : const Color(0xFFA3A49E),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: EselTypography.label(
                            fontSize: 14,
                            color: _tab == tab
                                ? EselColors.ink
                                : const Color(0xFFA3A49E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _grid(
    List<PublicIssue> issues,
    ValueChanged<PublicIssue> onTap,
    String prefix,
  ) => GridView.count(
    crossAxisCount: 3,
    mainAxisSpacing: 2,
    crossAxisSpacing: 2,
    childAspectRatio: 3 / 4,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    children: [
      for (final issue in issues)
        InkWell(
          key: ValueKey('$prefix-${issue.id}'),
          onTap: () => onTap(issue),
          child: Semantics(
            label: '${issue.issueLabel} · ${issue.date.shortLabel}',
            child: CanvasPhoto(issue: issue),
          ),
        ),
    ],
  );

  Widget _canvases(MagazineProfile? profile) {
    final issues = profile?.issues ?? const <PublicIssue>[];
    if (issues.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('아직 올린 캔버스가 없어요.'),
      );
    }
    return Column(
      children: [
        _grid(issues, widget.onOpenCanvas, 'my-canvas'),
        if (widget.controller.moreError case final message?)
          Padding(padding: const EdgeInsets.all(16), child: Text(message)),
        if (profile!.nextCursor != null)
          TextButton(
            onPressed: widget.controller.isLoadingMore
                ? null
                : () => widget.controller.load(more: true),
            child: Text(
              widget.controller.isLoadingMore ? '불러오는 중…' : '이전 캔버스 더 보기',
            ),
          ),
      ],
    );
  }

  /// 이번 달 색 달력: 전체 색 달력과 같은 월별 기록(발행 + 색 복원)을 읽는다(#24 리뷰).
  /// 올린 날은 그날 색 물감, 복원한 날은 그 색 테두리 동그라미, 지난 빈 날은 빈 동그라미, 오늘은 테두리.
  /// 색 복원은 색 달력 화면에서 한다.
  Widget _calendar() => FutureBuilder<ServerMonthRecords>(
    future: _month,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('색 기록을 불러오지 못했어요.'),
              TextButton(
                onPressed: () =>
                    setState(() => _month = widget.monthRecords(_monthKey)),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        );
      }
      final records = snapshot.data;
      if (records == null) {
        return const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final today = widget.viewer.today;
      final days = {for (final day in records.days) day.date.day: day};
      final first = DateTime.utc(today.year, today.month, 1);
      final count = DateTime.utc(today.year, today.month + 1, 0).day;
      final lead = first.weekday % 7; // 일요일 시작
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${today.month}월의 색',
              style: EselTypography.heading(fontSize: 22),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final d in ['일', '월', '화', '수', '목', '금', '토'])
                  Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: EselTypography.body(
                          fontSize: 11,
                          color: EselColors.muted,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.82,
              children: [
                for (var i = 0; i < lead; i++) const SizedBox.shrink(),
                for (var day = 1; day <= count; day++)
                  _day(day, days[day], today.day),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const ValueKey('my-open-records'),
              onPressed: widget.onOpenRecords,
              child: const Text('색 달력 열기 · 빈 날 색 복원'),
            ),
          ],
        ),
      );
    },
  );

  Widget _day(int day, ServerDayRecord? record, int today) => Container(
    key: ValueKey('my-day-$day'),
    margin: const EdgeInsets.all(2),
    decoration: day == today
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: EselColors.ink, width: 1.5),
          )
        : null,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$day',
          style: EselTypography.meta(
            fontSize: 10,
            color: day > today ? const Color(0xFFC7C8C2) : EselColors.muted,
          ),
        ),
        const SizedBox(height: 2),
        if (record != null && record.restored)
          Container(
            key: ValueKey('my-day-$day-restored'),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: EselPaints.of(record.color).color,
                width: 2.5,
              ),
            ),
          )
        else if (record != null)
          EselPaintAsset(paint: record.color, width: 30)
        else if (day < today)
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD3D3CE)),
            ),
          )
        else
          const SizedBox(height: 12),
      ],
    ),
  );

  Widget _saved() {
    final source = widget.savedIssues;
    if (source == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('저장함은 서버에 연결되면 볼 수 있어요. 저장한 사실은 나에게만 보여요.'),
      );
    }
    final issues = source();
    if (issues.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('저장한 캔버스가 없어요. 캔버스에서 저장을 누르면 여기에 모여요.'),
      );
    }
    return _grid(issues, widget.onOpenSaved, 'my-saved');
  }
}
