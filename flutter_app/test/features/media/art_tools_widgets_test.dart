import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/time/service_date.dart';
import 'package:esel/features/drafts/data/local_library.dart';
import 'package:esel/features/drafts/domain/cover_draft.dart';
import 'package:esel/features/garments/presentation/garment_editor.dart';
import 'package:esel/features/issue/data/demo_issue_catalog.dart';
import 'package:esel/features/issue/presentation/canvas_photo.dart';
import 'package:esel/features/issue/presentation/widgets/issue_bottom_sheet.dart';
import 'package:esel/features/magazine/data/sources/magazine_mock_source.dart';
import 'package:esel/features/magazine/presentation/controllers/magazine_controller.dart';
import 'package:esel/features/magazine/presentation/screens/shelf_screen.dart';
import 'package:esel/features/reactions/presentation/controllers/reactions_controller.dart';
import 'package:esel/features/stand/data/sources/stand_mock_source.dart';
import 'package:esel/features/stand/presentation/controllers/stand_controller.dart';
import 'package:esel/features/stand/presentation/screens/stand_screen.dart';
import 'package:esel/features/stand/domain/rules/same_color_rule.dart';

void main() {
  setUpAll(() async {
    for (final font in {
      'Cormorant Garamond': 'CormorantGaramond-Regular.ttf',
      'Nanum Myeongjo': 'NanumMyeongjo-Regular.ttf',
      'Instrument Sans': 'InstrumentSans-Variable.ttf',
      'Ahem': 'NanumMyeongjo-Regular.ttf',
      'Noto Sans KR': 'NanumMyeongjo-Regular.ttf',
    }.entries) {
      await (FontLoader(
        font.key,
      )..addFont(rootBundle.load('assets/fonts/${font.value}'))).load();
    }
  });
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> capture(WidgetTester tester, String name) async {
    final out = Platform.environment['ESEL_WIDGET_CAPTURES'];
    if (out == null) return;
    await tester.runAsync(() async {
      final context = tester.element(find.byKey(const ValueKey('capture')));
      for (final widget in tester.widgetList<Image>(find.byType(Image))) {
        await precacheImage(widget.image, context);
      }
    });
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final render = tester.firstRenderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('capture')),
      );
      final image = await render.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      await File('$out/$name.png').writeAsBytes(data!.buffer.asUint8List());
    });
  }

  testWidgets(
    'DEV-12 and DEV-13 common phone screens: recommendation, subscription, vertical photographs',
    (tester) async {
      phone(tester);
      const viewer = SameColorViewer.reader(ServiceDate(2026, 10, 18));
      final stand = StandController(StandMockSource());
      addTearDown(stand.dispose);
      String? opened;
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: const ValueKey('capture'),
            child: StandScreen(
              controller: stand,
              viewer: viewer,
              onSelectCover: (v) => opened = v.ownerId,
              onMakeTodayIssue: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('전체'), findsNothing);
      expect(find.byType(CanvasPhoto), findsWidgets);
      await capture(tester, 'palette');
      await tester.tap(find.byKey(const ValueKey('palette-fan')));
      await tester.pumpAndSettle();
      await capture(tester, 'palette-fan');
      await tester.tap(find.byKey(const ValueKey('palette-fan')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CanvasPhoto).first);
      expect(opened, isNotNull);
      stand.subscriptions = {opened!};
      stand.selectTab(PaletteTab.subscriptions);
      await tester.pumpAndSettle();
      expect(stand.tiles.every((v) => v.ownerId == opened), isTrue);
      final magazine = MagazineController(MagazineMockSource());
      addTearDown(magazine.dispose);
      final reactions = ReactionsController();
      addTearDown(reactions.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: const ValueKey('capture'),
            child: ShelfScreen(
              ownerId: opened!,
              viewer: viewer,
              controller: magazine,
              reactionsController: reactions,
              onSelectIssue: (_, _) {},
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsNothing);
      expect(find.byType(CanvasPhoto), findsWidgets);
      await tester.tap(find.text('구독'));
      await tester.pumpAndSettle();
      expect(reactions.isSubscribed(opened!), isTrue);
      await capture(tester, 'sketchbook');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('DEV-24 edit clothing, place tag and open matching detail row', (
    tester,
  ) async {
    phone(tester);
    final library = LocalLibrary.inMemory();
    addTearDown(library.dispose);
    var draft = CoverDraft(
      id: 'wear',
      ownerId: 'owner',
      photoPath: DemoIssueCatalog.issuesOn(
        const ServiceDate(2026, 10, 18),
      ).first.photo,
      masthead: 'artist',
      faceConfirmed: true,
      updatedAt: DateTime.utc(2026, 10, 18),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, update) => SingleChildScrollView(
              child: GarmentEditor(
                draft: draft,
                library: library,
                onChanged: (v) =>
                    update(() => draft = draft.copyWith(garments: v)),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('착용 정보 더하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '셔츠'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '내 파란 코트');
    await tester.tap(find.text('오래 입음'));
    await tester.tap(find.byType(Switch));
    await tester.scrollUntilVisible(
      find.byKey(const Key('garment-position-photo')),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('garment-position-photo')));
    await tester.scrollUntilVisible(
      find.text('더하기'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('더하기'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    expect(draft.garments.single.name, '내 파란 코트');
    expect(draft.garments.single.kind, '셔츠');
    expect(draft.garments.single.todayColor, isTrue);
    expect(draft.garments.single.x, isNotNull);
    await library.save(draft);
    final issue = DemoIssueCatalog.fromLocal(
      draft.copyWith(issueNumber: 1, publishedOn: '2026-10-18'),
    );
    final rc = ReactionsController();
    addTearDown(rc.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: const ValueKey('capture'),
            child: IssueBottomSheet(
              issue: issue,
              isOwner: true,
              readerMasthead: 'artist',
              reactionsController: rc,
              onOpenAuthorShelf: () {},
              onShare: () {},
              onReport: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final tag = find.byKey(ValueKey('garment-tag-${draft.garments.single.id}'));
    await tester.ensureVisible(tag);
    await tester.tap(tag);
    await tester.pumpAndSettle();
    expect(
      tester.widgetList<ListTile>(find.byType(ListTile)).any((v) => v.selected),
      isTrue,
    );
    await capture(tester, 'garment-detail');
    expect(tester.takeException(), isNull);
  });
}
