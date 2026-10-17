import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/time/service_clock.dart';
import 'package:esel/features/collections/data/collection_source.dart';
import 'package:esel/features/collections/domain/cover_collection.dart';
import 'package:esel/features/collections/presentation/collection_screen.dart';
import 'package:esel/features/drafts/data/local_library.dart';
import 'package:esel/features/drafts/domain/cover_draft.dart';
import 'package:esel/features/stand/domain/rules/same_color_rule.dart';
import 'package:esel/core/design/tokens.g.dart';
import 'package:esel/features/challenges/domain/challenge.dart';
import 'package:esel/features/challenges/data/challenge_source.dart';
import 'package:esel/features/challenges/presentation/challenge_screen.dart';
import 'collections_test.dart' show today, viewer, draft;

class RetryCollectionSource extends LocalCollectionSource {
  bool fail = true;
  RetryCollectionSource(super.library);
  @override
  Future<List<CoverDraft>> available(
    String owner,
    SameColorViewer viewer,
    CollectionPeriod period,
  ) async {
    if (fail) {
      fail = false;
      throw StateError('test failure');
    }
    return super.available(owner, viewer, period);
  }
}

void main() {
  final clock = ManualServiceClock(DateTime.utc(2026, 10, 18, 3));
  testWidgets('주간 화면: 다른 로컬 계정의 공개 참여 표지를 보고 잠기면 숨긴다', (tester) async {
    tester.view.physicalSize = const Size(480, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final lib = LocalLibrary.inMemory();
    final topic = StyleChallenge.forWeek(today).first;
    await lib.publish(
      draft('bob-weekly', owner: 'bob', color: EselPaint.camel),
      'bob',
      on: today,
    );
    await lib.attachChallenge('bob-weekly', 'bob', topic, today);
    final source = LocalChallengeSource(() => lib);
    Widget screen(bool published) => MaterialApp(
      home: ChallengeScreen(
        ownerId: 'alice',
        library: lib,
        source: source,
        clock: clock,
        viewer: viewer(published: published),
        onBack: () {},
        onBegin: (_, _) async {},
      ),
    );
    await tester.pumpWidget(screen(true));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('주간 드레스코드 참여 표지 보기'), 200);
    await tester.tap(find.text('주간 드레스코드 참여 표지 보기'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('bob · 2026-10-18 · Nº 1'), 200);
    expect(find.text('bob · 2026-10-18 · Nº 1'), findsOneWidget);
    await tester.pumpWidget(screen(false));
    await tester.pumpAndSettle();
    expect(find.text('bob · 2026-10-18 · Nº 1'), findsNothing);
  });
  testWidgets('특집 화면: 기간 선택·직접 선정·이유·해제·뒤로가기', (tester) async {
    tester.view.physicalSize = const Size(480, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final lib = LocalLibrary.inMemory();
    await lib.publish(draft('own'), 'alice', on: today);
    final source = LocalCollectionSource(() => lib);
    var back = false;
    await tester.pumpWidget(
      MaterialApp(
        home: CollectionScreen(
          ownerId: 'alice',
          source: source,
          library: lib,
          viewer: viewer(published: true),
          clock: clock,
          onBack: () => back = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('일간 표지 특집'), findsOneWidget);
    await tester.tap(find.text('공개 표지 골라 특집 편집'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('이 표지를 특집에 담기'), 250);
    await tester.tap(find.text('이 표지를 특집에 담기'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('collection-reason')),
      '차분한 색 조합을 소개해요',
    );
    await tester.ensureVisible(find.text('특집에 저장'));
    await tester.tap(find.text('특집에 저장'));
    await tester.pumpAndSettle();
    expect(
      (await source.selected(
        'alice',
        viewer(),
        CollectionPeriod.at(CollectionUnit.day, today),
      )).single.reason,
      '차분한 색 조합을 소개해요',
    );
    await tester.scrollUntilVisible(find.text('특집 보기로 돌아가기'), -250);
    await tester.tap(find.text('특집 보기로 돌아가기'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('선정 이유 · 차분한 색 조합을 소개해요'), 250);
    await tester.scrollUntilVisible(find.text('특집에서 빼기 · 발행본 유지'), 200);
    await tester.tap(find.text('특집에서 빼기 · 발행본 유지'));
    await tester.pumpAndSettle();
    expect(
      await source.selected(
        'alice',
        viewer(),
        CollectionPeriod.at(CollectionUnit.day, today),
      ),
      isEmpty,
    );
    expect(lib.issuesFor('alice'), hasLength(1));
    await tester.scrollUntilVisible(find.text('주간'), -250);
    await tester.tap(find.text('주간'));
    await tester.pumpAndSettle();
    expect(find.text('주간 표지 특집'), findsOneWidget);
    await tester.tap(find.byTooltip('뒤로'));
    expect(back, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('작은 화면·글자 200%: 실패·재시도·빈 화면과 미래 기간 차단', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final lib = LocalLibrary.inMemory();
    final source = RetryCollectionSource(() => lib);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: CollectionScreen(
          ownerId: 'alice',
          source: source,
          library: lib,
          viewer: viewer(),
          clock: clock,
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('다시 불러오기'), 250);
    await tester.tap(find.text('다시 불러오기'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.textContaining('아직 엮은 표지가 없어요.'), 200);
    expect(find.textContaining('아직 엮은 표지가 없어요.'), findsOneWidget);
    await tester.scrollUntilVisible(find.byTooltip('다음 기간'), -200);
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.chevron_right),
          )
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}
