import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/app/app.dart';
import 'package:esel/app/bootstrap/app_bootstrap.dart';
import 'package:esel/app/dependencies/service_locator.dart';
import 'package:esel/core/config/app_config.dart';
import 'package:esel/core/time/service_clock.dart';
import 'package:esel/core/ui/esel_button.dart';
import 'package:esel/core/ui/esel_pressable.dart';
import 'package:esel/features/auth/data/sources/mock_account_store.dart';
import 'package:esel/features/drafts/data/local_library.dart';
import 'package:esel/features/feed/presentation/screens/feed_screen.dart';
import 'package:esel/features/intro/presentation/screens/intro_screen.dart';
import 'package:esel/features/magazine/presentation/screens/my_page_screen.dart';
import 'package:esel/features/settings/presentation/screens/settings_screen.dart';

/// 기기 초안 지우기가 몇 프레임 걸리는 보관함. 그동안 앱이 화면을 다시 그려 설정 화면이 먼저 닫힌다.
class _SlowLibrary extends LocalLibrary {
  _SlowLibrary() : super.inMemory();

  @override
  Future<void> deleteOwnerData(String ownerId) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await super.deleteOwnerData(ownerId);
  }
}

/// #41 리뷰: 탈퇴가 성공하면 설정 화면이 먼저 닫혀도 첫 화면 처리(onDeleteComplete)가 불려야 한다.
/// 앱 전체(EselApp)를 띄워 스케치북 → 설정 → 탈퇴로 확인한다.
void main() {
  late ServiceLocator sl;
  setUpAll(() async {
    AppConfig.current = const AppConfig(apiMode: ApiMode.mock);
    await AppBootstrap.setup(
      localLibrary: _SlowLibrary(),
      clock: ManualServiceClock(DateTime.utc(2026, 9, 6, 3)),
      accountVault: InMemoryMockAccountVault(),
    );
    sl = ServiceLocator();
    await sl.authController.signupWithEmail(
      'gone@esel.local',
      'esel1234',
      'gonemag',
    );
  });

  testWidgets('스케치북에서 연 설정으로 탈퇴하면 첫 화면이 되고, 다음 로그인은 홈에서 시작한다', (tester) async {
    tester.view.physicalSize = const Size(480, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const EselApp());
    await tester.pumpAndSettle();

    // 스케치북 → ≡ → 설정과 계정 → 계정 관리
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is EselPressable && w.semanticsLabel == '스케치북',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MyPageScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('my-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('my-menu-settings')));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    await tester.tap(find.text('계정 관리'));
    await tester.pumpAndSettle();

    // 확인 체크 → 탈퇴 진행하기 → 영구 삭제
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.widgetWithText(EselButton, '탈퇴 진행하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('영구 삭제'));
    await tester.pumpAndSettle();

    expect(sl.authController.isAuthenticated, isFalse);
    expect(find.byType(IntroScreen), findsOneWidget);
    expect(find.byType(SettingsScreen), findsNothing);
    expect(tester.takeException(), isNull);

    // 다른 계정으로 들어오면 탈퇴 전 탭(스케치북)이 아니라 홈에서 시작한다.
    await tester.runAsync(
      () => sl.authController.signupWithEmail(
        'next@esel.local',
        'esel1234',
        'nextmag',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FeedScreen), findsOneWidget);
    expect(find.byType(MyPageScreen), findsNothing);
  });
}
