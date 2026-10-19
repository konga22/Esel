import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/errors/failures.dart';
import 'package:esel/core/design/tokens.g.dart';
import 'package:esel/core/time/service_clock.dart';
import 'package:esel/core/time/service_date.dart';
import 'package:esel/features/today/data/sources/today_remote_source.dart';
import 'package:esel/features/today/presentation/controllers/today_controller.dart';
import 'package:esel/features/magazine/data/sources/magazine_remote_source.dart';
import 'package:esel/features/magazine/presentation/controllers/magazine_controller.dart';
import 'package:esel/features/magazine/presentation/screens/shelf_screen.dart';
import 'package:esel/features/issue/data/sources/issue_remote_source.dart';
import 'package:esel/features/reactions/presentation/controllers/reactions_controller.dart';
import 'package:esel/features/stand/domain/rules/same_color_rule.dart';
import 'core_api_widgets_test.dart' show ScreenHttp, detail, useTestMedia;
import 'core_api_test.dart' show todayDto, issueDto;

Map<String, dynamic> ownMagazine() => {
  'masthead': 'artist',
  'issueCount': 0,
  'pastIssues': [],
  'todayIssue': null,
  'nextCursor': null,
};
TodayController todayController(ScreenHttp http, {ManualServiceClock? clock}) =>
    TodayController(
      clock: clock ?? ManualServiceClock(DateTime.utc(2026, 10, 18, 3)),
      remote: TodayRemoteSource(http),
      remoteMagazine: MagazineRemoteSource(http),
    );
void main() {
  useTestMedia();
  test(
    'queued colors wait for refresh and every selection reaches server in order',
    () async {
      Completer<Map<String, dynamic>>? gate;
      String? selected;
      final choices = <String>[];
      final http = ScreenHttp((method, path, body) async {
        if (path == '/me/magazine') return ownMagazine();
        if (method == 'PUT') {
          selected = body!['colorId'] as String;
          choices.add(selected!);
          return todayDto(selected: selected);
        }
        if (gate != null) return gate.future;
        return todayDto(selected: selected);
      });
      final c = todayController(http);
      addTearDown(c.dispose);
      c.bindUser(ownerId: 'a');
      await c.reload();
      gate = Completer();
      final refresh = c.reload();
      final first = c.choose(c.candidates[1]), last = c.choose(c.candidates[2]);
      expect(choices, isEmpty);
      gate.complete(todayDto());
      gate = null;
      await Future.wait([refresh, first, last]);
      expect(choices, ['powder', 'camel']);
      expect(c.myColor, EselPaint.camel);
      expect(c.hasTodayData, isTrue);
    },
  );
  test(
    'cached today survives refresh failure; initial failure has no invented data',
    () async {
      var fails = false;
      final http = ScreenHttp((_, path, _) async {
        if (fails) throw const NetworkFailure('연결 실패');
        return path == '/today' ? todayDto() : ownMagazine();
      });
      final c = todayController(http);
      addTearDown(c.dispose);
      c.bindUser(ownerId: 'a');
      await c.reload();
      final old = c.candidates;
      fails = true;
      await c.reload();
      expect(c.candidates, old);
      expect(c.hasTodayData, isTrue);
      expect(c.error, '연결 실패');
      c.bindUser(ownerId: 'b');
      await c.reload();
      expect(c.hasTodayData, isFalse);
      expect(c.candidates, isEmpty);
    },
  );
  test('queued color from another account is discarded', () async {
    Completer<Map<String, dynamic>>? gate;
    final http = ScreenHttp((_, path, _) async {
      if (path == '/me/magazine') return ownMagazine();
      return gate == null ? todayDto() : gate.future;
    });
    final c = todayController(http);
    addTearDown(c.dispose);
    c.bindUser(ownerId: 'a');
    await c.reload();
    gate = Completer();
    final refresh = c.reload();
    final chosen = c.choose(c.candidates.last);
    final pending = gate;
    gate = null;
    c.bindUser(ownerId: 'b');
    await c.reload();
    pending.complete(todayDto());
    await Future.wait([refresh, chosen]);
    expect(http.calls, isNot(contains('PUT /today/choice')));
  });
  testWidgets('midnight failure does not create a one-second request loop', (
    tester,
  ) async {
    final clock = ManualServiceClock(DateTime.utc(2026, 10, 18, 14, 59, 59));
    var fails = false, count = 0;
    final http = ScreenHttp((_, path, _) async {
      if (path == '/today') {
        count++;
        if (fails) throw const NetworkFailure('연결 실패');
        return todayDto();
      }
      return ownMagazine();
    });
    final c = todayController(http, clock: clock);
    addTearDown(c.dispose);
    c.bindUser(ownerId: 'a');
    await c.reload();
    c.watchMidnight();
    fails = true;
    clock.set(DateTime.utc(2026, 10, 18, 15, 0, 1));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(count, 2);
    await tester.pump(const Duration(seconds: 12));
    expect(count, 2);
    expect(c.error, '연결 실패');
    c.stopWatchingMidnight();
  });
  testWidgets(
    'more-page error preserves visible records and retries the same cursor',
    (tester) async {
      tester.view.physicalSize = const Size(480, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var fail = true;
      final cursors = <String?>[];
      final http = ScreenHttp((_, _, query) async {
        final cursor = query?['cursor'] as String?;
        cursors.add(cursor);
        if (cursor != null && fail) throw const NetworkFailure('다음 목록 연결 실패');
        return {
          'masthead': 'artist',
          'issueCount': 2,
          'isSubscribed': false,
          'issues': [
            {...issueDto(), 'id': cursor == null ? 'first' : 'second'},
          ],
          'nextCursor': cursor == null ? 'next' : null,
        };
      });
      final c = MagazineController(MagazineRemoteSource(http));
      addTearDown(c.dispose);
      final rc = ReactionsController();
      addTearDown(rc.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: ShelfScreen(
            ownerId: 'artist',
            viewerId: 'viewer',
            controller: c,
            reactionsController: rc,
            viewer: const SameColorViewer.reader(ServiceDate(2026, 10, 18)),
            onSelectIssue: (_, _) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('이전 캔버스 더 보기'), 250);
      await tester.tap(find.text('이전 캔버스 더 보기'));
      await tester.pumpAndSettle();
      expect(c.profile!.issues.single.id, 'first');
      expect(c.profile!.nextCursor, 'next');
      expect(c.errorMessage, isNull);
      expect(find.text('다음 목록 연결 실패'), findsOneWidget);
      fail = false;
      await tester.tap(find.text('더 보기 다시 시도'));
      await tester.pumpAndSettle();
      expect(cursors, [null, 'next', 'next']);
      expect(c.profile!.issues.map((v) => v.id), ['first', 'second']);
      expect(c.moreError, isNull);
    },
  );
  for (final mine in [false, true]) {
    testWidgets(
      'reader line count is ${mine ? 'owner total' : 'hidden from others'}',
      (tester) async {
        tester.view.physicalSize = const Size(480, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final http = ScreenHttp((_, path, _) async {
          if (path.contains('/me/issues/')) {
            return {
              'likeCount': 1,
              'scrapCount': 2,
              'lineCount': 37,
              'likes': [],
              'scraps': [],
            };
          }
          if (path.endsWith('/lines')) {
            return {
              'items': [
                {
                  'id': 'line',
                  'authorMasthead': 'reader',
                  'text': 'hello',
                  'createdAt': '2026-10-18T00:00:00Z',
                },
              ],
              'nextCursor': 'next',
            };
          }
          return issueDto();
        });
        await tester.pumpWidget(MaterialApp(home: detail(http, mine: mine)));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(const Key('reader-lines-heading')),
          220,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          tester
              .widget<Text>(find.byKey(const Key('reader-lines-heading')))
              .data,
          mine ? '한 줄 (37)' : '한 줄',
        );
        if (!mine) {
          expect(http.calls.any((v) => v.contains('/me/issues/')), isFalse);
        }
      },
    );
  }
  testWidgets('own sketchbook shows share instead of self-like or scrap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(480, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final http = ScreenHttp(
      (_, _, _) async => {
        'masthead': 'artist',
        'issueCount': 1,
        'pastIssues': [issueDto()],
        'todayIssue': null,
        'nextCursor': null,
      },
    );
    final c = MagazineController(MagazineRemoteSource(http)),
        rc = ReactionsController();
    addTearDown(c.dispose);
    addTearDown(rc.dispose);
    var shared = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ShelfScreen(
          ownerId: 'a',
          viewerId: 'a',
          isOwner: true,
          masthead: 'artist',
          controller: c,
          reactionsController: rc,
          viewer: const SameColorViewer.reader(ServiceDate(2026, 10, 18)),
          onSelectIssue: (_, _) {},
          onBack: () {},
          onShareIssue: (_) => shared++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byTooltip('공유'), 250);
    await tester.ensureVisible(find.byTooltip('공유'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('좋아요'), findsNothing);
    expect(find.byTooltip('저장'), findsNothing);
    await tester.tap(find.byTooltip('공유'));
    expect(shared, 1);
  });
  test(
    'likes, scraps, subscription and line are queued across a slow request',
    () async {
      final gate = Completer<void>();
      var liked = false, scrapped = false, subscribed = false, lines = 0;
      final http = ScreenHttp((method, path, _) async {
        if (path.endsWith('/like') && method == 'POST') {
          await gate.future;
          liked = true;
          return {};
        }
        if (path.endsWith('/scrap') && method == 'POST') {
          scrapped = true;
          return {};
        }
        if (path.endsWith('/subscription')) {
          subscribed = true;
          return {'subscribed': true};
        }
        if (path.endsWith('/lines')) {
          if (method == 'POST') {
            lines++;
            return {};
          }
          return {'items': [], 'nextCursor': null};
        }
        return issueDto(liked: liked, scrapped: scrapped);
      });
      final rc = ReactionsController(
        remote: IssueRemoteSource(http),
        remoteMagazine: MagazineRemoteSource(http),
      );
      addTearDown(rc.dispose);
      rc.bindUser('a', null);
      rc.toggleLike('id');
      rc.toggleScrap('id');
      rc.toggleSubscription('artist');
      final posted = rc.submitReaderLine(
        issueId: 'id',
        text: 'hello',
        authorMasthead: 'a',
      );
      expect(rc.loading, isTrue);
      gate.complete();
      expect(await posted, isTrue);
      await rc.whenSaved;
      expect(rc.isLiked('id'), isTrue);
      expect(rc.isScrapped('id'), isTrue);
      expect(rc.isSubscribed('artist'), isTrue);
      expect(subscribed, isTrue);
      expect(lines, 1);
      expect(rc.loading, isFalse);
    },
  );
  test(
    'two fast like taps are applied sequentially instead of keeping the first tap',
    () async {
      var liked = false;
      final http = ScreenHttp((method, path, _) async {
        if (path.endsWith('/like')) {
          liked = method == 'POST';
          return {};
        }
        return issueDto(liked: liked);
      });
      final rc = ReactionsController(remote: IssueRemoteSource(http));
      addTearDown(rc.dispose);
      rc.bindUser('a', null);
      rc.toggleLike('id');
      rc.toggleLike('id');
      await rc.whenSaved;
      expect(liked, isFalse);
      expect(http.calls.where((v) => v.endsWith('/like')), [
        'POST /issues/id/like',
        'DELETE /issues/id/like',
      ]);
    },
  );
}
