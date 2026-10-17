import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/errors/failures.dart';
import 'package:esel/core/network/http_client.dart';
import 'package:esel/features/issue/presentation/screens/server_issue_screen.dart';
import 'package:esel/features/magazine/presentation/screens/server_magazine_screen.dart';
import 'package:esel/features/records/presentation/screens/server_records_screen.dart';
import 'package:esel/features/today/presentation/screens/server_today_screen.dart';
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
  Future<Map<String, dynamic>> delete(String path) =>
      send('DELETE', path, null);
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
    await tester.pumpWidget(MaterialApp(home: ServerRecordsScreen(http: http)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('이전 달'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(requested, ['2026-10', '2026-09', '2026-09']);
    expect(find.text('2026-09'), findsOneWidget);
  });
  testWidgets(
    'today selects a server color and does not keep candidates after failure',
    (tester) async {
      var failing = false;
      final http = ScreenHttp((method, path, body) async {
        if (failing) throw const NetworkFailure('서버에 연결할 수 없어요.');
        return todayDto(
          selected: method == 'PUT' ? body!['colorId'] as String : null,
        );
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ServerTodayScreen(http: http, onColor: (_) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final buttons = find.byType(OutlinedButton);
      expect(buttons, findsNWidgets(3));
      await tester.tap(buttons.first);
      await tester.pumpAndSettle();
      expect(http.calls, contains('PUT /today/choice'));
      expect(find.text('선택한 색'), findsOneWidget);
      failing = true;
      await tester.tap(find.text('오늘 상태 새로고침'));
      await tester.pumpAndSettle();
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.text('서버에 연결할 수 없어요.'), findsOneWidget);
      failing = false;
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.byType(OutlinedButton), findsNWidgets(3));
    },
  );
  testWidgets('published today disables all choice buttons', (tester) async {
    final http = ScreenHttp((_, _, _) async => todayDto(published: true));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ServerTodayScreen(http: http, onColor: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final button in tester.widgetList<OutlinedButton>(
      find.byType(OutlinedButton),
    )) {
      expect(button.onPressed, isNull);
    }
  });
  testWidgets(
    'public detail hides response counts and never requests owner reactions',
    (tester) async {
      final http = ScreenHttp(
        (_, path, _) async => path.endsWith('/lines')
            ? {'items': [], 'nextCursor': null}
            : {...issueDto(), 'likeCount': 999, 'lineCount': 999},
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ServerIssueScreen(http: http, id: 'issue-one'),
        ),
      );
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
    await tester.pumpWidget(
      MaterialApp(
        home: ServerIssueScreen(http: http, id: 'issue-one', isOwner: true),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('좋아요 7 · 스크랩 2 · 독자 한 줄 0'), 150);
    expect(find.text('좋아요 7 · 스크랩 2 · 독자 한 줄 0'), findsOneWidget);
  });
  testWidgets('missing detail is empty with retry and no actions', (
    tester,
  ) async {
    final http = ScreenHttp(
      (_, _, _) async => throw const NotFoundFailure('찾을 수 없어요.'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ServerIssueScreen(http: http, id: 'hidden'),
      ),
    );
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
      await tester.pumpWidget(
        MaterialApp(
          home: ServerIssueScreen(http: http, id: 'issue-one'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byType(TextField), 200);
      await tester.enterText(find.byType(TextField), 'my comment');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('남기기'));
      await tester.tap(find.text('남기기'));
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
        home: ServerMagazineScreen(http: http, mine: false, masthead: 'artist'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('이전 호 더 보기'));
    await tester.pumpAndSettle();
    expect(find.text('이전 호 더 보기'), findsNothing);
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
          home: ServerRecordsScreen(http: http),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('2026-10'), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
