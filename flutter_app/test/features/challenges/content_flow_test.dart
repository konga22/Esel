import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/app/app.dart';
import 'package:esel/app/bootstrap/app_bootstrap.dart';
import 'package:esel/app/dependencies/service_locator.dart';
import 'package:esel/core/config/app_config.dart';
import 'package:esel/core/time/service_clock.dart';
import 'package:esel/features/auth/data/sources/mock_account_store.dart';
import 'package:esel/features/drafts/data/local_library.dart';
import 'package:esel/features/drafts/domain/cover_draft.dart';
import 'package:esel/features/challenges/domain/challenge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final clock = ManualServiceClock(DateTime.utc(2026, 10, 16, 3));
  final lib = LocalLibrary.inMemory();
  setUpAll(() async {
    AppConfig.current = const AppConfig(apiMode: ApiMode.mock);
    await AppBootstrap.setup(
      localLibrary: lib,
      clock: clock,
      accountVault: InMemoryMockAccountVault(),
    );
  });
  testWidgets(
    'login → past issue → today issue → restyle comparison, logout separates accounts',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final sl = ServiceLocator();
      await tester.runAsync(
        () => sl.authController.signupWithEmail(
          'content@esel.local',
          'eseldemo2026',
          'content',
        ),
      );
      await tester.pumpWidget(const EselApp());
      await tester.pumpAndSettle();
      final owner = sl.authController.currentSession!.userId;
      final photo = (await tester.runAsync(
        () => lib.importPhotoBytes(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
          ),
        ),
      ))!;
      CoverDraft draft(String id) => CoverDraft(
        id: id,
        ownerId: owner,
        photoPath: photo,
        masthead: 'content',
        caption: id,
        color: sl.todayController.candidates.first,
        faceConfirmed: true,
        updatedAt: clock.now(),
      );
      await tester.runAsync(() => sl.todayController.publish(draft('past')));
      clock.advance(const Duration(days: 1));
      sl.todayController.refresh();
      await tester.runAsync(() => sl.todayController.publish(draft('today')));
      await tester.pumpAndSettle();
      // 이번 주 주제는 마이페이지에서 빠지고 홈 피드 카드로 왔다(10-18).
      await tester.tap(find.bySemanticsLabel('스케치북'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('홈'));
      await tester.pumpAndSettle();
      final entry = find.byKey(const ValueKey('feed-feature-이번 주 주제'));
      await tester.scrollUntilVisible(
        entry,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      // 화면 아래 끝이면 캡슐에 가리므로 카드를 위쪽으로 올려서 누른다.
      Scrollable.ensureVisible(tester.element(entry), alignment: 0.2);
      await tester.pumpAndSettle();
      await tester.tap(entry);
      await tester.pumpAndSettle();
      final begin = find.text('지난 표지 골라 참여하기');
      await tester.scrollUntilVisible(begin, 180);
      await tester.tap(begin);
      await tester.pumpAndSettle();
      expect(find.text('같은 옷이 있는 내 지난 표지'), findsOneWidget);
      expect(find.text('2026-10-16 · Nº 1'), findsOneWidget);
      expect(find.text('2026-10-17 · Nº 2'), findsNothing);
      await tester.runAsync(() async {
        await tester.tap(find.text('2026-10-16 · Nº 1'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(lib.issuesFor(owner).length, 2);
      expect(lib.issuesFor(owner).first.previousIssueId, 'past');
      expect(
        lib.issuesFor(owner).first.challengeId,
        StyleChallenge.forWeek(clock.today).last.id,
      );
      await tester.scrollUntilVisible(
        find.textContaining('지난 착장 → 오늘 착장'),
        200,
      );
      expect(find.textContaining('지난 착장 → 오늘 착장'), findsOneWidget);
      await tester.runAsync(sl.authController.logout);
      await tester.pumpAndSettle();
      expect(find.text('내 참여 표지'), findsNothing);
      await tester.runAsync(
        () => sl.authController.signupWithEmail(
          'other@esel.local',
          'eseldemo2026',
          'other',
        ),
      );
      await tester.pumpAndSettle();
      expect(sl.todayController.issues, isEmpty);
      expect(
        await sl.challengeSource.mine(sl.authController.currentSession!.userId),
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
}
