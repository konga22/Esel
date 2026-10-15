import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/design/tokens.g.dart';
import 'package:esel/core/time/service_clock.dart';
import 'package:esel/core/time/service_date.dart';
import 'package:esel/features/drafts/data/local_library.dart';
import 'package:esel/features/drafts/domain/cover_draft.dart';
import 'package:esel/features/stand/domain/rules/same_color_rule.dart';
import 'package:esel/features/stand/presentation/controllers/stand_controller.dart';
import 'package:esel/features/stand/presentation/screens/stand_screen.dart';
import 'package:esel/features/today/presentation/controllers/today_controller.dart';

void main() {
  // 서울 2026-10-15 정오.
  final noon = DateTime.utc(2026, 10, 15, 3);
  late Directory directory;
  late LocalLibrary library;
  late ManualServiceClock clock;
  late TodayController today;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('esel-stand-test-');
    library = LocalLibrary(directory);
    await library.load();
    clock = ManualServiceClock(noon);
    today = TodayController(clock: clock)..library = library;
    today.bindUser(ownerId: 'reader-a');
  });
  tearDown(() async {
    today.dispose();
    library.dispose();
    await directory.delete(recursive: true);
  });

  CoverDraft draft(EselPaint color) => CoverDraft(
    id: library.newId(),
    photoPath: 'photo.png',
    masthead: 'reader',
    color: color,
    faceConfirmed: true,
    updatedAt: clock.now(),
  );

  Future<void> pumpStand(WidgetTester tester, StandController stand) async {
    tester.view.physicalSize = const Size(480, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: AnimatedBuilder(
          animation: today,
          builder: (context, _) => StandScreen(
            controller: stand,
            viewer: today.viewer,
            onSelectCover: (_) {},
            onMakeTodayIssue: () {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Finder lockIcons() => find.byIcon(Icons.lock_outline);

  group('DEV-12 가판대 · 같은 색 잠금(P01)', () {
    testWidgets('발행 전에는 후보 3색 칩 모두에 자물쇠, 그 방은 3장과 흐린 책등', (tester) async {
      final stand = StandController();
      await pumpStand(tester, stand);

      expect(find.text('가판대'), findsOneWidget);
      expect(today.candidates, hasLength(3));
      // 칩의 자물쇠는 후보 3색에만.
      expect(lockIcons(), findsNWidgets(3));
      for (final color in today.candidates) {
        expect(
          find.bySemanticsLabel(
            '${EselPaints.of(color).nameKo} · 오늘 발행 전이라 세 장만 먼저 보여요',
          ),
          findsOneWidget,
        );
      }

      // 카멜 방: 오늘 카멜 표지 4장 중 최신 3장만, 1장은 이름 없이 개수만.
      stand.select(EselPaint.camel);
      await tester.pump();
      expect(find.text('발행하면 함께 펼쳐집니다'), findsOneWidget);
      expect(find.text('오늘의 카멜 · 4명'), findsOneWidget);
      expect(find.text('먼저 3장'), findsOneWidget);
      for (final name in ['mara', 'selin', 'noor']) {
        expect(find.text(name), findsOneWidget);
      }
      expect(find.text('leo'), findsNothing);
      expect(find.textContaining('카멜 표지 1장이 더 있어요.'), findsOneWidget);
      expect(find.textContaining('놓치면'), findsNothing);
    });

    testWidgets('후보 색을 몇 번 바꿔도 어떤 방도 열리지 않는다', (tester) async {
      final stand = StandController();
      await pumpStand(tester, stand);

      for (final picked in [
        EselPaint.camel,
        EselPaint.lilac,
        EselPaint.olive,
        EselPaint.camel,
      ]) {
        today.pick(picked);
        expect(today.myColor, picked);
        for (final color in today.candidates) {
          expect(SameColorRule.isLockedToday(color, today.viewer), isTrue);
          stand.select(color);
          expect(stand.shelfFor(today.viewer).isPreview, isTrue);
        }
      }
      // 후보 밖의 색은 고를 수 없다(P17).
      today.pick(EselPaint.cobalt);
      expect(today.myColor, EselPaint.camel);
      stand.select(EselPaint.camel);
      await tester.pump();
      expect(lockIcons(), findsNWidgets(3 + 1)); // 칩 3개 + 잠긴 방 안내
    });

    test('초안 저장(확정)만으로는 열리지 않는다(P03)', () async {
      await library.save(draft(EselPaint.camel));
      expect(today.hasPublishedToday, isFalse);
      expect(
        SameColorRule.isLockedToday(EselPaint.camel, today.viewer),
        isTrue,
      );
    });

    testWidgets('오늘 발행하면 모든 방이 열린다', (tester) async {
      final stand = StandController();
      await pumpStand(tester, stand);
      await tester.runAsync(
        () => library.publish(
          draft(EselPaint.lilac),
          'reader-a',
          now: clock.now(),
        ),
      );
      await tester.pump();

      expect(today.hasPublishedToday, isTrue);
      expect(today.issueCount, 1);
      expect(today.myColor, EselPaint.lilac);
      expect(lockIcons(), findsNothing);
      stand.select(EselPaint.camel);
      await tester.pump();
      expect(find.text('발행하면 함께 펼쳐집니다'), findsNothing);
      for (final name in ['mara', 'selin', 'noor', 'leo']) {
        expect(find.text(name), findsOneWidget);
      }
    });

    test('자정이 지나면 어제 방은 열리고 새 날짜 후보 방은 다시 잠긴다', () async {
      await library.publish(
        draft(EselPaint.camel),
        'reader-a',
        now: clock.now(),
      );
      expect(today.hasPublishedToday, isTrue);
      final yesterday = today.today;

      clock.set(DateTime.utc(2026, 10, 15, 15, 1)); // 서울 10-16 00:01
      today.refresh();
      expect(today.today, const ServiceDate(2026, 10, 16));
      expect(today.hasPublishedToday, isFalse);
      expect(today.issueCount, 1);
      for (final color in EselPaint.values) {
        expect(
          SameColorRule.accessFor(
            color: color,
            date: yesterday,
            viewer: today.viewer,
          ),
          SameColorRoomAccess.open,
        );
      }
      for (final color in today.candidates) {
        expect(SameColorRule.isLockedToday(color, today.viewer), isTrue);
      }
    });

    testWidgets('후보가 아닌 색은 발행 전에도 열려 있다', (tester) async {
      final stand = StandController();
      await pumpStand(tester, stand);
      final open = EselPaint.values.firstWhere(
        (c) => !today.candidates.contains(c),
      );
      stand.select(open);
      await tester.pump();
      final shelf = stand.shelfFor(today.viewer);
      expect(shelf.isPreview, isFalse);
      expect(shelf.hiddenCount, 0);
      expect(find.text('발행하면 함께 펼쳐집니다'), findsNothing);
    });

    testWidgets('전체 칸에는 잠긴 후보 색 표지가 꽂히지 않는다', (tester) async {
      final stand = StandController();
      await pumpStand(tester, stand);
      final shelf = stand.shelfFor(today.viewer);
      expect(
        shelf.items.where((item) => today.candidates.contains(item.color)),
        isEmpty,
      );
      expect(find.text('leo'), findsNothing);
    });

    testWidgets('미성년자는 잠금이 없다', (tester) async {
      today.bindUser(ownerId: 'reader-a', isMinor: true);
      final stand = StandController();
      await pumpStand(tester, stand);
      expect(lockIcons(), findsNothing);
      stand.select(today.candidates.first);
      expect(stand.shelfFor(today.viewer).isPreview, isFalse);
    });
  });
}
