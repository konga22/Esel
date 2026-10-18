import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/design/tokens.g.dart';
import 'package:esel/core/time/service_clock.dart';
import 'package:esel/core/time/service_date.dart';
import 'package:esel/features/drafts/data/local_library.dart';
import 'package:esel/features/drafts/domain/cover_draft.dart';
import 'package:esel/features/stand/domain/rules/same_color_rule.dart';
import 'package:esel/features/stand/data/sources/stand_mock_source.dart';
import 'package:esel/features/stand/presentation/controllers/stand_controller.dart';
import 'package:esel/features/stand/presentation/screens/stand_screen.dart';
import 'package:esel/features/today/presentation/controllers/today_controller.dart';

void main() {
  // 서울 2026-09-06 정오. 디자인 시안의 날짜라 후보가 카멜·라일락·올리브다.
  final noon = DateTime.utc(2026, 9, 6, 3);
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
            viewerId: today.ownerId,
            onSelectCover: (_) {},
            onMakeTodayIssue: () {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Finder lockIcons() => find.byIcon(Icons.lock_outline);
  Finder sheetLocks() => find.descendant(
    of: find.byType(BottomSheet),
    matching: find.byIcon(Icons.lock_outline),
  );
  // R5-4: the color list opens from the fan (round button → 모든 색).
  Future<void> openAllColors(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('palette-fan')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('palette-all-colors')));
    await tester.pumpAndSettle();
  }

  group('DEV-12 팔레트 R5-4 · 둥근 버튼과 부채', () {
    testWidgets('위에 제목·탭 없이 둥근 버튼이 지금 보는 것을 보여 주고 부채로 바꾼다', (tester) async {
      final stand = StandController(StandMockSource(library: () => library));
      await pumpStand(tester, stand);
      expect(find.text('팔레트'), findsNothing);
      expect(find.byKey(const ValueKey('palette-colors')), findsNothing);
      expect(find.text('추천'), findsOneWidget); // label beside the round button

      await tester.tap(find.byKey(const ValueKey('palette-fan')));
      await tester.pumpAndSettle();
      for (final key in [
        'palette-fan-recommended',
        'palette-fan-subscriptions',
        'palette-all-colors',
      ]) {
        expect(find.byKey(ValueKey(key)), findsOneWidget);
      }
      // My three candidates sit on the middle arc with a lock before I post (P01).
      for (final color in today.candidates) {
        expect(
          find.byKey(ValueKey('palette-fan-color-${color.name}')),
          findsOneWidget,
        );
      }
      expect(find.byIcon(Icons.lock), findsNWidgets(3));

      await tester.tap(find.byKey(const ValueKey('palette-fan-subscriptions')));
      await tester.pumpAndSettle();
      expect(stand.tab, PaletteTab.subscriptions);
      expect(
        find.byKey(const ValueKey('palette-fan-recommended')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('palette-fan')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('palette-fan-color-camel')));
      await tester.pumpAndSettle();
      expect(stand.tab, PaletteTab.colors);
      expect(stand.selected, EselPaint.camel);
      expect(find.textContaining('같은 색'), findsOneWidget); // the room head
      expect(find.text('올리면 함께 펼쳐집니다'), findsOneWidget);
    });

    // #23 리뷰: 앱 위쪽에 오류 안내 줄이 끼면 이 화면만 짧아진다. 부채는 둥근 버튼을 둘러싸야 한다.
    for (final banner in [0.0, 80.0]) {
      testWidgets('위쪽 안내 ${banner.round()}px에서도 부채가 둥근 버튼을 중심으로 펼쳐진다', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(480, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final stand = StandController(StandMockSource(library: () => library));
        await tester.pumpWidget(
          MaterialApp(
            home: Column(
              children: [
                SizedBox(height: banner),
                Expanded(
                  child: StandScreen(
                    controller: stand,
                    viewer: today.viewer,
                    viewerId: today.ownerId,
                    onSelectCover: (_) {},
                    onMakeTodayIssue: () {},
                  ),
                ),
              ],
            ),
          ),
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('palette-fan')));
        await tester.pumpAndSettle();
        final button = tester.getCenter(
          find.byKey(const ValueKey('palette-fan')),
        );
        Offset on(double r, double deg) =>
            button +
            Offset(
              r * math.cos(deg * math.pi / 180),
              r * math.sin(deg * math.pi / 180),
            );
        for (final (key, deg) in [
          ('palette-fan-recommended', 200.0),
          ('palette-fan-subscriptions', 250.0),
        ]) {
          final got = tester.getCenter(find.byKey(ValueKey(key)));
          expect((got - on(80, deg)).distance, lessThan(1), reason: key);
        }
      });
    }

    testWidgets('모든 색 버튼은 누르는 영역이 48 이상', (tester) async {
      final stand = StandController(StandMockSource(library: () => library));
      await pumpStand(tester, stand);
      await tester.tap(find.byKey(const ValueKey('palette-fan')));
      await tester.pumpAndSettle();
      final size = tester.getSize(
        find.byKey(const ValueKey('palette-all-colors')),
      );
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(find.bySemanticsLabel('모든 색'), findsOneWidget);
    });

    testWidgets('바깥을 누르면 부채가 닫힌다', (tester) async {
      final stand = StandController(StandMockSource(library: () => library));
      await pumpStand(tester, stand);
      await tester.tap(find.byKey(const ValueKey('palette-fan')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(40, 120));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('palette-fan-recommended')),
        findsNothing,
      );
      expect(stand.tab, PaletteTab.recommended);
    });
  });

  group('DEV-12 팔레트 · 같은 색 잠금(P01)', () {
    testWidgets('올리기 전에는 후보 3색 칩 모두에 자물쇠, 그 방은 3장과 흐린 책등', (tester) async {
      final stand = StandController(StandMockSource(library: () => library));
      await pumpStand(tester, stand);

      expect(find.byKey(const ValueKey('palette-fan')), findsOneWidget);
      expect(today.candidates, hasLength(3));
      await openAllColors(tester);
      expect(sheetLocks(), findsNWidgets(3));
      await tester.tap(find.text('카멜').last);
      await tester.pumpAndSettle();
      // 카멜 방: 오늘 카멜 표지 4장 중 최신 3장만, 1장은 이름 없이 개수만.
      stand.select(EselPaint.camel);
      await tester.pump();
      expect(find.text('올리면 함께 펼쳐집니다'), findsOneWidget);
      expect(stand.tiles, hasLength(3));
      expect(stand.shelf!.hiddenCount, 1);
      // Cells carry only the photo (R5-4); who is visible is what the controller hands the grid.
      expect(
        stand.tiles.map((v) => v.masthead),
        containsAll(['mara', 'selin', 'noor']),
      );
      expect(stand.tiles.map((v) => v.masthead), isNot(contains('leo')));
      expect(find.textContaining('1장이 더 있어요'), findsOneWidget);
      expect(find.textContaining('놓치면'), findsNothing);
    });

    testWidgets(
      'color picker puts my selected candidate first and separates other colors',
      (tester) async {
        final stand = StandController(StandMockSource(library: () => library))
          ..preferredColor = EselPaint.lilac;
        await pumpStand(tester, stand);
        await openAllColors(tester);
        final titles = tester
            .widgetList<ListTile>(find.byType(ListTile))
            .map((v) => (v.title as Text).data)
            .toList();
        expect(titles.take(4), ['모든 색', '라일락', '카멜', '올리브']);
        expect(
          find.byKey(const Key('palette-candidate-divider')),
          findsOneWidget,
        );
      },
    );

    testWidgets('후보 색을 몇 번 바꿔도 어떤 방도 열리지 않는다', (tester) async {
      final stand = StandController(StandMockSource(library: () => library));
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
          await tester.pump();
          expect(stand.shelf!.isPreview, isTrue);
        }
      }
      // 후보 밖의 색은 고를 수 없다(P17).
      today.pick(EselPaint.cobalt);
      expect(today.myColor, EselPaint.camel);
      stand.select(EselPaint.camel);
      await tester.pump();
      await openAllColors(tester);
      expect(sheetLocks(), findsNWidgets(3));
    });

    test('초안 저장(확정)만으로는 열리지 않는다(P03)', () async {
      await library.save(draft(EselPaint.camel));
      expect(today.hasPublishedToday, isFalse);
      expect(
        SameColorRule.isLockedToday(EselPaint.camel, today.viewer),
        isTrue,
      );
    });

    testWidgets('오늘 올리면 모든 방이 열린다', (tester) async {
      final stand = StandController(StandMockSource(library: () => library));
      await pumpStand(tester, stand);
      await tester.runAsync(() => today.publish(draft(EselPaint.lilac)));
      await tester.pump();

      expect(today.hasPublishedToday, isTrue);
      expect(today.issueCount, 1);
      expect(today.myColor, EselPaint.lilac);
      expect(lockIcons(), findsNothing);
      stand.select(EselPaint.camel);
      await tester.pump();
      expect(find.text('올리면 함께 펼쳐집니다'), findsNothing);
      expect(
        stand.tiles.map((v) => v.masthead),
        containsAll(['mara', 'selin', 'noor', 'leo']),
      );
    });

    test('자정이 지나면 어제 방은 열리고 새 날짜 후보 방은 다시 잠긴다', () async {
      await today.publish(draft(EselPaint.camel));
      expect(today.hasPublishedToday, isTrue);
      final yesterday = today.today;

      clock.set(DateTime.utc(2026, 9, 6, 15, 1)); // 서울 09-07 00:01
      today.refresh();
      expect(today.today, const ServiceDate(2026, 9, 7));
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

    testWidgets('후보가 아닌 색은 올리기 전에도 열려 있다', (tester) async {
      final stand = StandController(StandMockSource(library: () => library));
      await pumpStand(tester, stand);
      final open = EselPaint.values.firstWhere(
        (c) => !today.candidates.contains(c),
      );
      stand.select(open);
      await tester.pump();
      final shelf = stand.shelf!;
      expect(shelf.isPreview, isFalse);
      expect(shelf.hiddenCount, 0);
      expect(find.text('올리면 함께 펼쳐집니다'), findsNothing);
    });

    testWidgets('전체 칸에는 잠긴 후보 색 표지가 꽂히지 않는다', (tester) async {
      final stand = StandController(StandMockSource(library: () => library));
      await pumpStand(tester, stand);
      final shelf = stand.shelf!;
      expect(
        shelf.items.where((item) => today.candidates.contains(item.color)),
        isEmpty,
      );
      expect(find.text('leo'), findsNothing);
    });

    testWidgets('미성년자는 잠금이 없다', (tester) async {
      today.bindUser(ownerId: 'reader-a', isMinor: true);
      final stand = StandController(StandMockSource(library: () => library));
      await pumpStand(tester, stand);
      expect(lockIcons(), findsNothing);
      stand.select(today.candidates.first);
      await tester.pump();
      expect(stand.shelf!.isPreview, isFalse);
    });
  });
}
