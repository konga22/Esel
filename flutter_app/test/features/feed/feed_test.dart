import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/features/feed/data/sources/feed_mock_source.dart';
import 'package:esel/features/feed/domain/rules/masthead_melt.dart';
import 'package:esel/features/feed/presentation/controllers/feed_controller.dart';
import 'package:esel/features/feed/presentation/screens/feed_screen.dart';
import 'package:esel/features/reactions/presentation/controllers/reactions_controller.dart';
import 'package:esel/features/stand/domain/rules/same_color_rule.dart';
import 'package:esel/features/today/domain/rules/daily_candidates.dart';

void main() {
  group('DEV-10 P16 사인 녹아들기(scroll.mjs와 같은 값)', () {
    MastheadMelt scrolled(List<double> path) {
      final melt = MastheadMelt();
      for (final y in path) {
        melt.update(y);
      }
      return melt;
    }

    test('내리면 사인이 표지와 함께 올라가고 300px 넘으면 사라진다', () {
      final melt = scrolled([0, 120]);
      expect(melt.mode, MastheadMode.cover);
      expect(melt.frame().translateY, -120);
      expect(melt.frame().scale, 1);
      melt.update(400);
      expect(melt.frame().opacity, 0);
      expect(melt.frame().pill, 0);
    });

    test('위로 48px 올리면 작은 로고, 아래로 18px 내리면 숨는다', () {
      final melt = scrolled([0, 600, 1500, 1460]);
      expect(melt.mode, MastheadMode.cover, reason: '40px로는 아직');
      melt.update(1452);
      expect(melt.mode, MastheadMode.float);
      final pill = melt.frame();
      expect(pill.scale, MastheadMelt.smallScale);
      expect(pill.translateY, MastheadMelt.pillOffset);
      expect(pill.pillVisible, isTrue);
      expect(pill.dot, 1);

      melt.update(1462);
      expect(melt.mode, MastheadMode.float, reason: '10px로는 아직');
      melt.update(1470);
      expect(melt.mode, MastheadMode.cover);
      expect(melt.frame().pill, 0);
    });

    test('맨 위 360px 안에서는 작은 로고가 커지며 사인로 녹아든다', () {
      final melt = scrolled([0, 1500, 1400, 360]);
      expect(melt.mode, MastheadMode.float);
      expect(melt.frame().scale, closeTo(MastheadMelt.smallScale, 1e-9));
      melt.update(180); // 진행 50%: smoothstep 0.5
      final half = melt.frame();
      expect(half.scale, closeTo(0.14 + 0.86 * 0.5, 1e-9));
      expect(half.translateY, MastheadMelt.pillOffset);
      expect(half.pill, 0, reason: '알약은 진행 18% 안에 사라짐');
      melt.update(340);
      expect(melt.frame().pill, greaterThan(0));
      melt.update(0);
      expect(melt.mode, MastheadMode.cover);
      final top = melt.frame();
      expect(top.scale, 1);
      expect(top.translateY, 0);
    });

    test('움직임 줄이기에서는 녹아들지 않고 맨 위에서 한 번에 바뀐다', () {
      final melt = scrolled([0, 1500, 1400, 180]);
      final calm = melt.frame(calm: true);
      expect(calm.scale, MastheadMelt.smallScale);
      expect(calm.pillVisible, isTrue);
      melt.update(0);
      expect(melt.frame(calm: true).scale, 1);
    });
  });

  testWidgets('DEV-10 표지는 첫 장만: Esel 사인은 하나, 안쪽 지면은 사인 없이 각자 색 이름', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    final today = DailyCandidates.demoDate;
    final viewer = SameColorViewer(
      today: today,
      candidates: DailyCandidates.forDate(today),
      hasPublishedToday: true,
      isMinor: false,
    );
    final feed = FeedController(FeedMockSource());
    await tester.pumpWidget(
      MaterialApp(
        home: FeedScreen(
          feedController: feed,
          reactionsController: ReactionsController(),
          viewer: viewer,
          onOpenAuthorShelf: (_) {},
          onOpenIssue: (_) {},
          onOpenStand: (_) {},
          onMakeTodayIssue: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Esel'), findsOneWidget);
    expect(find.text('Nº 249 · 2026. 9. 6.'), findsOneWidget);
    expect(find.text('파우더 블루 · 같은 색 3명'), findsOneWidget);
    // 안쪽 지면(ama 버터, lise 버건디 …)은 사인 없이 자기 색 이름.
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pump();
    expect(find.text('ama'), findsOneWidget);
    expect(find.text('버터'), findsOneWidget);
    expect(find.text('Esel'), findsOneWidget, reason: '사인은 스크롤 레이어 하나뿐');

    // 한참 내렸다가 위로 올리면 작은 로고, 누르면 맨 위로.
    final list = tester.widget<ListView>(find.byType(ListView));
    final scroll = list.controller!;
    scroll.jumpTo(1500);
    await tester.pump();
    scroll.jumpTo(1440);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    final logo = find.bySemanticsLabel('맨 위 표지로 돌아가기');
    expect(logo, findsOneWidget);
    await tester.tap(logo);
    await tester.pumpAndSettle();
    expect(scroll.offset, 0);
    semantics.dispose();
  });
}
