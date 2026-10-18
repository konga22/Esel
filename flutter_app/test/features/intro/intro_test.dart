import 'package:esel/core/config/app_config.dart';
import 'package:esel/core/network/http_client.dart';
import 'package:esel/core/storage/session_storage.dart';
import 'package:esel/features/feed/data/sources/feed_remote_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/ui/esel_glass.dart';
import 'package:esel/core/ui/esel_pressable.dart';
import 'package:esel/features/feed/data/sources/feed_mock_source.dart';
import 'package:esel/features/feed/presentation/controllers/feed_controller.dart';
import 'package:esel/features/intro/presentation/screens/intro_screen.dart';
import 'package:esel/features/today/domain/rules/daily_candidates.dart';

void main() {
  group('DEV-04 IntroScreen Tests (P12, P16)', () {
    // 디자인 기준 화면 393×852.
    void usePhone(WidgetTester tester) {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    Finder inBar(String text) => find.descendant(
      of: find.byKey(const Key('login-bar')),
      matching: find.text(text),
    );
    Finder barButton(String text) =>
        find.ancestor(of: inBar(text), matching: find.byType(EselPressable));

    testWidgets(
      'unavailable remote feed still exposes working login and join buttons',
      (tester) async {
        usePhone(tester);
        var logins = 0, joins = 0;
        final feed = FeedController(
          FeedRemoteSource(
            StandardHttpClient(
              config: const AppConfig(),
              storage: InMemorySessionStorage(),
            ),
          ),
        );
        addTearDown(feed.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: IntroScreen(
              feedController: feed,
              today: DailyCandidates.demoDate,
              onOpenLogin: () => logins++,
              onStartJoin: () => joins++,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('서버 피드는 아직 연결하지 않았어요.'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        await tester.tap(inBar('로그인'));
        await tester.tap(inBar('스케치북 만들기'));
        expect(logins, 1);
        expect(joins, 1);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets('renders cover, scroll brings glass login bar', (tester) async {
      usePhone(tester);
      var logins = 0;
      var joins = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: IntroScreen(
            feedController: FeedController(FeedMockSource()),
            today: DailyCandidates.demoDate,
            onOpenLogin: () => logins++,
            onStartJoin: () => joins++,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Esel'), findsOneWidget);
      expect(find.text('dana'), findsOneWidget);
      // 표지 오른쪽 위 "로그인" 칩은 디자인에 없다. 로그인은 아래 로그인 바에서만.
      expect(find.text('로그인'), findsOneWidget);
      expect(inBar('로그인'), findsOneWidget);

      // 640px 전에는 로그인 바가 눌리지 않는다.
      await tester.tap(inBar('로그인'), warnIfMissed: false);
      expect(logins, 0);

      // Scroll to trigger login bar
      await tester.drag(find.byType(ListView), const Offset(0, -700));
      await tester.pumpAndSettle();

      // 디자인 "로그인 바": 좌우 16, 아래 34, 높이 66, 사진 위 Glass.
      final bar = find.byKey(const Key('login-bar'));
      expect(bar, findsOneWidget);
      expect(tester.widget<EselGlass>(bar).solid, isFalse);
      expect(
        find.descendant(of: bar, matching: find.byType(BackdropFilter)),
        findsOneWidget,
      );
      expect(
        tester.getRect(bar),
        const Rect.fromLTRB(16, 852 - 34 - 66, 393 - 16, 852 - 34),
      );

      // 로그인 : 스케치북 만들기 = 1 : 1.35, 버튼 높이 50.
      final login = tester.getSize(barButton('로그인'));
      final join = tester.getSize(barButton('스케치북 만들기'));
      expect(login.height, 50);
      expect(join.height, 50);
      expect(join.width / login.width, closeTo(1.35, 0.001));

      await tester.tap(inBar('로그인'));
      await tester.tap(inBar('스케치북 만들기'));
      expect(logins, 1);
      expect(joins, 1);
    });

    testWidgets('login bar goes away when scrolled back to the cover', (
      tester,
    ) async {
      usePhone(tester);
      var logins = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: IntroScreen(
            feedController: FeedController(FeedMockSource()),
            today: DailyCandidates.demoDate,
            onOpenLogin: () => logins++,
            onStartJoin: () {},
          ),
        ),
      );
      await tester.pump();

      await tester.drag(find.byType(ListView), const Offset(0, -700));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, 700));
      await tester.pumpAndSettle();

      await tester.tap(inBar('로그인'), warnIfMissed: false);
      expect(logins, 0);
      expect(
        tester.getRect(find.byKey(const Key('login-bar'))).top,
        greaterThan(852 - 34 - 66),
      );
    });

    testWidgets('맛보기 끝은 안내 글만(중복 버튼 없음), 남은 쪽 수는 데이터에서', (tester) async {
      usePhone(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: IntroScreen(
            feedController: FeedController(FeedMockSource()),
            today: DailyCandidates.demoDate,
            onOpenLogin: () {},
            onStartJoin: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, -2400));
      await tester.pumpAndSettle();

      // 예시 인물 27명 중 표지 + 안쪽 2쪽을 뺀 24쪽.
      expect(find.text('오늘의 캔버스는 아직\n스물네 쪽이 더 남았어요.'), findsOneWidget);
      expect(find.text('로그인하면 끝까지 읽고, 스케치북도 만들 수 있어요.'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.text('스케치북 만들기'), findsOneWidget, reason: '로그인 바의 것 하나');
    });
  });
}
