import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/time/service_clock.dart';
import 'package:esel/features/challenges/data/challenge_source.dart';
import 'package:esel/features/challenges/domain/challenge.dart';
import 'package:esel/features/challenges/presentation/challenge_screen.dart';
import 'package:esel/features/drafts/data/local_library.dart';
import 'package:esel/features/drafts/domain/cover_draft.dart';
import 'package:esel/features/drafts/presentation/cover_editor_screen.dart';

class RetrySource extends LocalChallengeSource {
  bool fail = true;
  RetrySource(super.library);
  @override
  Future<List<CoverDraft>> mine(String ownerId) {
    if (fail) return Future.error(StateError('storage unavailable'));
    return super.mine(ownerId);
  }
}

void main() {
  final clock = ManualServiceClock(DateTime.utc(2026, 10, 17, 3));
  testWidgets(
    'small screen, loading failure, retry and newcomer restyle guidance',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final lib = LocalLibrary.inMemory();
      final source = RetrySource(() => lib);
      var began = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(2),
            ),
            child: ChallengeScreen(
              ownerId: 'a',
              library: lib,
              source: source,
              clock: clock,
              onBack: () {},
              onBegin: (_, _) async => began++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final retry = find.text('다시 불러오기');
      await tester.scrollUntilVisible(retry, 300);
      source.fail = false;
      await tester.tap(retry);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.textContaining('첫 참여를 기다리고'), 300);
      expect(find.textContaining('첫 참여를 기다리고'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('지난 표지 골라 참여하기'), -200);
      await tester.tap(find.text('지난 표지 골라 참여하기'));
      await tester.pumpAndSettle();
      expect(find.textContaining('지난 날짜의 올린 표지가 아직 없어요.'), findsOneWidget);
      expect(began, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'participation enters existing editor callback and back stays explicit',
    (tester) async {
      final lib = LocalLibrary.inMemory();
      StyleChallenge? selected;
      var back = false;
      await tester.pumpWidget(
        MaterialApp(
          home: ChallengeScreen(
            ownerId: 'a',
            library: lib,
            source: LocalChallengeSource(() => lib),
            clock: clock,
            onBack: () => back = true,
            onBegin: (c, _) async => selected = c,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('이번 주 주제에 참여하기'));
      await tester.pumpAndSettle();
      expect(selected?.id, StyleChallenge.forWeek(clock.today).first.id);
      await tester.tap(find.byTooltip('이전 화면'));
      expect(back, isTrue);
      expect(
        lib.drafts,
        isEmpty,
        reason: 'entering does not manufacture an issue',
      );
    },
  );
  testWidgets('missing photo blocks publication and keeps the saved draft', (
    tester,
  ) async {
    final lib = LocalLibrary.inMemory();
    final draft = CoverDraft(
      id: 'missing',
      ownerId: 'a',
      photoPath: 'memory:missing',
      masthead: 'look',
      faceConfirmed: true,
      updatedAt: clock.now(),
    );
    await tester.runAsync(() => lib.save(draft));
    var published = false;
    await tester.pumpWidget(
      MaterialApp(
        home: CoverEditorScreen(
          library: lib,
          initial: draft,
          onPublish: (_) async => published = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('오늘의 캔버스 올리기'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('오늘의 캔버스 올리기'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('오늘의 캔버스 올리기'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pumpAndSettle();
    expect(find.text('사진 파일을 찾을 수 없어요. 앨범에서 다시 골라 주세요.'), findsOneWidget);
    expect(published, isFalse);
    expect(lib.drafts.single.id, draft.id);
  });
}
