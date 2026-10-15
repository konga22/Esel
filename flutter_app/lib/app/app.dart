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
import '../features/auth/presentation/screens/login_sheet.dart';
import '../features/drafts/presentation/device_home_screen.dart';
import '../features/feed/presentation/screens/feed_screen.dart';
import '../features/friends/presentation/screens/friends_screen.dart';
import '../features/intro/presentation/screens/intro_screen.dart';
import '../features/issue/presentation/widgets/issue_bottom_sheet.dart';
import '../features/magazine/presentation/screens/my_magazine_screen.dart';
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
  String _authorShelfMasthead = 'seul';

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
      _sl.magazineController.localOwnerId = session?.userId;
      _sl.magazineController.localMasthead = session?.masthead;
      _sl.todayController.bindUser(
        ownerId: session?.userId,
        isMinor: session?.isMinor ?? false,
      );
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
        setState(() => _activeScreen = ActiveScreen.onboarding);
      },
      onLoginSuccess: () {
        final pending = _sl.authController.pendingDestination;
        if (pending == 'publish') {
          setState(() => _currentTab = AppTab.publish);
        } else if (pending == 'me') {
          setState(() => _currentTab = AppTab.me);
        } else if (pending == 'onboarding') {
          setState(() => _activeScreen = ActiveScreen.onboarding);
        }
      },
    );
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
            (_activeScreen == ActiveScreen.main &&
                _currentTab == AppTab.feed) ||
            _currentTab == AppTab.publish,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop || _currentTab == AppTab.publish) return;
          setState(() {
            if (_activeScreen == ActiveScreen.onboarding) {
              if (_sl.onboardingController.currentStep.index > 0) {
                _sl.onboardingController.prevStep();
              } else {
                _activeScreen = ActiveScreen.main;
              }
            } else if (_activeScreen != ActiveScreen.main) {
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

    // 1. 비로그인 상태이면서 intro 화면인 경우
    if (!auth.isAuthenticated && _activeScreen != ActiveScreen.onboarding) {
      return IntroScreen(
        onOpenLogin: () => _openLoginSheet(ctx: context),
        onStartJoin: () =>
            setState(() => _activeScreen = ActiveScreen.onboarding),
      );
    }

    // 2. 창간(온보딩) 화면
    if (_activeScreen == ActiveScreen.onboarding) {
      return OnboardingScreen(
        controller: _sl.onboardingController,
        candidates: _sl.todayController.candidates,
        onCancel: () => setState(() => _activeScreen = ActiveScreen.main),
        onComplete: () {
          // 창간 완료 시 로그인 세션 생성 및 메인 진입
          final draft = _sl.onboardingController.draft;
          _sl.authController.signupWithEmail(
            '${draft.masthead}@esel.app',
            'esel1234',
            draft.masthead,
          );
          setState(() {
            _activeScreen = ActiveScreen.main;
            _currentTab = AppTab.feed;
          });
        },
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

    // 7. 서브스크린: 타인 서가 (C5)
    if (_activeScreen == ActiveScreen.authorShelf) {
      return ShelfScreen(
        masthead: _authorShelfMasthead,
        controller: _sl.magazineController,
        reactionsController: _sl.reactionsController,
        onSelectIssue: (issue) {
          IssueBottomSheet.show(
            context,
            issueId: issue.id,
            authorMasthead: _authorShelfMasthead,
            mainPhoto: issue.photoAsset,
            secondPhoto: 'assets/models/m02.jpg',
            color: issue.color,
            caption: issue.caption,
            issueNumber: issue.issueString,
            isOwner: false,
            reactionsController: _sl.reactionsController,
            onOpenAuthorShelf: () {},
            onShare: () => ShareSheet.show(
              context,
              issueId: issue.id,
              masthead: _authorShelfMasthead,
              issueNumber: issue.issueString,
            ),
            onReport: () => ModerationSheet.show(
              context,
              authorMasthead: _authorShelfMasthead,
              onReport: () {},
              onBlock: () {},
            ),
          );
        },
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

  Widget _buildActiveTabScreen(BuildContext context) {
    final session = _sl.authController.currentSession;
    final myMasthead = session?.masthead ?? 'dana';

    switch (_currentTab) {
      case AppTab.feed:
        return FeedScreen(
          feedController: _sl.feedController,
          reactionsController: _sl.reactionsController,
          isAuthenticated: _sl.authController.isAuthenticated,
          onRequestLogin: () => _openLoginSheet(ctx: context),
          onOpenAuthorShelf: (masthead) {
            setState(() {
              _authorShelfMasthead = masthead;
              _activeScreen = ActiveScreen.authorShelf;
            });
          },
        );

      case AppTab.stand:
        return StandScreen(
          controller: _sl.standController,
          viewer: _sl.todayController.viewer,
          onMakeTodayIssue: () => setState(() => _currentTab = AppTab.publish),
          onSelectCover: (item) {
            IssueBottomSheet.show(
              context,
              issueId: item.id,
              authorMasthead: item.masthead,
              mainPhoto: item.photoAsset,
              secondPhoto: 'assets/models/m01.jpg',
              color: item.color,
              caption: item.caption,
              issueNumber: item.issueLabel,
              isOwner: item.masthead == myMasthead,
              reactionsController: _sl.reactionsController,
              onOpenAuthorShelf: () {
                setState(() {
                  _authorShelfMasthead = item.masthead;
                  _activeScreen = ActiveScreen.authorShelf;
                });
              },
              onShare: () => ShareSheet.show(
                context,
                issueId: item.id,
                masthead: item.masthead,
                issueNumber: item.issueLabel,
              ),
              onReport: () => ModerationSheet.show(
                context,
                authorMasthead: item.masthead,
                onReport: () {},
                onBlock: () {},
              ),
            );
          },
        );

      case AppTab.publish:
        return PublishScreen(
          library: _sl.localLibrary!,
          ownerId: session!.userId,
          controller: _sl.publishingController,
          masthead: myMasthead,
          currentIssueCount: _issueCount,
          hasPublishedToday: _hasPublishedToday,
          candidates: _sl.todayController.candidates,
          publish: _sl.todayController.publish,
          onPublishSuccess: (_) => setState(() => _currentTab = AppTab.me),
          onClose: () => setState(() => _currentTab = AppTab.feed),
        );

      case AppTab.shelf:
        return ShelfScreen(
          isOwner: true,
          masthead: myMasthead,
          controller: _sl.magazineController,
          reactionsController: _sl.reactionsController,
          onSelectIssue: (issue) {
            if (issue.cover != null) {
              Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: Text(issue.issueString)),
                    body: Center(child: CoverPreview(draft: issue.cover!)),
                  ),
                ),
              );
              return;
            }
            IssueBottomSheet.show(
              context,
              issueId: issue.id,
              authorMasthead: myMasthead,
              mainPhoto: issue.photoAsset,
              secondPhoto: 'assets/models/m01.jpg',
              color: issue.color,
              caption: issue.caption,
              issueNumber: issue.issueString,
              isOwner: true,
              reactionsController: _sl.reactionsController,
              onOpenAuthorShelf: () {},
              onShare: () => ShareSheet.show(
                context,
                issueId: issue.id,
                masthead: myMasthead,
                issueNumber: issue.issueString,
              ),
              onReport: () {},
            );
          },
          onBack: () => setState(() => _currentTab = AppTab.me),
        );

      case AppTab.me:
        return MyMagazineScreen(
          showExtendedFeatures: !_sl.config.isMock,
          masthead: myMasthead,
          issueCount: _issueCount,
          hasPublishedToday: _hasPublishedToday,
          todayColor: _sl.todayController.myColor,
          controller: _sl.magazineController,
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
