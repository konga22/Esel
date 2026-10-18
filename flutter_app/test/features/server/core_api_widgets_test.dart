import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/errors/failures.dart';
import 'package:esel/core/network/http_client.dart';
import 'package:esel/features/issue/presentation/widgets/issue_bottom_sheet.dart';
import 'package:esel/features/issue/data/demo_issue_catalog.dart';
import 'package:esel/features/issue/data/sources/issue_remote_source.dart';
import 'package:esel/features/magazine/data/sources/magazine_remote_source.dart';
import 'package:esel/features/magazine/presentation/controllers/magazine_controller.dart';
import 'package:esel/features/magazine/presentation/screens/shelf_screen.dart';
import 'package:esel/features/records/presentation/screens/monthly_record_screen.dart';
import 'package:esel/features/records/data/sources/records_remote_source.dart';
import 'package:esel/features/today/data/sources/today_remote_source.dart';
import 'package:esel/features/today/presentation/controllers/today_controller.dart';
import 'package:esel/features/stand/domain/rules/same_color_rule.dart';
import 'package:esel/features/reactions/presentation/controllers/reactions_controller.dart';
import 'package:esel/core/time/service_clock.dart';
import 'package:esel/core/time/service_date.dart';
import 'package:esel/features/issue/domain/models/public_issue.dart';
import 'core_api_test.dart' show issueDto, todayDto;

class ScreenHttp extends AppHttpClient {
  final Future<Map<String, dynamic>> Function(
    String,
    String,
    Map<String, dynamic>?,
  )
  respond;
  final calls = <String>[];
  ScreenHttp(this.respond);
  Future<Map<String, dynamic>> send(
    String method,
    String path,
    Map<String, dynamic>? body,
  ) {
    calls.add('$method $path');
    return respond(method, path, body);
  }

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
  }) => send('GET', path, queryParams);
  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) => send('POST', path, body);
  @override
  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) =>
      send('PUT', path, body);
  @override
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) => send('PATCH', path, body);
  @override
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
  }) => send('DELETE', path, body);
}

Widget records(ScreenHttp http) => MonthlyRecordScreen(
  source: RecordsRemoteSource(http),
  onBack: () {},
  onOpenIssue: (_) {},
);
Widget detail(ScreenHttp http, {String id = 'issue-one', bool mine = false}) {
  final reference = DemoIssueCatalog.issuesOn(
    const ServiceDate(2026, 10, 17),
  ).first;
  final rc = ReactionsController(remote: IssueRemoteSource(http));
  rc.bindUser('viewer', null);
  // The reference is only a navigation key; public fields are re-read by the common sheet.
  return Scaffold(
    body: IssueBottomSheet(
      issue: PublicIssue(
        id: id,
        ownerId: reference.ownerId,
        masthead: reference.masthead,
        issueNumber: reference.issueNumber,
        date: reference.date,
        publishedAt: reference.publishedAt,
        timeLabel: '',
        color: reference.color,
        photo: '',
        face: reference.face,
        faceMode: reference.faceMode,
        caption: '',
        alt: '',
      ),
      isOwner: mine,
      readerMasthead: 'viewer',
      reactionsController: rc,
      onOpenAuthorShelf: () {},
      onShare: () {},
      onReport: () {},
    ),
  );
}

void main() {
  testWidgets('records retry the requested month after a failed month switch', (
    tester,
  ) async {
    var failed = false;
    final requested = <String>[];
    final http = ScreenHttp((_, path, query) async {
      if (path == '/today') return todayDto();
      final month = query!['month'] as String;
      requested.add(month);
      if (month == '2026-09' && !failed) {
        failed = true;
        throw const NetworkFailure('기록 연결 실패');
      }
      return {'month': month, 'remainingRestores': 2, 'days': []};
    });
    await tester.pumpWidget(MaterialApp(home: records(http)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('이전 달'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(requested, ['2026-10', '2026-09', '2026-09']);
    expect(find.text('2026-09'), findsOneWidget);
  });
  test(
    'today common controller keeps its last snapshot after refresh failure',
    () async {
      var failing = false;
      final http = ScreenHttp((method, path, body) async {
        if (failing) throw const NetworkFailure('연결 실패');
        if (path == '/me/magazine') {
          return {
            'masthead': 'viewer',
            'issueCount': 0,
            'todayIssue': null,
            'pastIssues': [],
            'nextCursor': null,
          };
        }
        return todayDto(
          selected: method == 'PUT' ? body!['colorId'] as String : null,
        );
      });
      final c = TodayController(
        clock: const SystemServiceClock(),
        remote: TodayRemoteSource(http),
        remoteMagazine: MagazineRemoteSource(http),
      );
      addTearDown(c.dispose);
      c.bindUser(ownerId: 'viewer');
      await c.reload();
      expect(c.candidates, hasLength(3));
      await c.choose(c.candidates.first);
      expect(http.calls, contains('PUT /today/choice'));
      failing = true;
      await c.reload();
      expect(c.candidates, hasLength(3));
      expect(c.error, '연결 실패');
      failing = false;
      await c.reload();
      expect(c.candidates, hasLength(3));
    },
  );
  test('published remote today refuses another color choice', () async {
    final http = ScreenHttp(
      (_, path, _) async => path == '/today'
          ? todayDto(published: true)
          : {
              'masthead': 'viewer',
              'issueCount': 0,
              'todayIssue': null,
              'pastIssues': [],
              'nextCursor': null,
            },
    );
    final c = TodayController(
      clock: const SystemServiceClock(),
      remote: TodayRemoteSource(http),
      remoteMagazine: MagazineRemoteSource(http),
    );
    addTearDown(c.dispose);
    c.bindUser(ownerId: 'viewer');
    await c.reload();
    await c.choose(c.candidates.last);
    expect(c.hasPublishedToday, isTrue);
    expect(http.calls, isNot(contains('PUT /today/choice')));
  });
  test(
    'new server account can choose colors before its sketchbook exists',
    () async {
      final http = ScreenHttp((_, path, _) async {
        if (path == '/today') return todayDto();
        throw const NotFoundFailure('아직 스케치북이 없어요.');
      });
      final c = TodayController(
        clock: const SystemServiceClock(),
        remote: TodayRemoteSource(http),
        remoteMagazine: MagazineRemoteSource(http),
      );
      addTearDown(c.dispose);
      c.bindUser(ownerId: 'new', hasProfile: false);
      await c.reload();
      expect(c.candidates, hasLength(3));
      expect(c.error, isNull);
      expect(http.calls, isNot(contains('GET /me/magazine')));
    },
  );
  test(
    'retry after successful line POST and failed refresh does not post twice',
    () async {
      var posted = 0, failed = false;
      final http = ScreenHttp((method, path, _) async {
        if (method == 'POST') {
          posted++;
          return {};
        }
        if (!failed) {
          failed = true;
          throw const NetworkFailure('조회 실패');
        }
        return {'items': [], 'nextCursor': null};
      });
      final c = ReactionsController(remote: IssueRemoteSource(http));
      c.bindUser('a', null);
      addTearDown(c.dispose);
      expect(
        await c.submitReaderLine(
          issueId: 'id',
          text: '안녕',
          authorMasthead: 'artist',
        ),
        isTrue,
      );
      expect(c.saveError, '조회 실패');
      c.retrySave();
      await c.whenSaved;
      expect(posted, 1);
      expect(c.saveError, isNull);
    },
  );
  testWidgets(
    'public detail hides response counts and never requests owner reactions',
    (tester) async {
      final http = ScreenHttp(
        (_, path, _) async => path.endsWith('/lines')
            ? {'items': [], 'nextCursor': null}
            : {...issueDto(), 'likeCount': 999, 'lineCount': 999},
      );
      await tester.pumpWidget(MaterialApp(home: detail(http)));
      await tester.pumpAndSettle();
      expect(find.textContaining('999'), findsNothing);
      expect(http.calls.any((p) => p.contains('/me/issues/')), isFalse);
      expect(find.text('사진 제공 준비 중'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('owner reaction figures load only through owner endpoint', (
    tester,
  ) async {
    final http = ScreenHttp((_, path, _) async {
      if (path.contains('/me/issues/')) {
        return {
          'likeCount': 7,
          'scrapCount': 2,
          'lineCount': 0,
          'likes': [],
          'scraps': [],
        };
      }
      if (path.endsWith('/lines')) return {'items': [], 'nextCursor': null};
      return issueDto();
    });
    await tester.pumpWidget(MaterialApp(home: detail(http, mine: true)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('나에게만 보여요'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(http.calls, contains('GET /me/issues/issue-one/reactions'));
    expect(find.text('7'), findsOneWidget);
  });
  testWidgets('missing detail is empty with retry and no actions', (
    tester,
  ) async {
    final http = ScreenHttp(
      (_, _, _) async => throw const NotFoundFailure('찾을 수 없어요.'),
    );
    await tester.pumpWidget(MaterialApp(home: detail(http, id: 'hidden')));
    await tester.pumpAndSettle();
    expect(find.text('찾을 수 없어요.'), findsOneWidget);
    expect(find.text('좋아요'), findsNothing);
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(http.calls, hasLength(2));
  });
  testWidgets(
    'reader-line failure preserves typed text and shows retry reason',
    (tester) async {
      final http = ScreenHttp((method, path, _) async {
        if (method == 'POST') {
          throw const RuleFailure('잠시 뒤 다시 시도해 주세요.', code: 'RATE_LIMITED');
        }
        if (path.endsWith('/lines')) return {'items': [], 'nextCursor': null};
        return issueDto();
      });
      await tester.pumpWidget(MaterialApp(home: detail(http)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'my comment');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.bySemanticsLabel('한 줄 남기기'));
      await tester.tap(find.bySemanticsLabel('한 줄 남기기'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'my comment',
      );
      expect(find.text('잠시 뒤 다시 시도해 주세요.'), findsOneWidget);
    },
  );
  testWidgets('magazine loads another cursor page without duplicate covers', (
    tester,
  ) async {
    final http = ScreenHttp(
      (_, _, body) async => {
        'masthead': 'artist',
        'issueCount': 2,
        'isSubscribed': false,
        'issues': [issueDto()],
        'nextCursor': body?.containsKey('cursor') == true ? null : 'next',
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ShelfScreen(
          ownerId: 'artist',
          masthead: 'artist',
          viewerId: 'viewer',
          controller: MagazineController(MagazineRemoteSource(http)),
          reactionsController: ReactionsController(
            remote: IssueRemoteSource(http),
          ),
          viewer: const SameColorViewer.reader(ServiceDate(2026, 10, 18)),
          onSelectIssue: (_, _) {},
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('이전 캔버스 더 보기'), 300);
    await tester.tap(find.text('이전 캔버스 더 보기'));
    await tester.pumpAndSettle();
    expect(find.text('이전 캔버스 더 보기'), findsNothing);
    expect(find.text('Nº 001 · 10. 17.'), findsOneWidget);
  });
  testWidgets(
    'records use real month and restored ring, work on narrow large text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final http = ScreenHttp(
        (_, path, _) async => path == '/today'
            ? todayDto()
            : {
                'month': '2026-10',
                'remainingRestores': 1,
                'days': [
                  {
                    'serviceDate': '2026-10-17',
                    'kind': 'RESTORED',
                    'color': {'id': 'sage'},
                    'issueId': null,
                  },
                ],
              },
      );
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: records(http),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('2026-10'), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
