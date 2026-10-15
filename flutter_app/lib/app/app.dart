import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/design/theme.dart';
import '../core/design/tokens.g.dart';
import '../core/ui/esel_glass.dart';
import '../core/ui/esel_paint_asset.dart';
import '../core/ui/esel_phone_frame.dart';
import '../core/ui/esel_pressable.dart';
import '../features/drafts/data/local_library.dart';
import '../features/drafts/domain/cover_draft.dart';
import '../features/issue/domain/models/public_issue.dart';
import '../features/auth/presentation/screens/login_sheet.dart';
import '../features/drafts/presentation/device_home_screen.dart';
import '../features/feed/presentation/screens/feed_screen.dart';
import '../features/friends/presentation/screens/friends_screen.dart';
import '../features/intro/presentation/screens/intro_screen.dart';
import '../features/issue/presentation/widgets/issue_bottom_sheet.dart';
import '../features/magazine/presentation/screens/my_magazine_screen.dart';
import '../features/magazine/domain/rules/privacy_rule.dart';
import '../features/magazine/presentation/screens/shelf_screen.dart';
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
import '../features/media/presentation/cover_preview.dart';
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

  // 사용자의 오늘 상태는 TodayController 한 곳에서 계산한다(P01·P04).
  bool get _hasPublishedToday => _sl.todayController.hasPublishedToday;
  int get _issueCount => _sl.todayController.issueCount;

  @override
  void initState() {
    super.initState();
    _sl.authController.addListener(_onAuthChanged);
    _sl.todayController.addListener(_onTodayChanged);
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
    super.dispose();
  }

  /// 앱을 다시 열면 서비스 날짜와 오늘 발행 여부를 다시 계산한다(P04). 백그라운드에서는
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
    if (_sl.config.isMock) {
      _sl.todayController.bindUser(
        ownerId: session?.userId,
        isMinor: session?.isMinor ?? false,
      );
    }
    // 제호 없는 계정은 창간부터(P14). 창간하는 중이면 그 단계를 그대로 둔다.
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

  /// 제호가 없는 계정은 앱을 쓰기 전에 창간한다. 제호를 이메일에서 지어내지 않는다(P14).
  bool get _needsProfile {
    final session = _sl.authController.currentSession;
    return session != null && session.masthead.isEmpty;
  }

  bool get _isFounding =>
      _needsProfile || _activeScreen == ActiveScreen.onboarding;

  void _startFounding() {
    _sl.onboardingController.reset();
    setState(() => _activeScreen = ActiveScreen.onboarding);
  }

  /// 창간을 멈춘다. 제호 없는 계정이면 로그아웃해서 첫 화면으로 돌아간다.
  Future<void> _cancelFounding() async {
    if (_needsProfile) await _sl.authController.logout();
    _sl.onboardingController.reset();
    if (mounted) setState(() => _activeScreen = ActiveScreen.main);
  }

  /// 창간하기(P13). 계정이 없으면 계정부터 만들고, 그 계정에 제호를 정한 뒤 창간호(Nº 001)를
  /// 실제로 발행한다(P04). 이미 창간한 계정으로 들어왔으면 그 잡지를 덮어쓰지 않는다.
  Future<void> _found(BuildContext context) async {
    final auth = _sl.authController;
    final onboarding = _sl.onboardingController;
    final messenger = ScaffoldMessenger.of(context);
    if (!auth.isAuthenticated) {
      await LoginSheet.show(
        context,
        authController: auth,
        title: '계정을 만들고 창간해요',
        lead: '창간호는 이 계정의 내 잡지에 꽂혀요.',
        emailSignUp: true,
        onLoginSuccess: () {},
      );
      if (!auth.isAuthenticated) return;
    }
    if (!_needsProfile) {
      messenger.showSnackBar(
        const SnackBar(content: Text('이미 창간한 잡지가 있는 계정이에요. 그 잡지로 들어가요.')),
      );
      _finishFounding(AppTab.feed);
      return;
    }
    final draft = onboarding.draft;
    if (!await auth.createProfile(draft.masthead)) {
      messenger.showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? '제호를 저장하지 못했어요.')),
      );
      return;
    }
    try {
      final issue = await _sl.todayController.publish(
        draft.toCover(id: _sl.localLibrary!.newId(), now: _sl.clock.now()),
      );
      final others = await _sl.standController
          .sameColorCount(_sl.todayController.today, issue.color)
          .catchError((Object _) => 0);
      onboarding.markFounded(issue, sameColorCount: others + 1);
    } on FormatException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
      _finishFounding(AppTab.me);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('창간호를 기기에 저장하지 못했어요. 내 잡지에서 오늘 호를 다시 만들어 주세요.'),
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
      builder: (context, child) => EselPhoneFrame(child: child!),
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
    if (_sl.config.isServer) {
      return DeviceHomeScreen(auth: _sl.authController, http: _sl.httpClient);
    }
    final auth = _sl.authController;

    // 1. 창간(J3~J7): "내 잡지 만들기"로 시작했거나, 로그인했지만 제호가 없는 계정(P13·P14)
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

    // 3. 서브스크린: 월간 색 기록 (R1~R5)
    if (_activeScreen == ActiveScreen.records) {
      return MonthlyRecordScreen(
        controller: _sl.recordsController,
        onBack: () => setState(() => _activeScreen = ActiveScreen.main),
      );
    }

    // 4. 서브스크린: 나의 친구 (F1~F3)
    if (_activeScreen == ActiveScreen.friends) {
      return FriendsScreen(
        controller: _sl.friendsController,
        onBack: () => setState(() => _activeScreen = ActiveScreen.main),
      );
    }

    // 5. 서브스크린: 트윈 (T1~T10)
    if (_activeScreen == ActiveScreen.twin) {
      return TwinScreen(
        controller: _sl.twinController,
        onBack: () => setState(() => _activeScreen = ActiveScreen.main),
      );
    }

    // 6. 서브스크린: 설정 (S1~S6)
    if (_activeScreen == ActiveScreen.settings) {
      return SettingsScreen(
        authController: _sl.authController,
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

    // 7. 서브스크린: 다른 사람의 서가(C5). 누른 사람의 잡지를 연다.
    final authorShelf = _authorShelfOwnerId;
    if (_activeScreen == ActiveScreen.authorShelf && authorShelf != null) {
      return ShelfScreen(
        ownerId: authorShelf,
        controller: _sl.magazineController,
        reactionsController: _sl.reactionsController,
        viewer: _sl.todayController.viewer,
        viewerId: auth.currentSession?.userId,
        onSelectIssue: (issue, _) => _openIssue(context, issue),
        onBack: () => setState(() => _activeScreen = ActiveScreen.main),
      );
    }

    // 8. 메인 탭 화면 + 하단 글라스 캡슐 메뉴 바
    return Scaffold(
      backgroundColor: EselTokens.paper,
      body: Stack(
        children: [
          _buildActiveTabScreen(context),
          // 디자인: 196×60 캡슐, 가로 가운데, 화면 아래 34(홈 인디케이터가 더 높으면 그 위).
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
    if (userId != null) await _sl.localLibrary?.deleteOwnerData(userId);
  }

  /// 다른 사람의 서가로. 내 이름을 누르면 내 서가로 간다.
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

  /// 펼침면(C3). 반응 숫자는 발행한 본인에게만 보인다(P18).
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
      onShare: () => ShareSheet.show(
        context,
        issueId: issue.id,
        masthead: issue.masthead,
        issueNumber: issue.issueLabel,
      ),
      onReport: () => ModerationSheet.show(
        context,
        authorMasthead: issue.masthead,
        onReport: () {},
        onBlock: () {},
      ),
    );
  }

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
            _sl.standController.select(color);
            setState(() => _currentTab = AppTab.stand);
          },
          onMakeTodayIssue: () => setState(() => _currentTab = AppTab.publish),
        );

      case AppTab.stand:
        return StandScreen(
          controller: _sl.standController,
          viewer: today.viewer,
          viewerId: session.userId,
          onMakeTodayIssue: () => setState(() => _currentTab = AppTab.publish),
          onSelectCover: (issue) => _openIssue(context, issue),
        );

      case AppTab.publish:
        return PublishScreen(
          library: _sl.localLibrary!,
          ownerId: session.userId,
          masthead: session.masthead,
          currentIssueCount: _issueCount,
          hasPublishedToday: _hasPublishedToday,
          candidates: today.candidates,
          publish: today.publish,
          onPublishSuccess: (_) => setState(() => _currentTab = AppTab.me),
          onClose: () => setState(() => _currentTab = AppTab.feed),
        );

      case AppTab.shelf:
        return ShelfScreen(
          ownerId: session.userId,
          masthead: session.masthead,
          isOwner: true,
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
        return MyMagazineScreen(
          showExtendedFeatures: !_sl.config.isMock,
          masthead: session.masthead,
          issueCount: _issueCount,
          hasPublishedToday: _hasPublishedToday,
          todayColor: today.myColor,
          todayIssue: today.todayIssue,
          reactionsController: _sl.reactionsController,
          onMakeTodayIssue: () => setState(() => _currentTab = AppTab.publish),
          onOpenShelf: () => setState(() => _currentTab = AppTab.shelf),
          onOpenRecords: () =>
              setState(() => _activeScreen = ActiveScreen.records),
          onOpenFriends: () =>
              setState(() => _activeScreen = ActiveScreen.friends),
          onOpenTwin: () => setState(() => _activeScreen = ActiveScreen.twin),
          onOpenSettings: () =>
              setState(() => _activeScreen = ActiveScreen.settings),
        );
    }
  }

  /// 디자인 "메뉴 캡슐": 내 오늘의 색 물감(52) · Ink 원 48 안의 + · 내 아바타(34).
  /// 사진이 깔린 피드에서만 글라스, 흰 화면 탭에서는 단색 + 그림자.
  Widget _buildGlassBottomBar(BuildContext context) {
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
          _buildCapsuleItem(
            '오늘의 색 가판대',
            AppTab.stand,
            context,
            child: EselPaintAsset(
              paint: _sl.todayController.myColor,
              width: 52,
            ),
          ),
          _buildCapsuleItem(
            '표지 만들기',
            AppTab.publish,
            context,
            width: 48,
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
            '내 잡지',
            AppTab.me,
            context,
            child: _buildMyAvatar(),
          ),
        ],
      ),
    );
  }

  Widget _buildMyAvatar() {
    final session = _sl.authController.currentSession;
    final issues = session == null
        ? const <CoverDraft>[]
        : _sl.localLibrary?.issuesFor(session.userId) ?? const <CoverDraft>[];
    final masthead = session?.masthead ?? '';
    final initial = Center(
      child: Text(
        masthead.isEmpty ? 'E' : masthead[0].toUpperCase(),
        style: EselTypography.name(fontSize: 20),
      ),
    );
    // 아바타는 장식이다. 이름은 버튼 라벨("내 잡지")로 읽힌다.
    return ExcludeSemantics(
      child: ClipOval(
        child: Container(
          width: 34,
          height: 34,
          color: const Color(0xFFE9E9E6),
          child: issues.isEmpty
              ? initial
              : Image(
                  image: localPhotoProvider(issues.first.photoPath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => initial,
                ),
        ),
      ),
    );
  }

  Widget _buildCapsuleItem(
    String label,
    AppTab tab,
    BuildContext context, {
    required Widget child,
    double width = 60,
  }) {
    return EselPressable(
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
        setState(() => _currentTab = tab);
      },
      child: SizedBox(
        width: width,
        height: 48,
        child: Center(child: child),
      ),
    );
  }
}
