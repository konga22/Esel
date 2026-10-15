import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/design/tokens.g.dart';
import 'package:esel/features/drafts/data/local_library.dart';
import 'package:esel/features/drafts/presentation/cover_editor_screen.dart';
import 'package:esel/features/drafts/presentation/local_calendar_screen.dart';
import 'package:esel/features/media/domain/models/face_layout_mode.dart';
import 'package:esel/features/settings/presentation/device_preferences.dart';
import 'package:esel/features/settings/presentation/screens/device_settings_screen.dart';
import 'package:esel/features/publishing/presentation/screens/publish_screen.dart';
import 'package:esel/features/publishing/presentation/controllers/publishing_controller.dart';

void main() {
  late LocalLibrary library;
  setUp(() {
    library = LocalLibrary(
      Directory.systemTemp.createTempSync('esel-ui-test-'),
    );
  });
  tearDown(() {
    library.directory!.deleteSync(recursive: true);
    library.dispose();
  });
  testWidgets(
    'edit, undo, four face modes and close cancellation work offline',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: CoverEditorScreen(library: library)),
      );
      final name = find.byKey(const Key('draft-masthead'));
      await tester.scrollUntilVisible(
        name,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(name, 'mycover');
      await tester.pump();
      expect(tester.widget<TextField>(name).controller!.text, 'mycover');
      await tester.tap(find.byTooltip('이전 편집으로 되돌리기'));
      await tester.pump();
      expect(tester.widget<TextField>(name).controller!.text, '');
      for (final mode in [
        ('물감 한 획', FaceLayoutMode.paintStroke),
        ('제호 뒤로', FaceLayoutMode.behindLogo),
        ('목 아래', FaceLayoutMode.belowNeck),
        ('그대로', FaceLayoutMode.original),
      ]) {
        await tester.scrollUntilVisible(
          find.text(mode.$1),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text(mode.$1));
        await tester.pump();
        expect(
          tester
              .widget<ChoiceChip>(
                find.ancestor(
                  of: find.text(mode.$1),
                  matching: find.byType(ChoiceChip),
                ),
              )
              .selected,
          isTrue,
        );
      }
      await tester.tap(find.byTooltip('편집 닫기'));
      await tester.pumpAndSettle();
      expect(find.text('계속 편집'), findsOneWidget);
      await tester.tap(find.text('계속 편집'));
      await tester.pumpAndSettle();
      expect(find.byType(CoverEditorScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'saving without a photo explains missing input and creates no draft',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: CoverEditorScreen(library: library)),
      );
      await tester.scrollUntilVisible(
        find.text('초안 저장'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('초안 저장'));
      await tester.pumpAndSettle();
      expect(find.text('사진을 먼저 골라 주세요.'), findsOneWidget);
      expect(library.drafts, isEmpty);
    },
  );
  testWidgets(
    'calendar navigates across year boundaries and resets current month',
    (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(
        MaterialApp(home: LocalCalendarScreen(library: library)),
      );
      for (var i = 0; i < 13; i++) {
        await tester.tap(find.byTooltip('이전 달'));
        await tester.pump();
      }
      final target = DateTime(now.year, now.month - 13);
      expect(find.text('${target.year}년 ${target.month}월'), findsOneWidget);
      await tester.ensureVisible(find.text('이번 달로 돌아가기'));
      await tester.tap(find.text('이번 달로 돌아가기'));
      await tester.pump();
      expect(find.text('${now.year}년 ${now.month}월'), findsOneWidget);
    },
  );
  testWidgets(
    'settings toggle persists and applies accessibility preferences',
    (tester) async {
      await tester.runAsync(library.load);
      await tester.pumpWidget(
        MaterialApp(
          home: DevicePreferences(
            library: library,
            child: DeviceSettingsScreen(library: library),
          ),
        ),
      );
      await tester.runAsync(() async {
        await tester.tap(find.text('큰 글씨'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(library.largeText, isTrue);
      expect(
        MediaQuery.textScalerOf(
          tester.element(find.byType(DeviceSettingsScreen)),
        ).scale(10),
        12,
      );
      final reopened = LocalLibrary(library.directory!);
      await tester.runAsync(reopened.load);
      expect(reopened.largeText, isTrue);
      reopened.dispose();
      await tester.tap(find.text('초안 보관 안내'));
      await tester.pumpAndSettle();
      expect(find.text('이 기기에 보관돼요'), findsOneWidget);
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(find.text('이 기기에 보관돼요'), findsNothing);
    },
  );
  testWidgets(
    'already published screen returns through Android back without exiting',
    (tester) async {
      var closed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: PublishScreen(
            controller: PublishingController(),
            library: library,
            masthead: 'selin',
            ownerId: 'owner',
            currentIssueCount: 1,
            hasPublishedToday: true,
            candidates: const [
              EselPaint.camel,
              EselPaint.lilac,
              EselPaint.olive,
            ],
            onPublishSuccess: (_) {},
            onClose: () => closed = true,
          ),
        ),
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(closed, isTrue);
    },
  );
}
