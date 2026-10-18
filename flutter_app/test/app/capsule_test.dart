import 'package:esel/features/feed/presentation/screens/feed_screen.dart';
import 'package:esel/core/design/tokens.g.dart';
import 'package:esel/features/stand/domain/models/stand_shelf.dart';
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

  Finder dot(String tab) => find.byKey(ValueKey('capsule-dot-$tab'));

  testWidgets('menu capsule is 198x60 glass over the photo feed', (
    tester,
  ) async {
    usePhone(tester);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const EselApp());
    await tester.pumpAndSettle();

    final capsule = find.byKey(const Key('menu-capsule'));
    expect(capsule, findsOneWidget);
    expect(tester.getSize(capsule), const Size(198, 60));
    expect(tester.widget<EselGlass>(capsule).solid, isFalse);
    expect(backdropIn(capsule), findsOneWidget);
    // 홈에서는 첫 칸이 팔레트(10-18 바뀌는 칸). 홈 칸은 따로 없다.
    expect(find.bySemanticsLabel('팔레트'), findsOneWidget);
    expect(find.bySemanticsLabel('홈'), findsNothing);
    expect(find.bySemanticsLabel('만들기'), findsOneWidget);
    expect(find.bySemanticsLabel('스케치북'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('menu capsule turns solid on the white palette screen', (
    tester,
  ) async {
    usePhone(tester);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const EselApp());
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('팔레트'));
    await tester.pumpAndSettle();

    final capsule = find.byKey(const Key('menu-capsule'));
    expect(tester.getSize(capsule), const Size(198, 60));
    expect(tester.widget<EselGlass>(capsule).solid, isTrue);
    expect(backdropIn(capsule), findsNothing);
    semantics.dispose();
  });

  testWidgets('첫 칸은 홈↔팔레트로 바뀌고, 점은 내 스케치북에만, 세 칸 모두 48 이상', (tester) async {
    usePhone(tester);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const EselApp());
    await tester.pumpAndSettle();

    // 홈: 첫 칸은 팔레트, 점 없음.
    expect(dot('feed'), findsNothing);
    expect(dot('stand'), findsNothing);
    expect(dot('me'), findsNothing);
    for (final label in ['팔레트', '만들기', '스케치북']) {
      final size = tester.getSize(find.bySemanticsLabel(label));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }

    // 팔레트: 첫 칸은 홈, 점 없음.
    await tester.tap(find.bySemanticsLabel('팔레트'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('홈'), findsOneWidget);
    expect(find.bySemanticsLabel('팔레트'), findsNothing);
    expect(
      tester.getSize(find.bySemanticsLabel('홈')).width,
      greaterThanOrEqualTo(48),
    );
    expect(dot('feed'), findsNothing);
    expect(dot('stand'), findsNothing);

    // 내 스케치북: 첫 칸은 홈, 스케치북 칸에 점.
    await tester.tap(find.bySemanticsLabel('스케치북'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('홈'), findsOneWidget);
    expect(dot('me'), findsOneWidget);

    // 홈으로 돌아가면 첫 칸은 다시 팔레트.
    await tester.tap(find.bySemanticsLabel('홈'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('팔레트'), findsOneWidget);
    expect(find.bySemanticsLabel('홈'), findsNothing);
    expect(dot('me'), findsNothing);
    semantics.dispose();
  });

  testWidgets('남의 스케치북은 들어온 쪽을 따른다: 홈에서 열면 팔레트, 팔레트에서 열면 홈', (tester) async {
    usePhone(tester);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const EselApp());
    await tester.pumpAndSettle();

    tester
        .widget<FeedScreen>(find.byType(FeedScreen))
        .onOpenAuthorShelf('someone-else');
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('팔레트'), findsOneWidget);
    expect(find.bySemanticsLabel('홈'), findsNothing);

    await tester.tap(find.bySemanticsLabel('팔레트'));
    await tester.pumpAndSettle();
    final cover = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('palette-cover-'),
    );
    expect(cover, findsWidgets);
    await tester.tap(cover.first);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('홈'), findsOneWidget);
    expect(find.bySemanticsLabel('팔레트'), findsNothing);
    semantics.dispose();
  });

  testWidgets('feed color link opens the color tab instead of recommended', (
    tester,
  ) async {
    usePhone(tester);
    await tester.pumpWidget(const EselApp());
    await tester.pumpAndSettle();
    tester
        .widget<FeedScreen>(find.byType(FeedScreen))
        .onOpenStand(EselPaint.camel);
    await tester.pumpAndSettle();
    expect(ServiceLocator().standController.tab, PaletteTab.colors);
    expect(ServiceLocator().standController.selected, EselPaint.camel);
  });
}
