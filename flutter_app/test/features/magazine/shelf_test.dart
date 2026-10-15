import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/features/magazine/data/sources/magazine_mock_source.dart';
import 'package:esel/features/magazine/presentation/controllers/magazine_controller.dart';
import 'package:esel/features/magazine/presentation/screens/shelf_screen.dart';
import 'package:esel/features/reactions/presentation/controllers/reactions_controller.dart';
import 'package:esel/features/stand/domain/rules/same_color_rule.dart';
import 'package:esel/features/today/domain/rules/daily_candidates.dart';

void main() {
  testWidgets('DEV-13 누른 사람의 서가가 열린다(예시 seul 고정 아님)', (tester) async {
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
    expect(find.textContaining('호 발행'), findsOneWidget);
    // 남의 서가에 구독자 수 같은 숫자는 없다(P18).
    expect(find.textContaining('구독자'), findsNothing);

    await open('demo_lise');
    expect(find.text('lise'), findsWidgets);
    expect(find.text('kofi'), findsNothing);

    // 구독은 그 사람(주인 id)에게.
    await tester.tap(find.text('구독'));
    await tester.pump();
    expect(reactions.isSubscribed('demo_lise'), isTrue);
    expect(find.text('구독 중'), findsOneWidget);
  });
}
