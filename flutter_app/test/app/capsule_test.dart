import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/app/app.dart';
import 'package:esel/app/bootstrap/app_bootstrap.dart';
import 'package:esel/features/auth/data/sources/mock_account_store.dart';
import 'package:esel/app/dependencies/service_locator.dart';
import 'package:esel/core/config/app_config.dart';
import 'package:esel/core/ui/esel_glass.dart';
import 'package:esel/features/drafts/data/local_library.dart';

void main() {
  late Directory directory;
  setUpAll(() async {
    AppConfig.current = const AppConfig(apiMode: ApiMode.mock);
    directory = Directory.systemTemp.createTempSync('esel-capsule-test-');
    await AppBootstrap.setup(
      localLibrary: LocalLibrary(directory),
      accountVault: InMemoryMockAccountVault(),
    );
    await ServiceLocator().authController.signupWithEmail(
      'capsule@esel.local',
      'eseldemo2026',
      'capsule',
    );
  });
  tearDownAll(() => directory.deleteSync(recursive: true));

  // 테스트 글꼴은 실제 글꼴보다 글자 폭이 넓어 393 폭에서는 피드 윗줄이 넘친다.
  // 캡슐만 보는 테스트라 넘치지 않는 큰 휴대폰 폭(창이 넓다고 판단하지 않는 600 미만)을 쓴다.
  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(480, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Finder backdropIn(Finder capsule) =>
      find.descendant(of: capsule, matching: find.byType(BackdropFilter));

  testWidgets('menu capsule is 196x60 glass over the photo feed', (
    tester,
  ) async {
    usePhone(tester);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const EselApp());
    await tester.pumpAndSettle();

    final capsule = find.byKey(const Key('menu-capsule'));
    expect(capsule, findsOneWidget);
    expect(tester.getSize(capsule), const Size(196, 60));
    expect(tester.widget<EselGlass>(capsule).solid, isFalse);
    expect(backdropIn(capsule), findsOneWidget);
    expect(find.bySemanticsLabel('오늘의 색 가판대'), findsOneWidget);
    expect(find.bySemanticsLabel('표지 만들기'), findsOneWidget);
    expect(find.bySemanticsLabel('내 잡지'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('menu capsule turns solid on the white stand screen', (
    tester,
  ) async {
    usePhone(tester);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const EselApp());
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('오늘의 색 가판대'));
    await tester.pumpAndSettle();

    final capsule = find.byKey(const Key('menu-capsule'));
    expect(tester.getSize(capsule), const Size(196, 60));
    expect(tester.widget<EselGlass>(capsule).solid, isTrue);
    expect(backdropIn(capsule), findsNothing);
    semantics.dispose();
  });

  testWidgets('지금 보는 쪽(가판대·내 잡지) 아래에 점, 세 항목 모두 48 이상', (tester) async {
    usePhone(tester);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const EselApp());
    await tester.pumpAndSettle();
    Finder dot(String tab) => find.byKey(ValueKey('capsule-dot-$tab'));

    // 피드에서는 점이 없다.
    expect(dot('stand'), findsNothing);
    expect(dot('me'), findsNothing);
    for (final label in ['오늘의 색 가판대', '표지 만들기', '내 잡지']) {
      final size = tester.getSize(find.bySemanticsLabel(label));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }

    await tester.tap(find.bySemanticsLabel('오늘의 색 가판대'));
    await tester.pumpAndSettle();
    expect(dot('stand'), findsOneWidget);
    expect(dot('me'), findsNothing);

    await tester.tap(find.bySemanticsLabel('내 잡지'));
    await tester.pumpAndSettle();
    expect(dot('me'), findsOneWidget);
    expect(dot('stand'), findsNothing);
    semantics.dispose();
  });
}
