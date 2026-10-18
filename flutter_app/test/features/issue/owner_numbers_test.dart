import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/app/app.dart';
import 'package:esel/app/bootstrap/app_bootstrap.dart';
import 'package:esel/app/dependencies/service_locator.dart';
import 'package:esel/core/config/app_config.dart';
import 'package:esel/core/design/tokens.g.dart';
import 'package:esel/core/time/service_clock.dart';
import 'package:esel/features/auth/data/sources/mock_account_store.dart';
import 'package:esel/features/drafts/data/local_library.dart';
import 'package:esel/features/drafts/domain/cover_draft.dart';
import 'package:esel/features/issue/presentation/widgets/issue_bottom_sheet.dart';
import 'package:esel/features/magazine/domain/rules/privacy_rule.dart';

void main() {
  test('DEV-02 P18 본인 판정은 계정 id로, 로그인 전이나 빈 id는 남', () {
    expect(
      PrivacyRule.shouldExposeReactionCounts(
        viewerUserId: 'user_1',
        ownerUserId: 'user_1',
      ),
      isTrue,
    );
    expect(
      PrivacyRule.shouldExposeReactionCounts(
        viewerUserId: 'mock_apple',
        ownerUserId: 'demo_dana',
      ),
      isFalse,
    );
    expect(
      PrivacyRule.shouldExposeReactionCounts(
        viewerUserId: null,
        ownerUserId: 'demo_dana',
      ),
      isFalse,
    );
    expect(
      PrivacyRule.shouldExposeReactionCounts(viewerUserId: '', ownerUserId: ''),
      isFalse,
    );
  });

  testWidgets('DEV-11 P18 내 표지에만 숫자, 남의 표지에는 숫자가 없다', (tester) async {
    tester.view.physicalSize = const Size(480, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    AppConfig.current = const AppConfig(apiMode: ApiMode.mock);
    final clock = ManualServiceClock(DateTime.utc(2026, 9, 6, 3));
    await AppBootstrap.setup(
      localLibrary: LocalLibrary.inMemory(),
      clock: clock,
      accountVault: InMemoryMockAccountVault(),
    );
    final sl = ServiceLocator();
    // 예시 인물 dana가 아니라 내 계정. Apple 시연도 dana가 되지 않는다.
    await tester.runAsync(
      () => sl.authController.signupWithEmail(
        'own@esel.local',
        'esel1234',
        'ownmag',
      ),
    );
    final me = sl.authController.currentSession!;
    await tester.pumpWidget(const EselApp());
    await tester.pumpAndSettle();
    await sl.todayController.publish(
      CoverDraft(
        id: 'own-1',
        photoPath: 'own.png',
        masthead: 'ownmag',
        color: EselPaint.camel,
        faceConfirmed: true,
        updatedAt: clock.now(),
      ),
    );

    await tester.pump();
    await tester.tap(find.bySemanticsLabel('스케치북'));
    await tester.pumpAndSettle();
    // 마이페이지 격자 → 세로 목록 → 반응 보기.
    await tester.tap(find.byKey(const ValueKey('my-canvas-own-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('내 캔버스의 반응 보기'));
    await tester.pumpAndSettle();
    expect(find.byType(IssueBottomSheet), findsOneWidget);
    expect(
      tester
          .widget<IssueBottomSheet>(find.byType(IssueBottomSheet))
          .issue
          .ownerId,
      me.userId,
    );
    expect(find.textContaining('나에게만 보여요'), findsOneWidget);
    Navigator.of(tester.element(find.byType(IssueBottomSheet))).pop();
    await tester.pumpAndSettle();

    // 남의 표지(이름이 같은 사람이 있어도 id로 가른다). 내 스케치북의 캡슐 첫 칸은 홈이라
    // 홈을 거쳐 팔레트로 간다.
    await tester.tap(find.bySemanticsLabel('홈'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('팔레트'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('palette-cover-selin-2026-09-06')),
      180,
    );
    await tester.tap(
      find.byKey(const ValueKey('palette-cover-selin-2026-09-06')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('자세히 보기').first);
    await tester.pumpAndSettle();
    expect(find.byType(IssueBottomSheet), findsOneWidget);
    expect(find.textContaining('나에게만 보여요'), findsNothing);
    expect(find.text('좋아요'), findsNothing);
    semantics.dispose();
  });
}
