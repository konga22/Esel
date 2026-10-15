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

      // 로그인 : 내 잡지 만들기 = 1 : 1.35, 버튼 높이 50.
      final login = tester.getSize(barButton('로그인'));
      final join = tester.getSize(barButton('내 잡지 만들기'));
      expect(login.height, 50);
      expect(join.height, 50);
      expect(join.width / login.width, closeTo(1.35, 0.001));

      await tester.tap(inBar('로그인'));
      await tester.tap(inBar('내 잡지 만들기'));
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
  });
}
