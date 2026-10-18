import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/app/app.dart';
import 'package:esel/app/bootstrap/app_bootstrap.dart';
import 'package:esel/app/dependencies/service_locator.dart';
import 'package:esel/core/config/app_config.dart';
import 'package:esel/core/design/tokens.g.dart';
import 'package:esel/core/time/service_clock.dart';
import 'package:esel/core/ui/esel_paint_asset.dart';
import 'package:esel/core/ui/esel_pressable.dart';
import 'package:esel/features/auth/data/sources/mock_account_store.dart';
import 'package:esel/features/drafts/data/local_library.dart';
import 'package:esel/features/drafts/domain/cover_draft.dart';
import 'package:esel/features/friends/presentation/screens/friends_screen.dart';
import 'package:esel/features/magazine/presentation/screens/my_page_screen.dart';
import 'package:esel/features/magazine/presentation/screens/shelf_screen.dart';
import 'package:esel/features/records/presentation/screens/monthly_record_screen.dart';
import 'package:esel/features/settings/presentation/screens/settings_screen.dart';
import 'package:esel/features/twin/presentation/screens/twin_screen.dart';

void main() {
  // 서비스 로케이터는 한 번만 준비된다. 테스트는 위에서부터 이어진다(첫 테스트에서 오늘 올림).
  late ServiceLocator sl;
  late ManualServiceClock clock;
  setUpAll(() async {
    AppConfig.current = const AppConfig(apiMode: ApiMode.mock);
    clock = ManualServiceClock(DateTime.utc(2026, 9, 6, 3));
    await AppBootstrap.setup(
      localLibrary: LocalLibrary.inMemory(),
      clock: clock,
      accountVault: InMemoryMockAccountVault(),
    );
    sl = ServiceLocator();
    await sl.authController.signupWithEmail(
      'own@esel.local',
      'esel1234',
      'ownmag',
    );
  });

  group('DEV-14 마이페이지 X4-1', () {
    Future<void> openMyPage(WidgetTester tester) async {
      tester.view.physicalSize = const Size(480, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const EselApp());
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is EselPressable && w.semanticsLabel == '스케치북',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MyPageScreen), findsOneWidget);
    }

    Future<void> publish(WidgetTester tester) async {
      await tester.runAsync(
        () => sl.todayController.publish(
          CoverDraft(
            id: 'own-1',
            photoPath: 'own.png',
            masthead: 'ownmag',
            color: EselPaint.camel,
            faceConfirmed: true,
            updatedAt: clock.now(),
          ),
        ),
      );
    }

    testWidgets('머리·숫자 줄·오늘 줄. 주제·전시·친구·트윈·설정 버튼은 첫 화면에 없다', (tester) async {
      await openMyPage(tester);
      expect(find.text('MY SKETCHBOOK'), findsOneWidget);
      expect(find.byKey(const ValueKey('my-menu')), findsOneWidget);
      for (final key in ['canvases', 'subscriptions', 'friends']) {
        expect(find.byKey(ValueKey('my-stat-$key')), findsOneWidget);
      }
      // 구독자 수는 아직 데이터가 없어 칸을 만들지 않는다.
      expect(find.text('구독자'), findsNothing);
      for (final gone in ['이번 주 주제', '전시', '트윈', '설정', '내 캔버스의 반응 보기']) {
        expect(find.text(gone), findsNothing, reason: gone);
      }
      // 아직 올리지 않았으면 오늘 줄.
      expect(find.byKey(const ValueKey('my-today-color')), findsOneWidget);

      await publish(tester);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('my-today-color')), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('my-stat-canvases')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('격자 칸을 누르면 세로 목록, 뒤로 가면 마이페이지', (tester) async {
      await openMyPage(tester);
      await tester.tap(find.byKey(const ValueKey('my-canvas-own-1')));
      await tester.pumpAndSettle();
      final shelf = tester.widget<ShelfScreen>(find.byType(ShelfScreen));
      expect(shelf.focusIssueId, 'own-1');
      expect(shelf.isOwner, isTrue);
      expect(find.text('내 캔버스의 반응 보기'), findsOneWidget);
      await tester.tap(find.byTooltip('뒤로'));
      await tester.pumpAndSettle();
      expect(find.byType(MyPageScreen), findsOneWidget);
    });

    testWidgets('색 달력 탭은 이번 달, 전체 달력은 색 달력 화면으로', (tester) async {
      await openMyPage(tester);
      await tester.tap(find.byKey(const ValueKey('my-tab-calendar')));
      await tester.pumpAndSettle();
      expect(find.text('9월의 색'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('my-day-6')),
          matching: find.byType(EselPaintAsset),
        ),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('my-open-records')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('my-open-records')));
      await tester.pumpAndSettle();
      expect(find.byType(MonthlyRecordScreen), findsOneWidget);
    });

    testWidgets('저장함은 내가 저장했고 지금 볼 수 있는 캔버스만', (tester) async {
      await openMyPage(tester);
      await tester.tap(find.byKey(const ValueKey('my-tab-saved')));
      await tester.pumpAndSettle();
      expect(find.textContaining('저장한 캔버스가 없어요'), findsOneWidget);

      sl.reactionsController.toggleScrap('kofi-2026-09-05');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('my-saved-kofi-2026-09-05')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('my-saved-ama-2026-09-05')),
        findsNothing,
      );
    });

    testWidgets('≡ 메뉴: 프로필 편집은 프로필로 바로, 뒤로는 마이페이지. 설정과 계정은 설정 메뉴', (
      tester,
    ) async {
      await openMyPage(tester);
      await tester.tap(find.byKey(const ValueKey('my-menu')));
      await tester.pumpAndSettle();
      expect(find.text('프로필 편집'), findsOneWidget);
      expect(find.text('내 스케치북 공유'), findsOneWidget);
      expect(find.text('설정과 계정'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('my-menu-edit')));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('프로필 편집'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();
      expect(find.byType(MyPageScreen), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('my-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('my-menu-settings')));
      await tester.pumpAndSettle();
      expect(find.text('나의 설정'), findsOneWidget);
    });

    testWidgets('친구 · 트윈 숫자 → 친구 화면, 트윈은 친구 화면 맨 위 줄', (tester) async {
      await openMyPage(tester);
      await tester.tap(find.byKey(const ValueKey('my-stat-friends')));
      await tester.pumpAndSettle();
      expect(find.byType(FriendsScreen), findsOneWidget);
      await tester.tap(find.byKey(const Key('friends-twin')));
      await tester.pumpAndSettle();
      expect(find.byType(TwinScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();
      expect(find.byType(FriendsScreen), findsOneWidget);
    });
  });
}
