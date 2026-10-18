import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/app/app.dart';
import 'package:esel/app/bootstrap/app_bootstrap.dart';
import 'package:esel/app/dependencies/service_locator.dart';
import 'package:esel/core/config/app_config.dart';
import 'package:esel/core/errors/failures.dart';
import 'package:esel/core/storage/session_storage.dart';
import 'package:esel/features/auth/domain/models/auth_session.dart';
import 'package:esel/features/drafts/data/local_library.dart';
import '../features/server/core_api_widgets_test.dart' show ScreenHttp;
import '../features/server/core_api_test.dart' show todayDto;

void main() {
  testWidgets(
    'unavailable device storage does not prevent server app startup and cannot be overwritten',
    (tester) async {
      tester.view.physicalSize = const Size(480, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      AppConfig.current = const AppConfig(apiMode: ApiMode.server);
      final http = ScreenHttp((_, path, _) async {
        if (path == '/today') return todayDto();
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
      await AppBootstrap.setup(
        localLibrary: LocalLibrary.unavailable(),
        httpClient: http,
        sessionStorage: InMemorySessionStorage(),
      );
      ServiceLocator().authController.updateSession(
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
      expect(find.byKey(const Key('menu-capsule')), findsOneWidget);
      expect(find.textContaining('기기 보관함을 열지 못했어요'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('만들기'));
      await tester.pumpAndSettle();
      expect(find.textContaining('기기 보관함을 다시 읽은 뒤 편집해 주세요'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
