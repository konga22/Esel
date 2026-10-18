import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/app/app.dart';
import 'package:esel/app/bootstrap/app_bootstrap.dart';
import 'package:esel/features/auth/data/sources/mock_account_store.dart';
import 'package:esel/core/config/app_config.dart';
import 'package:esel/core/ui/esel_glass.dart';
import 'package:esel/features/auth/presentation/screens/login_sheet.dart';
import 'package:esel/features/intro/presentation/screens/intro_screen.dart';
import 'package:esel/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:esel/features/drafts/data/local_library.dart';

void main() {
  late Directory directory;
  setUpAll(() async {
    AppConfig.current = const AppConfig(apiMode: ApiMode.mock);
    directory = Directory.systemTemp.createTempSync('esel-login-entry-test-');
    await AppBootstrap.setup(
      localLibrary: LocalLibrary(directory),
      accountVault: InMemoryMockAccountVault(),
    );
  });
  tearDownAll(() => directory.deleteSync(recursive: true));

  // capsule_test와 같은 이유로 넘치지 않는 큰 휴대폰 폭(600 미만)을 쓴다.
  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(480, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets(
    'logged-out reader opens the glass login sheet from the login bar '
    'and can start a magazine from it',
    (tester) async {
      usePhone(tester);
      await tester.pumpWidget(const EselApp());
      await tester.pumpAndSettle();
      expect(find.byType(IntroScreen), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -700));
      await tester.pumpAndSettle();
      final bar = find.descendant(
        of: find.byType(IntroScreen),
        matching: find.byKey(const Key('login-bar')),
      );
      await tester.tap(find.descendant(of: bar, matching: find.text('로그인')));
      await tester.pumpAndSettle();

      final sheet = find.descendant(
        of: find.byType(LoginSheet),
        matching: find.byType(EselGlass),
      );
      expect(sheet, findsOneWidget);
      expect(tester.widget<EselGlass>(sheet).solid, isFalse);

      await tester.tap(
        find.descendant(
          of: find.byType(LoginSheet),
          matching: find.text('스케치북 만들기'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginSheet), findsNothing);
      expect(find.byType(OnboardingScreen), findsOneWidget);
    },
  );
}
