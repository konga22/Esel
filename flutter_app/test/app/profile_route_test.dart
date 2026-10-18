import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/app/app.dart';
import 'package:esel/app/bootstrap/app_bootstrap.dart';
import 'package:esel/app/dependencies/service_locator.dart';
import 'package:esel/core/config/app_config.dart';
import 'package:esel/features/auth/data/sources/mock_account_store.dart';
import 'package:esel/features/drafts/data/local_library.dart';
import 'package:esel/features/feed/presentation/screens/feed_screen.dart';
import 'package:esel/features/intro/presentation/screens/intro_screen.dart';
import 'package:esel/features/onboarding/presentation/screens/onboarding_screen.dart';

void main() {
  late Directory directory;
  setUpAll(() async {
    AppConfig.current = const AppConfig(apiMode: ApiMode.mock);
    directory = Directory.systemTemp.createTempSync('esel-profile-route-');
    await AppBootstrap.setup(
      localLibrary: LocalLibrary(directory),
      accountVault: InMemoryMockAccountVault(),
    );
  });
  tearDownAll(() => directory.deleteSync(recursive: true));

  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(480, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('사인 없는 첫 로그인은 첫 캔버스로 가고, 멈추면 로그아웃된다(P13·P14)', (tester) async {
    usePhone(tester);
    final auth = ServiceLocator().authController;
    await tester.runAsync(
      () => auth.signupWithEmail('first@esel.local', 'esel1234', ''),
    );
    expect(auth.currentSession!.masthead, isEmpty);

    await tester.pumpWidget(const EselApp());
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(FeedScreen), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(auth.isAuthenticated, isFalse);
    expect(find.byType(IntroScreen), findsOneWidget);
  });

  testWidgets('사인을 정한 계정은 바로 표지 피드로 들어간다', (tester) async {
    usePhone(tester);
    final auth = ServiceLocator().authController;
    await tester.runAsync(
      () => auth.loginWithEmail('first@esel.local', 'esel1234'),
    );
    expect(await tester.runAsync(() => auth.createProfile('firstmag')), isTrue);

    await tester.pumpWidget(const EselApp());
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(FeedScreen), findsOneWidget);
    await tester.runAsync(auth.logout);
  });
}
