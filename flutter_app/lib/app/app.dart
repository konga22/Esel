import 'package:flutter/material.dart';
import '../core/design/theme.dart';
import '../core/design/tokens.g.dart';
import '../core/ui/esel_glass.dart';
import '../core/ui/esel_pressable.dart';
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

class _EselAppState extends State<EselApp> {
  final _sl = ServiceLocator();

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  AppTab _currentTab = AppTab.feed;
  ActiveScreen _activeScreen = ActiveScreen.main;
  String _authorShelfMasthead = 'seul';

  // 사용자의 오늘 상태
  bool _hasPublishedToday = false;
  int _issueCount = 0;

  @override
  void initState() {
    super.initState();
    _sl.authController.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _sl.authController.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    final session = _sl.authController.currentSession;
    if (_sl.config.isMock && session != null) {
      _sl.magazineController.localOwnerId = session.userId;
      _sl.magazineController.localMasthead = session.masthead;
      final issues = _sl.localLibrary!.issuesFor(session.userId);
      _issueCount = issues.length;
      final now = DateTime.now();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      _hasPublishedToday = issues.any((d) => d.publishedOn == today);
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
            _hasPublishedToday = true;
            _issueCount = 1;
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
            colorKey: issue.colorKey,
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
          Positioned(
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: _currentTab == AppTab.publish
                ? const SizedBox.shrink()
                : _buildGlassBottomBar(context),
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
          mySelectedColorKey: _sl.publishingController.colorId,
          hasPublishedToday: _hasPublishedToday,
          onSelectCover: (item) {
            IssueBottomSheet.show(
              context,
              issueId: item.id,
              authorMasthead: item.masthead,
              mainPhoto: item.photoAsset,
              secondPhoto: 'assets/models/m01.jpg',
              colorKey: item.colorKey,
              caption: item.caption,
              issueNumber: item.issueNumber,
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
                issueNumber: item.issueNumber,
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
          onPublishSuccess: (newCount) {
            setState(() {
              _hasPublishedToday = true;
              _issueCount = newCount;
              _currentTab = AppTab.me;
            });
          },
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
              colorKey: issue.colorKey,
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

  Widget _buildGlassBottomBar(BuildContext context) {
    return EselGlass(
      borderRadius: EselRadius.pill,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCapsuleItem(
            Icons.auto_stories_outlined,
            Icons.auto_stories,
            '오늘의 색',
            AppTab.stand,
            context,
          ),
          _buildCapsuleItem(
            Icons.add_circle_outline,
            Icons.add_circle,
            '만들기',
            AppTab.publish,
            context,
          ),
          _buildCapsuleItem(
            Icons.person_outline,
            Icons.person,
            '내 잡지',
            AppTab.me,
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildCapsuleItem(
    IconData inactiveIcon,
    IconData activeIcon,
    String label,
    AppTab tab,
    BuildContext context,
  ) {
    final isSelected = _currentTab == tab;

    return EselPressable(
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
        width: 88,
        height: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              size: 24,
              color: isSelected ? EselTokens.ink : EselTokens.inkMuted,
            ),
            Text(label, style: EselTypography.labelSmall),
          ],
        ),
      ),
    );
  }
}
