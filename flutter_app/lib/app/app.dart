import '../features/stand/domain/models/stand_shelf.dart';
import '../features/drafts/domain/cover_draft.dart';
import '../features/drafts/presentation/draft_library_screen.dart';
import '../features/drafts/presentation/cover_editor_screen.dart';
import '../features/settings/presentation/device_preferences.dart';
import '../features/settings/presentation/screens/device_settings_screen.dart';
import '../core/errors/failures.dart';
import 'dart:math' as math;
import '../features/challenges/domain/challenge.dart';
import '../features/challenges/presentation/challenge_screen.dart';
import '../features/collections/presentation/collection_screen.dart';
import 'package:flutter/material.dart';
import '../core/design/theme.dart';
import '../core/design/tokens.g.dart';
import '../core/ui/esel_glass.dart';
import '../core/ui/esel_paint_asset.dart';
import '../core/ui/esel_phone_frame.dart';
import '../core/ui/esel_pressable.dart';
import '../features/drafts/data/local_library.dart';
import '../features/issue/domain/models/public_issue.dart';
import '../features/auth/presentation/screens/login_sheet.dart';
import '../features/feed/presentation/screens/feed_screen.dart';
import '../features/friends/presentation/screens/friends_screen.dart';
import '../features/intro/presentation/screens/intro_screen.dart';
import '../features/issue/presentation/widgets/issue_bottom_sheet.dart';
import '../features/magazine/domain/rules/privacy_rule.dart';
import '../features/magazine/presentation/screens/shelf_screen.dart';
import '../features/feed/presentation/widgets/feed_pages.dart';
import '../features/moderation/presentation/widgets/moderation_sheet.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/publishing/presentation/screens/publish_screen.dart';
import '../features/records/presentation/screens/monthly_record_screen.dart';
import '../features/sharing/presentation/widgets/share_sheet.dart';
import '../features/stand/presentation/screens/stand_screen.dart';
import '../features/twin/presentation/screens/twin_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import 'dependencies/service_locator.dart';
import 'routing/app_routes.dart';
import '../features/media/domain/models/face_box.dart';
import '../features/media/presentation/cover_preview.dart';
import '../features/media/presentation/face_avatar.dart';
import '../core/design/typography.dart';

class EselApp extends StatefulWidget {
  const EselApp({super.key});

  @override
  State<EselApp> createState() => _EselAppState();
}

class _EselAppState extends State<EselApp> with WidgetsBindingObserver {
  final _sl = ServiceLocator();

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  AppTab _currentTab = AppTab.feed;
  ActiveScreen _activeScreen = ActiveScreen.main;
  String? _authorShelfOwnerId;
  StyleChallenge? _pendingChallenge;
  String? _previousIssueId;
  String? _contentOwnerId;

  // 사용자의 오늘 상태는 TodayController 한 곳에서 계산한다(P01·P04).
  bool get _hasPublishedToday => _sl.todayController.hasPublishedToday;
  int get _issueCount => _sl.todayController.issueCount;

  @override
  void initState() {
    super.initState();
    _sl.authController.addListener(_onAuthChanged);
    _sl.todayController.addListener(_onTodayChanged);
    _sl.reactionsController.addListener(_onTodayChanged);
    _sl.localLibrary?.addListener(_onTodayChanged);
    WidgetsBinding.instance.addObserver(this);
    _sl.todayController.watchMidnight();
    _onAuthChanged();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sl.todayController.stopWatchingMidnight();
    _sl.authController.removeListener(_onAuthChanged);
    _sl.todayController.removeListener(_onTodayChanged);
    _sl.reactionsController.removeListener(_onTodayChanged);
    _sl.localLibrary?.removeListener(_onTodayChanged);
    super.dispose();
  }

  /// 앱을 다시 열면 서비스 날짜와 오늘 올리기 여부를 다시 계산한다(P04). 백그라운드에서는
  /// 자정 타이머가 늦을 수 있다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _sl.todayController.refresh();
    _sl.todayController.watchMidnight();
  }

  void _onTodayChanged() {
    if (mounted) setState(() {});
  }

  void _onAuthChanged() {
    final session = _sl.authController.currentSession;
    _sl.reactionsController.bindUser(session?.userId, _sl.localLibrary);
    if (_contentOwnerId != session?.userId) {
      final previousOwner = _contentOwnerId;
      _contentOwnerId = session?.userId;
      _pendingChallenge = null;
      _previousIssueId = null;
      _sl.magazineController.clear();
      if (previousOwner != null) {
        _navigatorKey.currentState?.popUntil((route) => route.isFirst);
      }
      if (_activeScreen != ActiveScreen.onboarding) {
        _activeScreen = ActiveScreen.main;
      }
    }

    _sl.todayController.bindUser(
      ownerId: session?.userId,
      isMinor: session?.isMinor ?? false,
      hasProfile: session?.masthead.isNotEmpty ?? false,
    );

    // 사인 없는 계정은 첫 캔버스부터(P14). 첫 캔버스를 올리는 중이면 그 단계를 그대로 둔다.
    if (_needsProfile && _activeScreen != ActiveScreen.onboarding) {
      _sl.onboardingController.reset();
      _activeScreen = ActiveScreen.onboarding;
    }
    if (mounted) setState(() {});
  }

  void _openLoginSheet({BuildContext? ctx, String? destination}) {
    if (destination != null) {
      _sl.authController.setPendingDestination(destination);
    }
    final targetContext = ctx ?? _navigatorKey.currentContext ?? context;
    LoginSheet.show(
      targetContext,
      authController: _sl.authController,
      onStartJoin: () {
        _sl.authController.setPendingDestination(null);
        _startFounding();
      },
      onLoginSuccess: () {
        final pending = _sl.authController.pendingDestination;
        if (pending == 'publish') {
          setState(() => _currentTab = AppTab.publish);
        } else if (pending == 'me') {
          setState(() => _currentTab = AppTab.me);
        }
      },
    );
  }

  /// 사인이 없는 계정은 앱을 쓰기 전에 첫 캔버스한다. 사인을 이메일에서 지어내지 않는다(P14).
  bool get _needsProfile {
    final session = _sl.authController.currentSession;
    return session != null && session.masthead.isEmpty;
  }

  bool get _isFounding =>
      _needsProfile || _activeScreen == ActiveScreen.onboarding;

  Future<void> _startFounding() async {
    if (_sl.config.isServer && !_sl.authController.isAuthenticated) {
      final context = _navigatorKey.currentContext;
      if (context == null) return;
      await LoginSheet.show(
        context,
        authController: _sl.authController,
        emailSignUp: true,
        onLoginSuccess: () {},
      );
      if (!_sl.authController.isAuthenticated) return;
    }
    _sl.onboardingController.reset();
    setState(() => _activeScreen = ActiveScreen.onboarding);
  }

  /// 첫 캔버스를 멈춘다. 사인 없는 계정이면 로그아웃해서 첫 화면으로 돌아간다.
  Future<void> _cancelFounding() async {
    if (_needsProfile) await _sl.authController.logout();
    _sl.onboardingController.reset();
    if (mounted) setState(() => _activeScreen = ActiveScreen.main);
  }

  /// 첫 캔버스 올리기(P13). 계정이 없으면 계정부터 만들고, 그 계정에 사인을 정한 뒤 첫 캔버스(Nº 001)를
  /// 실제로 올린다(P04). 이미 첫 캔버스한 계정으로 들어왔으면 그 잡지를 덮어쓰지 않는다.
  Future<void> _found(BuildContext context) async {
    final auth = _sl.authController;
    final onboarding = _sl.onboardingController;
    final messenger = ScaffoldMessenger.of(context);
    if (!auth.isAuthenticated) {
      await LoginSheet.show(
        context,
        authController: auth,
        title: '계정을 만들고 첫 캔버스해요',
        lead: '첫 캔버스는 이 계정의 스케치북에 꽂혀요.',
        emailSignUp: true,
        onLoginSuccess: () {},
      );
      if (!auth.isAuthenticated) return;
    }
    if (!_needsProfile) {
      messenger.showSnackBar(
        const SnackBar(content: Text('이미 첫 캔버스한 잡지가 있는 계정이에요. 그 잡지로 들어가요.')),
      );
      _finishFounding(AppTab.feed);
      return;
    }
    final draft = onboarding.draft;
    if (!await auth.createProfile(draft.masthead)) {
      messenger.showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? '사인을 저장하지 못했어요.')),
      );
      return;
    }
    try {
      final cover = draft
          .toCover(id: _sl.localLibrary!.newId(), now: _sl.clock.now())
          .copyWith(ownerId: auth.currentSession!.userId);
      await _sl.localLibrary!.save(cover);
      final issue = await _sl.todayController.publish(cover);
      final others = await _sl.standController
          .sameColorCount(_sl.todayController.today, issue.color)
          .catchError((Object _) => 0);
      onboarding.markFounded(issue, sameColorCount: others + 1);
    } on Failure catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
      _finishFounding(AppTab.me);
    } on FormatException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
      _finishFounding(AppTab.me);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('첫 캔버스를 기기에 저장하지 못했어요. 스케치북에서 오늘의 캔버스를 다시 만들어 주세요.'),
        ),
      );
      _finishFounding(AppTab.me);
    }
  }

  void _finishFounding(AppTab tab) {
    _sl.onboardingController.reset();
    if (!mounted) return;
    setState(() {
      _activeScreen = ActiveScreen.main;
      _currentTab = tab;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Esel',
      debugShowCheckedModeBanner: false,
      theme: EselTheme.lightTheme,
      builder: (context, child) => DevicePreferences(
        library: _sl.localLibrary!,
        child: EselPhoneFrame(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _sl.reactionsController,
              _sl.todayController,
              _sl.localLibrary!,
            ]),
            builder: (context, _) => Column(
              children: [
                if (_sl.reactionsController.saveError case final error?)
                  Material(
                    color: EselColors.paper,
                    child: SafeArea(
                      bottom: false,
                      child: ListTile(
                        title: Text(error),
                        trailing: TextButton(
                          onPressed: _sl.reactionsController.retrySave,
                          child: const Text('재시도'),
                        ),
                      ),
                    ),
                  ),
                if (_sl.todayController.error case final error?
                    when _sl.todayController.isRemote &&
                        _sl.todayController.hasTodayData)
                  Material(
                    color: EselColors.paper,
                    child: SafeArea(
                      bottom: false,
                      child: ListTile(
                        key: const Key('today-refresh-error'),
                        title: Text(error),
                        trailing: TextButton(
                          onPressed: _sl.todayController.loading
                              ? null
                              : () => _sl.todayController.reload(),
                          child: const Text('다시 시도'),
                        ),
                      ),
                    ),
                  ),
                if (_sl.todayController.hasTodayData &&
                    (_sl.todayController.loading ||
                        _sl.reactionsController.loading))
                  const LinearProgressIndicator(
                    minHeight: 2,
                    semanticsLabel: '요청을 처리하고 있어요.',
                  ),
                if (_sl.localLibrary!.loadError case final error?)
                  Material(
                    color: EselColors.paper,
                    child: SafeArea(
                      bottom: false,
                      child: ListTile(
                        title: Text(error),
                        trailing: TextButton(
                          onPressed: _sl.localLibrary!.directory == null
                              ? null
                              : _sl.localLibrary!.loadForStartup,
                          child: const Text('다시 읽기'),
                        ),
                      ),
                    ),
                  ),
                Expanded(child: child!),
              ],
            ),
          ),
        ),
      ),
      home: PopScope(
        canPop:
            !_isFounding &&
            ((_activeScreen == ActiveScreen.main &&
                    _currentTab == AppTab.feed) ||
                _currentTab == AppTab.publish),
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_isFounding) {
            if (_sl.onboardingController.currentStep.index > 0) {
              _sl.onboardingController.prevStep();
            } else {
              _cancelFounding();
            }
            return;
          }
          if (_currentTab == AppTab.publish) return;
          setState(() {
            if (_activeScreen != ActiveScreen.main) {
              _activeScreen = ActiveScreen.main;
            } else {
              _currentTab = _currentTab == AppTab.shelf
                  ? AppTab.me
                  : AppTab.feed;
            }
          });
        },
        child: Builder(builder: (ctx) => _buildRootContent(ctx)),
      ),
    );
  }

  Widget _buildRootContent(BuildContext context) {
    final auth = _sl.authController;
    final today = _sl.todayController;
    if (auth.isAuthenticated && today.isRemote && !today.hasTodayData) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Esel', style: EselTypography.heading(fontSize: 40)),
                if (today.loading)
                  const CircularProgressIndicator()
                else ...[
                  Text(today.error ?? '오늘의 색을 확인하지 못했어요.'),
                  TextButton(
                    onPressed: () => today.reload(),
                    child: const Text('다시 시도'),
                  ),
                  TextButton(onPressed: auth.logout, child: const Text('로그아웃')),
                ],
              ],
            ),
          ),
        ),
      );
    }

    // 1. 첫 캔버스(J3~J7): "스케치북 만들기"로 시작했거나, 로그인했지만 사인이 없는 계정(P13·P14)
    if (_isFounding) {
      final today = _sl.todayController;
      return OnboardingScreen(
        controller: _sl.onboardingController,
        candidates: today.candidates,
        today: today.today,
        library: _sl.localLibrary!,
        onCancel: _cancelFounding,
        onFound: () => _found(context),
        onOpenFeed: () => _finishFounding(AppTab.feed),
        onOpenMyMagazine: () => _finishFounding(AppTab.me),
      );
    }

    // 2. 비로그인 첫 화면(J1)
    if (!auth.isAuthenticated) {
      return IntroScreen(
        feedController: _sl.feedController,
        today: _sl.todayController.today,
        onOpenLogin: () => _openLoginSheet(ctx: context),
        onStartJoin: _startFounding,
      );
    }

    if (_activeScreen == ActiveScreen.collections) {
      return CollectionScreen(
        key: ValueKey(auth.currentSession!.userId),
        ownerId: auth.currentSession!.userId,
        source: _sl.collectionSource,
        library: _sl.localLibrary!,
        viewer: _sl.todayController.viewer,
        clock: _sl.clock,
        onBack: () => setState(() => _activeScreen = ActiveScreen.main),
      );
    }
    if (_activeScreen == ActiveScreen.challenges) {
      return ChallengeScreen(
        key: ValueKey(auth.currentSession!.userId),
        ownerId: auth.currentSession!.userId,
        library: _sl.localLibrary!,
        source: _sl.challengeSource,
        clock: _sl.clock,
        viewer: _sl.todayController.viewer,
        onBack: () => setState(() => _activeScreen = ActiveScreen.main),
        onBegin: (challenge, previousId) async {
          _sl.todayController.refresh();
          final issue = _sl.todayController.todayIssue;
          if (issue != null) {
            await _sl.challengeSource.attach(
              auth.currentSession!.userId,
              issue.id,
              challenge,
              _sl.clock.today,
              previousId: previousId,
            );
          } else {
            if (_sl.todayController.hasPublishedToday) {
              throw const FormatException(
                '오늘의 캔버스가 삭제되어 참여에 연결할 수 없어요. 다음 올리기일에 참여해 주세요.',
              );
            }
            setState(() {
              _pendingChallenge = challenge;
              _previousIssueId = previousId;
              _activeScreen = ActiveScreen.main;
              _currentTab = AppTab.publish;
            });
          }
        },
      );
    }

    // 3. 서브스크린: 색 달력 (R1~R5)
    if (_activeScreen == ActiveScreen.records) {
      return MonthlyRecordScreen(
        source: _sl.recordsSource,
        onOpenIssue: (id) async {
          try {
            final issue = await _sl.reactionsController.ownIssue(id);
            if (context.mounted) _openIssue(context, issue);
          } on Failure catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(e.message)));
            }
          }
        },
        onBack: () => setState(() => _activeScreen = ActiveScreen.main),
      );
    }

    // 4. 서브스크린: 나의 친구 (F1~F3)
    if (_activeScreen == ActiveScreen.friends) {
      return FriendsScreen(
        controller: _sl.friendsController,
        onBack: () => setState(() => _activeScreen = ActiveScreen.main),
        onOpenTwin: () => setState(() => _activeScreen = ActiveScreen.twin),
      );
    }

    // 5. 서브스크린: 트윈 (T1~T10)
    if (_activeScreen == ActiveScreen.twin) {
      // 트윈은 친구 화면 맨 위 줄에서 연다(10-18). 뒤로 가면 친구 화면.
      return TwinScreen(
        controller: _sl.twinController,
        onBack: () => setState(() => _activeScreen = ActiveScreen.friends),
      );
    }

    // 6. 서브스크린: 설정 (S1~S6)
    if (_activeScreen == ActiveScreen.settings) {
      return SettingsScreen(
        authController: _sl.authController,
        deviceActions: {
          '기기 접근성 설정': () => Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => DeviceSettingsScreen(library: _sl.localLibrary!),
            ),
          ),
          '기기 초안 · 초안 달력': () => Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => DraftLibraryScreen(
                library: _sl.localLibrary!,
                ownerId: auth.currentSession!.userId,
                clock: _sl.clock,
                onEdit: (draft) => _editDeviceDraft(context, draft),
              ),
            ),
          ),
        },
        deleteAccount: _deleteAccount,
        onBack: () => setState(() => _activeScreen = ActiveScreen.main),
        onLogoutComplete: () {
          setState(() {
            _activeScreen = ActiveScreen.intro;
            _currentTab = AppTab.feed;
          });
        },
        onDeleteComplete: () {
          setState(() {
            _activeScreen = ActiveScreen.intro;
            _currentTab = AppTab.feed;
          });
        },
      );
    }

    // 7. 서브스크린: 다른 사람의 스케치북(C5). 누른 사람의 잡지를 연다.
    final authorShelf = _authorShelfOwnerId;
    if (_activeScreen == ActiveScreen.authorShelf && authorShelf != null) {
      return Stack(
        children: [
          ShelfScreen(
            ownerId: authorShelf,
            controller: _sl.magazineController,
            reactionsController: _sl.reactionsController,
            viewer: _sl.todayController.viewer,
            viewerId: auth.currentSession?.userId,
            onSelectIssue: (issue, _) => _openIssue(context, issue),
            onBack: () => setState(() => _activeScreen = ActiveScreen.main),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: math.max(34.0, MediaQuery.of(context).padding.bottom),
            child: Center(child: _buildGlassBottomBar(context)),
          ),
        ],
      );
    }

    // 8. 메인 탭 화면 + 하단 글라스 캡슐 메뉴 바
    return Scaffold(
      backgroundColor: EselTokens.paper,
      body: Stack(
        children: [
          _buildActiveTabScreen(context),
          // 디자인: 198×60 캡슐, 가로 가운데, 화면 아래 34(홈 인디케이터가 더 높으면 그 위).
          Positioned(
            left: 0,
            right: 0,
            bottom: math.max(34.0, MediaQuery.of(context).padding.bottom),
            child: _currentTab == AppTab.publish
                ? const SizedBox.shrink()
                : Center(child: _buildGlassBottomBar(context)),
          ),
        ],
      ),
    );
  }

  /// 탈퇴: 계정 기록을 지운 뒤 이 기기의 내 호·사진·내보낸 이미지까지 지운다.
  /// 화면 문구("모든 호와 데이터가 영구히 삭제")가 사실이 되게 한다.
  Future<void> _deleteAccount() async {
    final userId = _sl.authController.currentSession?.userId;
    await _sl.authController.deleteAccount();
    if (userId != null) {
      await _sl.localLibrary?.deleteOwnerData(userId);
      _sl.reactionsController.forgetOwner(userId);
    }
  }

  /// 다른 사람의 스케치북으로. 내 이름을 누르면 내 스케치북으로 간다.
  void _openAuthorShelf(String ownerId) {
    setState(() {
      if (ownerId == _sl.authController.currentSession?.userId) {
        _activeScreen = ActiveScreen.main;
        _currentTab = AppTab.shelf;
      } else {
        _authorShelfOwnerId = ownerId;
        _activeScreen = ActiveScreen.authorShelf;
      }
    });
  }

  /// 자세히 보기(C3). 반응 숫자는 올린 본인에게만 보인다(P18).
  void _openIssue(BuildContext context, PublicIssue issue) {
    final session = _sl.authController.currentSession;
    IssueBottomSheet.show(
      context,
      issue: issue,
      isOwner: PrivacyRule.shouldExposeReactionCounts(
        viewerUserId: session?.userId,
        ownerUserId: issue.ownerId,
      ),
      readerMasthead: session?.masthead ?? '',
      reactionsController: _sl.reactionsController,
      onOpenAuthorShelf: () => _openAuthorShelf(issue.ownerId),
      onShare: () => _shareIssue(context, issue),
      onReport: () => ModerationSheet.show(
        context,
        authorMasthead: issue.masthead,
        onReport: () {},
        onBlock: () {},
      ),
    );
  }

  void _editDeviceDraft(BuildContext context, CoverDraft draft) {
    final account = _sl.authController.currentSession;
    if (account == null ||
        draft.ownerId != account.userId ||
        draft.issueNumber != 0) {
      return;
    }
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (editorContext) => CoverEditorScreen(
          library: _sl.localLibrary!,
          initial: draft,
          candidates: _sl.todayController.candidates,
          onClose: () => Navigator.pop(editorContext),
          onPublish: (value) async {
            await _sl.todayController.publish(value);
            if (editorContext.mounted) Navigator.pop(editorContext);
          },
        ),
      ),
    );
  }

  void _shareIssue(BuildContext context, PublicIssue issue) => ShareSheet.show(
    context,
    issueId: issue.id,
    masthead: issue.masthead,
    issueNumber: issue.issueLabel,
  );
  Widget _buildActiveTabScreen(BuildContext context) {
    final session = _sl.authController.currentSession!;
    final today = _sl.todayController;

    switch (_currentTab) {
      case AppTab.feed:
        return FeedScreen(
          feedController: _sl.feedController,
          reactionsController: _sl.reactionsController,
          viewer: today.viewer,
          onOpenAuthorShelf: _openAuthorShelf,
          onOpenIssue: (issue) => _openIssue(context, issue),
          onOpenStand: (color) {
            _sl.standController.selectTab(PaletteTab.colors);
            _sl.standController.select(color);
            setState(() => _currentTab = AppTab.stand);
          },
          onMakeTodayIssue: () => setState(() => _currentTab = AppTab.publish),
          // 주제·전시는 아직 이 기기 안의 기능이라 목업 모드에서만 카드를 낸다.
          challenge: _sl.config.isMock
              ? FeedFeature(
                  eyebrow: '이번 주 주제',
                  title: StyleChallenge.forWeek(today.viewer.today).first.topic,
                  sub: '서울 월~일 · 오늘 후보 색과 함께, 새 옷 없이도',
                  onTap: () =>
                      setState(() => _activeScreen = ActiveScreen.challenges),
                )
              : null,
          collection: _sl.config.isMock
              ? FeedFeature(
                  eyebrow: '이번 주의 전시',
                  title: '고른 이유가 있는 캔버스',
                  sub: '오늘 · 이번 주 · 이달 · 순위나 숫자 없이',
                  onTap: () =>
                      setState(() => _activeScreen = ActiveScreen.collections),
                )
              : null,
        );

      case AppTab.stand:
        _sl.standController.preferredColor = today.myColor;
        _sl.standController.subscriptions =
            _sl.reactionsController.subscribedOwnerIds;
        // 이번 주 주제·전시는 팔레트에서 빠지고 홈 피드 카드로 간다(10-18).
        return StandScreen(
          controller: _sl.standController,
          viewer: today.viewer,
          viewerId: session.userId,
          onMakeTodayIssue: () => setState(() => _currentTab = AppTab.publish),
          onSelectCover: (issue) => _openAuthorShelf(issue.ownerId),
        );

      case AppTab.publish:
        if (!_sl.localLibrary!.available) {
          return const Scaffold(
            body: SafeArea(
              child: Center(
                child: Text('기기 보관함을 다시 읽은 뒤 편집해 주세요. 기존 자료는 보존되어 있어요.'),
              ),
            ),
          );
        }
        return PublishScreen(
          challengeId: _pendingChallenge?.id,
          previousIssueId: _previousIssueId,
          library: _sl.localLibrary!,
          ownerId: session.userId,
          masthead: session.masthead,
          currentIssueCount: _issueCount,
          hasPublishedToday: _hasPublishedToday,
          candidates: today.candidates,
          publish: today.publish,
          onPublishSuccess: (_) => _closeContentEditor(published: true),
          onClose: _closeContentEditor,
        );

      case AppTab.shelf:
        return ShelfScreen(
          ownerId: session.userId,
          masthead: session.masthead,
          isOwner: true,
          onShareIssue: (issue) => _shareIssue(context, issue),
          controller: _sl.magazineController,
          reactionsController: _sl.reactionsController,
          viewer: today.viewer,
          viewerId: session.userId,
          onSelectIssue: (issue, local) {
            if (local == null) {
              _openIssue(context, issue);
              return;
            }
            Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: Text(issue.issueLabel)),
                  body: Center(child: CoverPreview(draft: local)),
                ),
              ),
            );
          },
          onBack: () => setState(() => _currentTab = AppTab.me),
        );

      case AppTab.me:
        return ShelfScreen(
          ownerId: session.userId,
          masthead: session.masthead,
          isOwner: true,
          onShareIssue: (issue) => _shareIssue(context, issue),
          controller: _sl.magazineController,
          reactionsController: _sl.reactionsController,
          viewer: today.viewer,
          viewerId: session.userId,
          onSelectIssue: (issue, _) => _openIssue(context, issue),
          onBack: () => setState(() => _currentTab = AppTab.feed),
          actions: {
            '오늘의 캔버스 만들기': () => setState(() => _currentTab = AppTab.publish),
            '오늘의 색': () => _chooseColor(context),
            '색 달력': () => setState(() => _activeScreen = ActiveScreen.records),
            if (_sl.config.isMock)
              '이번 주 주제': () =>
                  setState(() => _activeScreen = ActiveScreen.challenges),
            if (_sl.config.isMock)
              '전시': () =>
                  setState(() => _activeScreen = ActiveScreen.collections),
            if (_sl.config.isMock)
              '친구': () => setState(() => _activeScreen = ActiveScreen.friends),
            if (_sl.config.isMock)
              '트윈': () => setState(() => _activeScreen = ActiveScreen.twin),
            '설정': () => setState(() => _activeScreen = ActiveScreen.settings),
          },
        );
    }
  }

  Future<void> _chooseColor(BuildContext context) async {
    final today = _sl.todayController;
    final color = await showModalBottomSheet<EselPaint>(
      context: context,
      useSafeArea: true,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(title: Text('오늘의 색')),
          for (final paint in today.candidates)
            ListTile(
              title: Text(EselPaints.of(paint).nameKo),
              leading: EselPaintAsset(paint: paint, width: 40),
              enabled: !today.hasPublishedToday,
              onTap: () => Navigator.pop(context, paint),
            ),
        ],
      ),
    );
    if (color != null) today.pick(color);
  }

  void _closeContentEditor({bool published = false}) {
    setState(() {
      _activeScreen = _pendingChallenge == null
          ? ActiveScreen.main
          : ActiveScreen.challenges;
      _currentTab = _pendingChallenge != null || published
          ? AppTab.me
          : AppTab.feed;
      _pendingChallenge = null;
      _previousIssueId = null;
    });
  }

  /// 디자인 "메뉴 캡슐"(10-18): 바뀌는 칸 · Ink 원 48 안의 + · 내 아바타(34).
  /// 바뀌는 칸은 지금 속한 쪽의 반대편이다. 홈 피드(와 홈에서 연 스케치북)에서는 내 오늘의 색
  /// 물감(52) → 팔레트, 그 밖(팔레트·팔레트에서 연 스케치북·내 스케치북)에서는 홈 아이콘 → 홈.
  /// 사진이 깔린 피드에서만 글라스, 흰 화면 탭에서는 단색 + 그림자.
  Widget _buildGlassBottomBar(BuildContext context) {
    final onHome = _currentTab == AppTab.feed;
    return EselGlass(
      key: const Key('menu-capsule'),
      width: EselSizes.capsuleWidth,
      height: EselSizes.capsuleHeight,
      borderRadius: EselSizes.capsuleHeight / 2,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      solid: _currentTab != AppTab.feed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (onHome)
            _buildCapsuleItem(
              '팔레트',
              AppTab.stand,
              context,
              child: EselPaintAsset(
                paint: _sl.todayController.myColor,
                width: 52,
              ),
            )
          else
            _buildCapsuleItem(
              '홈',
              AppTab.feed,
              context,
              child: const Icon(Icons.home_outlined, size: 26),
            ),
          _buildCapsuleItem(
            '만들기',
            AppTab.publish,
            context,
            width: 62,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: EselColors.ink,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 22, color: EselColors.paper),
            ),
          ),
          _buildCapsuleItem(
            '스케치북',
            AppTab.me,
            context,
            child: _buildMyAvatar(),
          ),
        ],
      ),
    );
  }

  /// 내 아바타: 최근 호 사진에서 얼굴이 원을 채우게. 호가 없으면 사인 첫 글자.
  Widget _buildMyAvatar() {
    final session = _sl.authController.currentSession;
    final latest = _sl.todayController.issues.firstOrNull;
    final masthead = session?.masthead ?? '';
    if (latest != null && latest.photoPath.isNotEmpty) {
      return FaceAvatar(
        image: localPhotoProvider(latest.photoPath),
        face: FaceBox(latest.faceX, latest.faceY, latest.faceWidth),
        size: 34,
      );
    }
    // 아바타는 장식이다. 이름은 버튼 라벨("스케치북")로 읽힌다.
    return ExcludeSemantics(
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Color(0xFFE9E9E6),
          shape: BoxShape.circle,
        ),
        child: Text(
          masthead.isEmpty ? 'E' : masthead[0].toUpperCase(),
          style: EselTypography.name(fontSize: 20),
        ),
      ),
    );
  }

  Widget _buildCapsuleItem(
    String label,
    AppTab tab,
    BuildContext context, {
    required Widget child,
    double width = 62,
  }) {
    // 앱 목업: 4px 먹 점은 내 스케치북에 있을 때 스케치북 칸에만. 바뀌는 칸은 갈 곳을
    // 보여 주는 버튼이라 점이 없고, 만들기는 잠깐 들어갔다 나오는 화면이라 점이 없다.
    final marked =
        tab == AppTab.me &&
        (_currentTab == AppTab.me || _currentTab == AppTab.shelf);
    return Semantics(
      selected: marked,
      child: EselPressable(
        semanticsLabel: label,
        onTap: () {
          if (tab == AppTab.publish || tab == AppTab.me) {
            if (!_sl.authController.isAuthenticated) {
              _openLoginSheet(
                ctx: context,
                destination: tab == AppTab.publish ? 'publish' : 'me',
              );
              return;
            }
          }
          setState(() {
            _activeScreen = ActiveScreen.main;
            _currentTab = tab;
          });
        },
        child: SizedBox(
          width: width,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              child,
              if (marked)
                Positioned(
                  bottom: 1,
                  child: Container(
                    key: ValueKey('capsule-dot-${tab.name}'),
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: EselColors.ink,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
