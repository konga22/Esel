import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/app/app.dart';
import 'package:esel/app/bootstrap/app_bootstrap.dart';
import 'package:esel/app/dependencies/service_locator.dart';
import 'package:esel/core/config/app_config.dart';
import 'package:esel/core/design/tokens.g.dart';
import 'package:esel/core/time/service_clock.dart';
import 'package:esel/features/auth/data/sources/mock_account_store.dart';
import 'package:esel/features/auth/presentation/screens/email_login_view.dart';
import 'package:esel/features/drafts/data/local_library.dart';
import 'package:esel/features/intro/presentation/screens/intro_screen.dart';
import 'package:esel/features/magazine/presentation/screens/my_magazine_screen.dart';
import 'package:esel/features/media/presentation/cover_preview.dart';
import 'package:esel/features/onboarding/domain/models/onboarding_draft.dart';
import 'package:esel/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:esel/features/onboarding/presentation/screens/onboarding_screen.dart';

void main() {
  group('DEV-06 창간 규칙(P13·P14)', () {
    test('제호는 비어 있게 시작하고 예시 인물 이름으로 채우지 않는다', () {
      final c = OnboardingController();
      expect(c.draft.masthead, isEmpty);
      expect(c.draft.masthead, isNot('dana'));
      expect(c.draft.color, isNull);
      expect(c.canProceed(), isFalse);
    });

    test('제호는 소문자만 남기고 10자에서 멈추며, 확인된 이름만 다음으로', () async {
      final taken = {'dana', 'selin'};
      final c = OnboardingController(
        checkMasthead: (name) async => !taken.contains(name),
      );
      c.selectColor(EselPaint.camel);
      c.nextStep();
      c.setPhoto('photo.png');
      c.nextStep();
      expect(c.currentStep, OnboardingStep.name);

      expect(c.updateMasthead('My Magazine 2026!'), 'mymagazine');
      expect(c.draft.mastheadStatus, MastheadStatus.checking);
      expect(c.canProceed(), isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(c.draft.mastheadStatus, MastheadStatus.available);
      expect(c.canProceed(), isTrue);

      c.updateMasthead('dana');
      await Future<void>.delayed(Duration.zero);
      expect(c.draft.mastheadStatus, MastheadStatus.taken);
      expect(c.canProceed(), isFalse);

      c.updateMasthead('a');
      expect(c.draft.mastheadStatus, MastheadStatus.tooShort);
      expect(c.canProceed(), isFalse);
    });

    test('얼굴 위치를 정하기 전에는 창간할 수 없다(P11)', () {
      final c = OnboardingController()
        ..selectColor(EselPaint.camel)
        ..nextStep()
        ..setPhoto('photo.png')
        ..nextStep()
        ..updateMasthead('mymag')
        ..nextStep()
        ..nextStep();
      expect(c.currentStep, OnboardingStep.face);
      expect(c.canProceed(), isFalse);
      c.placeFace(const Offset(.5, .3));
      expect(c.canProceed(), isTrue);
      // 창간호는 실제로 발행한 뒤에만 열린다.
      c.nextStep();
      expect(c.currentStep, OnboardingStep.face);
      // 사진을 바꾸면 얼굴 위치를 다시 정한다.
      c.setPhoto('other.png');
      expect(c.canProceed(), isFalse);
    });
  });

  group('DEV-06 창간 → 창간호 Nº 001', () {
    // 서울 2026-10-15 정오.
    final clock = ManualServiceClock(DateTime.utc(2026, 10, 15, 3));

    testWidgets('로그인 전 창간: 색 → 사진 → 제호 → 얼굴 → 계정 → Nº 001이 내 잡지에', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(480, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();
      // 보관함의 쓰기 대기열이 테스트의 가짜 시간 안에서 돌도록 여기서 만든다.
      AppConfig.current = const AppConfig(apiMode: ApiMode.mock);
      final library = LocalLibrary.inMemory();
      await AppBootstrap.setup(
        localLibrary: library,
        clock: clock,
        accountVault: InMemoryMockAccountVault(),
      );
      final sl = ServiceLocator();
      final today = sl.todayController;

      await tester.pumpWidget(const EselApp());
      await tester.pumpAndSettle();
      expect(find.byType(IntroScreen), findsOneWidget);

      // J1 로그인 바의 "내 잡지 만들기"로 창간을 시작한다.
      final intro = tester.state(find.byType(IntroScreen));
      expect(intro, isNotNull);
      (tester.widget<IntroScreen>(find.byType(IntroScreen))).onStartJoin();
      await tester.pumpAndSettle();
      expect(find.text('창간 1 / 4'), findsOneWidget);
      expect(find.text('${today.today.label} 오늘의 색'), findsOneWidget);

      // J3: 오늘 후보 중 두 번째 색.
      final color = today.candidates[1];
      await tester.tap(find.bySemanticsLabel(EselPaints.of(color).nameKo));
      await tester.pump();
      await tester.tap(find.textContaining('찍기'));
      await tester.pumpAndSettle();
      expect(find.text('창간 2 / 4'), findsOneWidget);

      // J4: 촬영은 기기 카메라라 테스트에서는 사진 경로만 넣는다.
      sl.onboardingController
        ..setPhoto('founding.png')
        ..nextStep();
      await tester.pumpAndSettle();
      expect(find.text('창간 3 / 4'), findsOneWidget);

      // J5: 제호. 예시 인물 이름은 이미 있는 이름이다.
      final field = find.byKey(const Key('founding-masthead'));
      expect(tester.widget<TextField>(field).controller!.text, isEmpty);
      await tester.enterText(field, 'Dana');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      expect(find.text('이미 있는 이름이에요. 다른 이름을 적어 주세요.'), findsOneWidget);
      await tester.enterText(field, 'Mina Kim');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      expect(tester.widget<TextField>(field).controller!.text, 'minakim');
      expect(find.text('minakim — 쓸 수 있는 이름이에요.'), findsOneWidget);
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text('창간 4 / 4'), findsOneWidget);

      // J6: 얼굴 위치를 정해야 창간할 수 있다.
      await tester.tap(find.bySemanticsLabel('제호 뒤로 · 이름 뒤에 숨겨요'));
      await tester.tap(find.byType(CoverPreview));
      await tester.pump();
      await tester.tap(find.text('창간하기'));
      await tester.pumpAndSettle();

      // 계정이 없으니 계정 만들기(이메일 가입)부터.
      expect(find.text('계정을 만들고 창간해요'), findsOneWidget);
      await tester.tap(find.text('이메일로 계속하기'));
      await tester.pumpAndSettle();
      expect(find.text('이메일로 가입하기'), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byType(EmailLoginView),
          matching: find.byType(TextField).at(0),
        ),
        'mina@esel.local',
      );
      await tester.enterText(
        find.descendant(
          of: find.byType(EmailLoginView),
          matching: find.byType(TextField).at(1),
        ),
        'esel1234',
      );
      await tester.tap(find.text('가입하고 시작하기'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // J7 창간호.
      expect(find.text('창간을 축하해요'), findsOneWidget);
      expect(find.text('minakim의 첫 호가\n오늘 가판대에 올라갔어요.'), findsOneWidget);
      expect(find.text('Nº 001 · 창간호 · ${today.today.label}'), findsOneWidget);
      final session = sl.authController.currentSession!;
      expect(session.masthead, 'minakim');
      final issues = library.issuesFor(session.userId);
      expect(issues, hasLength(1));
      expect(issues.single.issueNumber, 1);
      expect(issues.single.masthead, 'minakim');
      expect(issues.single.color, color);
      expect(issues.single.faceMode, FaceLayoutMode.behindLogo);
      expect(issues.single.publishedOn, today.today.key);
      expect(today.hasPublishedToday, isTrue);

      // 내 잡지에 1호가 보인다. 같은 날 두 번째 발행은 없다.
      await tester.tap(find.text('내 잡지 보기'));
      await tester.pumpAndSettle();
      expect(find.byType(MyMagazineScreen), findsOneWidget);
      expect(find.text('총 1호 발행 · 결호 없음'), findsOneWidget);
      expect(find.text('오늘 호 발행 완료'), findsOneWidget);
      await expectLater(
        today.publish(issues.single.copyWith(issueNumber: 0)),
        throwsFormatException,
      );
      semantics.dispose();
    });
  });

  testWidgets('창간 화면 J4: 촬영으로 고른 사진을 받으면 제호 단계로', (tester) async {
    tester.view.physicalSize = const Size(480, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    final c = OnboardingController()
      ..selectColor(EselPaint.camel)
      ..nextStep();
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          controller: c,
          candidates: const [EselPaint.camel, EselPaint.lilac, EselPaint.olive],
          today: ManualServiceClock(DateTime.utc(2026, 9, 6, 3)).today,
          library: LocalLibrary.inMemory(),
          onCancel: () {},
          onFound: () async {},
          onOpenFeed: () {},
          onOpenMyMagazine: () {},
          pickPhoto: (_) async => 'picked.png',
        ),
      ),
    );
    expect(find.text('카멜이 보이게 찍어요'), findsOneWidget);
    expect(find.text('얼굴은 다음 단계에서 가릴 수 있어요.'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('촬영'));
    await tester.pumpAndSettle();
    expect(c.draft.photoPath, 'picked.png');
    expect(c.currentStep, OnboardingStep.name);
    semantics.dispose();
  });
}
