import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/app/app.dart';
import 'package:esel/app/bootstrap/app_bootstrap.dart';
import 'package:esel/app/dependencies/service_locator.dart';
import 'package:esel/core/config/app_config.dart';
import 'package:esel/core/errors/failures.dart';
import 'package:esel/core/storage/session_storage.dart';
import 'package:esel/core/time/service_clock.dart';
import 'package:esel/features/auth/domain/models/auth_session.dart';
import 'package:esel/features/drafts/data/local_library.dart';
import 'package:esel/features/drafts/domain/cover_draft.dart';
import 'package:esel/features/drafts/presentation/cover_editor_screen.dart';
import 'package:esel/features/garments/domain/garment.dart';
import 'package:esel/features/media/presentation/cover_preview.dart';
import 'package:esel/features/settings/presentation/screens/device_settings_screen.dart';
import 'package:esel/features/drafts/presentation/draft_library_screen.dart';
import '../features/server/core_api_widgets_test.dart' show ScreenHttp;
import '../features/server/core_api_test.dart' show todayDto;

void main() {
  testWidgets(
    'server editor survives app resume, refresh errors and day changes with draft intact',
    (tester) async {
      tester.view.physicalSize = const Size(480, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Completer<Map<String, dynamic>>? gate;
      var serviceDate = '2026-10-18';
      final http = ScreenHttp((_, path, _) async {
        if (path == '/today') {
          return gate == null
              ? {...todayDto(), 'serviceDate': serviceDate}
              : gate.future;
        }
        if (path == '/me/magazine') {
          return {
            'masthead': 'artist',
            'issueCount': 0,
            'pastIssues': [],
            'todayIssue': null,
            'nextCursor': null,
          };
        }
        throw const NotImplementedFailure('준비 중이에요.');
      });
      final library = LocalLibrary.inMemory();
      await library.save(
        CoverDraft(
          id: 'draft',
          ownerId: 'a',
          photoPath: 'assets/demo/blue-city.jpg',
          masthead: 'artist',
          caption: 'keep caption',
          faceConfirmed: true,
          updatedAt: DateTime.utc(2026, 10, 18),
          garments: const [Garment(id: 'coat', kind: '코트', name: 'keep coat')],
        ),
      );
      AppConfig.current = const AppConfig(apiMode: ApiMode.server);
      final clock = ManualServiceClock(DateTime.utc(2026, 10, 18, 3));
      await AppBootstrap.setup(
        localLibrary: library,
        clock: clock,
        httpClient: http,
        sessionStorage: InMemorySessionStorage(),
      );
      final sl = ServiceLocator();
      sl.authController.updateSession(
        const AuthSession(
          userId: 'a',
          email: 'a@esel.local',
          masthead: 'artist',
          hasPublishedToday: false,
          issueCount: 0,
          accessToken: 'test',
          refreshToken: 'test',
        ),
      );
      await tester.pumpWidget(const EselApp());
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('만들기'));
      await tester.pumpAndSettle();
      final editor = find.byType(CoverEditorScreen),
          state = tester.state(editor);
      final caption = find.byKey(const Key('draft-caption'));
      await tester.ensureVisible(caption);
      await tester.enterText(caption, 'edited caption');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      gate = Completer();
      for (final phase in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(phase);
      }
      await tester.pump();
      expect(sl.todayController.loading, isTrue);
      expect(tester.state(editor), same(state));
      expect(
        tester.widget<TextField>(caption).controller!.text,
        'edited caption',
      );
      gate.completeError(const NetworkFailure('일시적 연결 오류'));
      gate = null;
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('today-refresh-error')), findsOneWidget);
      expect(tester.state(editor), same(state));
      tester
          .state<ScrollableState>(
            find
                .descendant(of: editor, matching: find.byType(Scrollable))
                .first,
          )
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      final preview = tester.widget<CoverPreview>(
        find.byType(CoverPreview).first,
      );
      expect(preview.draft.photoPath, 'assets/demo/blue-city.jpg');
      expect(preview.draft.garments.single.id, 'coat');
      expect(preview.draft.caption, 'edited caption');
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('today-refresh-error')),
          matching: find.text('다시 시도'),
        ),
      );
      await tester.pumpAndSettle();
      expect(sl.todayController.error, isNull);
      expect(tester.state(editor), same(state));
      serviceDate = '2026-10-19';
      clock.set(DateTime.utc(2026, 10, 18, 15, 1));
      sl.todayController.refresh();
      await tester.pumpAndSettle();
      expect(sl.todayController.today.key, '2026-10-19');
      expect(tester.state(editor), same(state));
      await tester.tap(find.byTooltip('편집 닫기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('저장 후 닫기'));
      await tester.pumpAndSettle();
      expect(library.drafts.single.caption, 'edited caption');
      expect(find.text('이번 주 주제'), findsNothing);
      expect(find.text('전시'), findsNothing);
      await tester.tap(find.bySemanticsLabel('스케치북'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('my-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('설정과 계정'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('기기 접근성 설정'));
      await tester.pumpAndSettle();
      expect(find.byType(DeviceSettingsScreen), findsOneWidget);
      await tester.tap(find.widgetWithText(SwitchListTile, '움직임 줄이기'));
      await tester.pumpAndSettle();
      expect(library.reduceMotion, isTrue);
      Navigator.of(tester.element(find.byType(DeviceSettingsScreen))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('기기 초안 · 초안 달력'));
      await tester.pumpAndSettle();
      expect(find.byType(DraftLibraryScreen), findsOneWidget);
      expect(find.textContaining('edited caption'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
