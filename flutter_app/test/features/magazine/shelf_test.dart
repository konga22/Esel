import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/features/magazine/data/sources/magazine_mock_source.dart';
import 'package:esel/features/magazine/presentation/controllers/magazine_controller.dart';
import 'package:esel/features/magazine/presentation/screens/shelf_screen.dart';
import 'package:esel/features/reactions/presentation/controllers/reactions_controller.dart';
import 'package:esel/features/stand/domain/rules/same_color_rule.dart';
import 'package:esel/features/today/domain/rules/daily_candidates.dart';

void main() {
  testWidgets('DEV-13 누른 사람의 스케치북이 열린다(예시 seul 고정 아님)', (tester) async {
    tester.view.physicalSize = const Size(480, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = MagazineController(MagazineMockSource());
    final reactions = ReactionsController();
    const viewer = SameColorViewer.reader(DailyCandidates.demoDate);

    Future<void> open(String ownerId) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ShelfScreen(
            ownerId: ownerId,
            controller: controller,
            reactionsController: reactions,
            viewer: viewer,
            onSelectIssue: (_, _) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
    }

    await open('demo_kofi');
    expect(find.text('kofi'), findsWidgets);
    expect(find.text('seul'), findsNothing);
    expect(find.textContaining('캔버스 '), findsOneWidget);
    // 남의 스케치북에 구독자 수 같은 숫자는 없다(P18).
    expect(find.textContaining('구독자'), findsNothing);

    await open('demo_lise');
    expect(find.text('lise'), findsWidgets);
    expect(find.text('kofi'), findsNothing);

    // 구독은 그 사람(주인 id)에게.
    await tester.tap(find.text('구독'));
    await tester.pump();
    expect(reactions.isSubscribed('demo_lise'), isTrue);
    expect(find.text('구독중'), findsOneWidget);
  });

  testWidgets('DEV-14 마이페이지 격자에서 누른 장까지 세로 목록이 내려 준다', (tester) async {
    tester.view.physicalSize = const Size(480, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: ShelfScreen(
          ownerId: 'demo_kofi',
          controller: MagazineController(MagazineMockSource()),
          reactionsController: ReactionsController(),
          viewer: const SameColorViewer.reader(DailyCandidates.demoDate),
          focusIssueId: 'kofi-2026-09-02',
          onSelectIssue: (_, _) {},
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final focused = find.byWidgetPredicate(
      (w) => w is InkWell && w.key is GlobalKey,
    );
    expect(focused, findsOneWidget);
    final top = tester.getTopLeft(focused).dy;
    expect(top, inInclusiveRange(0, 1000 - 1));
    // 뒤로 버튼이 있는 머리는 위로 지나갔다.
    expect(find.byTooltip('뒤로'), findsNothing);
  });
}
