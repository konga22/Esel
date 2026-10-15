import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/app/app.dart';
import 'package:esel/app/bootstrap/app_bootstrap.dart';
import 'package:esel/app/dependencies/service_locator.dart';
import 'package:esel/core/config/app_config.dart';
import 'package:esel/core/time/service_clock.dart';
import 'package:esel/core/time/service_date.dart';
import 'package:esel/features/drafts/data/local_library.dart';
import 'package:esel/features/drafts/domain/cover_draft.dart';

void main() {
  late Directory directory;
  // 서울 2026-10-15 23:30.
  final clock = ManualServiceClock(DateTime.utc(2026, 10, 15, 14, 30));

  setUpAll(() async {
    AppConfig.current = const AppConfig(apiMode: ApiMode.mock);
    directory = Directory.systemTemp.createTempSync('esel-day-boundary-');
    await AppBootstrap.setup(
      localLibrary: LocalLibrary(directory),
      clock: clock,
    );
    await ServiceLocator().authController.loginWithEmail(
      'midnight@esel.local',
      'eseldemo2026',
    );
  });
  tearDownAll(() => directory.deleteSync(recursive: true));

  testWidgets('앱을 다시 열면 자정이 지났는지 다시 계산한다(P04)', (tester) async {
    tester.view.physicalSize = const Size(480, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final today = ServiceLocator().todayController;

    await tester.pumpWidget(const EselApp());
    await tester.pumpAndSettle();
    expect(today.isSignedIn, isTrue);

    await tester.runAsync(
      () => today.publish(
        CoverDraft(
          id: 'midnight-1',
          photoPath: 'photo.png',
          masthead: 'midnight',
          color: today.candidates.first,
          faceConfirmed: true,
          updatedAt: clock.now(),
        ),
      ),
    );
    await tester.pump();
    expect(today.hasPublishedToday, isTrue);

    // 앱이 백그라운드에 있는 사이 서울 자정을 넘긴다.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    clock.set(DateTime.utc(2026, 10, 15, 16)); // 서울 10-16 01:00
    expect(today.hasPublishedToday, isTrue, reason: '아직 다시 계산하지 않음');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(today.today, const ServiceDate(2026, 10, 16));
    expect(today.hasPublishedToday, isFalse);
    expect(today.issueCount, 1);
  });
}
