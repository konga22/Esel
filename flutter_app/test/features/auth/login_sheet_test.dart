import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/config/app_config.dart';
import 'package:esel/core/network/http_client.dart';
import 'package:esel/core/storage/session_storage.dart';
import 'package:esel/core/ui/esel_glass.dart';
import 'package:esel/core/ui/esel_pressable.dart';
import 'package:esel/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:esel/features/auth/data/sources/auth_mock_source.dart';
import 'package:esel/features/auth/data/sources/auth_remote_source.dart';
import 'package:esel/features/auth/presentation/controllers/auth_controller.dart';
import 'package:esel/features/auth/presentation/screens/email_login_view.dart';
import 'package:esel/features/auth/presentation/screens/login_sheet.dart';

void main() {
  late AuthController controller;

  setUp(() {
    const config = AppConfig(apiMode: ApiMode.mock);
    AppConfig.current = config;
    final storage = InMemorySessionStorage();
    controller = AuthController(
      AuthRepositoryImpl(
        config: config,
        storage: storage,
        mockSource: AuthMockSource(),
        remoteSource: AuthRemoteSource(
          StandardHttpClient(config: config, storage: storage),
        ),
      ),
    );
  });

  // 디자인 기준 화면 393×852.
  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> openSheet(
    WidgetTester tester, {
    bool solid = false,
    VoidCallback? onLoginSuccess,
    VoidCallback? onStartJoin,
    VoidCallback? onCancel,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => LoginSheet.show(
                  context,
                  authController: controller,
                  onLoginSuccess: onLoginSuccess ?? () {},
                  onStartJoin: onStartJoin,
                  onCancel: onCancel,
                  solid: solid,
                ),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
  }

  Finder sheetGlass() => find.descendant(
    of: find.byType(LoginSheet),
    matching: find.byType(EselGlass),
  );
  Finder backdropIn(Finder finder) =>
      find.descendant(of: finder, matching: find.byType(BackdropFilter));

  testWidgets('login sheet is glass with top corners 28 over a dimmed cover', (
    tester,
  ) async {
    usePhone(tester);
    await openSheet(tester, onStartJoin: () {});

    final glass = tester.widget<EselGlass>(sheetGlass());
    expect(glass.solid, isFalse);
    expect(
      glass.corners,
      const BorderRadius.vertical(top: Radius.circular(28)),
    );
    expect(backdropIn(sheetGlass()), findsOneWidget);

    // 화면 폭 전체, 아래에 붙는다.
    final rect = tester.getRect(sheetGlass());
    expect(rect.left, 0);
    expect(rect.width, 393);
    expect(rect.bottom, 852);

    // 시트 뒤 표지를 rgba(20, 20, 18, 0.32)로 덮는다.
    final barrier = tester.widgetList<ModalBarrier>(find.byType(ModalBarrier));
    expect(barrier.last.color, LoginSheet.barrierColor);

    expect(find.text('Esel에 들어가기'), findsOneWidget);
    for (final label in ['Apple로 계속하기', 'Google로 계속하기', '이메일로 계속하기']) {
      final option = find.ancestor(
        of: find.text(label),
        matching: find.byType(EselPressable),
      );
      expect(tester.getSize(option).height, 54, reason: label);
    }
    expect(find.text('처음이라면'), findsOneWidget);
    expect(find.text('내 잡지 만들기'), findsOneWidget);
  });

  testWidgets('login sheet turns solid on a white screen', (tester) async {
    usePhone(tester);
    await openSheet(tester, solid: true);

    final glass = tester.widget<EselGlass>(sheetGlass());
    expect(glass.solid, isTrue);
    expect(backdropIn(sheetGlass()), findsNothing);
    // 창간으로 갈 곳이 없으면 "처음이라면" 줄을 숨긴다.
    expect(find.text('처음이라면'), findsNothing);
  });

  testWidgets('email login still signs in and closes the glass sheet', (
    tester,
  ) async {
    usePhone(tester);
    var successes = 0;
    await openSheet(tester, onLoginSuccess: () => successes++);

    await tester.tap(find.text('이메일로 계속하기'));
    await tester.pumpAndSettle();
    expect(find.byType(EmailLoginView), findsOneWidget);
    expect(sheetGlass(), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'dana@esel.app');
    await tester.enterText(find.byType(TextField).at(1), 'esel1234');
    await tester.tap(
      find.descendant(
        of: find.byType(EmailLoginView),
        matching: find.text('로그인'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(controller.isAuthenticated, isTrue);
    expect(successes, 1);
    expect(find.byType(LoginSheet), findsNothing);
  });

  testWidgets('Apple button still signs in through the mock', (tester) async {
    usePhone(tester);
    var successes = 0;
    await openSheet(tester, onLoginSuccess: () => successes++);

    await tester.tap(find.text('Apple로 계속하기'));
    await tester.pump();
    expect(find.text('연결 중...'), findsNWidgets(2));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(controller.isAuthenticated, isTrue);
    expect(successes, 1);
    expect(find.byType(LoginSheet), findsNothing);
  });

  testWidgets('first-timer link closes the sheet and starts the magazine', (
    tester,
  ) async {
    usePhone(tester);
    var joins = 0;
    await openSheet(tester, onStartJoin: () => joins++);

    await tester.tap(find.text('내 잡지 만들기'));
    await tester.pumpAndSettle();

    expect(joins, 1);
    expect(find.byType(LoginSheet), findsNothing);
    expect(controller.isAuthenticated, isFalse);
  });

  testWidgets('close button dismisses without signing in', (tester) async {
    usePhone(tester);
    var cancels = 0;
    await openSheet(tester, onCancel: () => cancels++);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(cancels, 1);
    expect(find.byType(LoginSheet), findsNothing);
  });
}
