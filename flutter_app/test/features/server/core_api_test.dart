import 'package:esel/features/media/domain/models/face_layout_mode.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/config/app_config.dart';
import 'package:esel/core/design/tokens.g.dart';
import 'package:esel/core/errors/failures.dart';
import 'package:esel/core/network/http_client.dart';
import 'package:esel/core/storage/session_storage.dart';
import 'package:esel/core/time/service_date.dart';
import 'package:esel/features/issue/data/sources/issue_remote_source.dart';
import 'package:esel/features/magazine/data/sources/magazine_remote_source.dart';
import 'package:esel/features/records/data/sources/records_remote_source.dart';
import 'package:esel/features/today/data/sources/today_remote_source.dart';

Map<String, dynamic> issueDto({bool liked = false, bool scrapped = false}) => {
  'id': 'issue-one',
  'masthead': 'artist',
  'issueNumber': 1,
  'serviceDate': '2026-10-17',
  'publishedAt': '2026-10-17T01:00:00Z',
  'color': {'id': 'sage'},
  'media': {
    'id': 'media-one',
    'mimeType': 'image/png',
    'width': null,
    'height': null,
  },
  'caption': 'test caption',
  'faceCrop': 'ORIGINAL',
  'paintStroke': false,
  'liked': liked,
  'scrapped': scrapped,
};
Map<String, dynamic> todayDto({String? selected, bool published = false}) => {
  'serviceDate': '2026-10-18',
  'candidates': [
    {'id': 'sage'},
    {'id': 'powder'},
    {'id': 'camel'},
  ],
  'selectedColorId': selected,
  'hasPublishedToday': published,
};
void main() {
  test('새 응답은 사인 뒤로+물감을 보존하고 목 아래의 물감은 정규화한다', () {
    final behind = serverIssueToPublic(
      parseServerIssue({
        ...issueDto(),
        'faceCrop': 'BEHIND_LOGO',
        'paintStroke': true,
      }),
    );
    expect(behind.faceEffects, {
      FaceLayoutMode.behindLogo,
      FaceLayoutMode.paintStroke,
    });
    final neck = serverIssueToPublic(
      parseServerIssue({
        ...issueDto(),
        'faceCrop': 'BELOW_NECK',
        'paintStroke': true,
      }),
    );
    expect(neck.faceEffects, {FaceLayoutMode.belowNeck});
    expect(neck.faceMode, FaceLayoutMode.belowNeck);
  });

  late HttpServer server;
  late StandardHttpClient http;
  late InMemorySessionStorage storage;
  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    storage = InMemorySessionStorage();
    await storage.saveTokens(
      accessToken: 'test-access',
      refreshToken: 'test-refresh',
    );
    http = StandardHttpClient(
      config: AppConfig(apiBaseUrl: 'http://127.0.0.1:${server.port}/api'),
      storage: storage,
    );
  });
  tearDown(() async {
    await server.close(force: true);
  });
  void respond(Future<Map<String, dynamic>> Function(HttpRequest) handler) {
    server.listen((req) async {
      expect(req.headers.value('authorization'), 'Bearer test-access');
      req.response.headers.contentType = ContentType.json;
      req.response.write(jsonEncode(await handler(req)));
      await req.response.close();
    });
  }

  test(
    'today reads server date and three candidates, PUT uses colorId',
    () async {
      respond((req) async {
        if (req.method == 'PUT') {
          expect(req.uri.path, '/api/today/choice');
          expect(jsonDecode(await utf8.decoder.bind(req).join()), {
            'colorId': 'camel',
          });
          return todayDto(selected: 'camel');
        }
        expect(req.uri.path, '/api/today');
        return todayDto();
      });
      final source = TodayRemoteSource(http);
      expect((await source.today()).date, const ServiceDate(2026, 10, 18));
      expect((await source.choose(EselPaint.camel)).selected, EselPaint.camel);
    },
  );
  test(
    'choice locked remains server error, no fabricated selected color',
    () async {
      respond((req) async {
        req.response.statusCode = 409;
        return {
          'error': {'code': 'CHOICE_LOCKED', 'message': '색을 바꿀 수 없어요.'},
        };
      });
      await expectLater(
        TodayRemoteSource(http).choose(EselPaint.camel),
        throwsA(
          isA<RuleFailure>().having((e) => e.code, 'code', 'CHOICE_LOCKED'),
        ),
      );
    },
  );
  test(
    'magazine and own magazine preserve cursor and use different endpoints',
    () async {
      respond((req) async {
        if (req.uri.path == '/api/me/magazine') {
          return {
            'masthead': 'artist',
            'issueCount': 21,
            'todayIssue': null,
            'pastIssues': [issueDto()],
            'nextCursor': 'cursor-20',
          };
        }
        expect(req.uri.path, '/api/magazines/artist');
        expect(req.uri.queryParameters['cursor'], 'cursor-20');
        return {
          'masthead': 'artist',
          'issueCount': 21,
          'isSubscribed': true,
          'issues': [],
          'nextCursor': null,
        };
      });
      final source = MagazineRemoteSource(http);
      final mine = await source.page(mine: true);
      expect(mine.page.items.single.mediaId, 'media-one');
      expect(mine.page.nextCursor, 'cursor-20');
      final other = await source.page(
        mine: false,
        masthead: 'artist',
        cursor: mine.page.nextCursor,
      );
      expect(other.subscribed, isTrue);
      expect(other.page.items, isEmpty);
    },
  );
  test(
    'subscription consumes subscribed boolean, not magazine isSubscribed',
    () async {
      respond((req) async {
        expect(req.uri.path, '/api/magazines/artist/subscription');
        return {'subscribed': req.method == 'POST'};
      });
      final source = MagazineRemoteSource(http);
      expect(await source.subscribe('artist', true), isTrue);
      expect(await source.subscribe('artist', false), isFalse);
    },
  );
  test(
    'like and scrap are server mutations followed by fresh visible issue',
    () async {
      var liked = false, scrapped = false;
      respond((req) async {
        if (req.uri.path.endsWith('/like')) liked = req.method == 'POST';
        if (req.uri.path.endsWith('/scrap')) scrapped = req.method == 'POST';
        return req.method == 'GET'
            ? issueDto(liked: liked, scrapped: scrapped)
            : {'liked': liked, 'scrapped': scrapped};
      });
      final source = IssueRemoteSource(http);
      expect(
        (await source.setReaction(
          'issue-one',
          like: true,
          enabled: true,
        )).liked,
        isTrue,
      );
      expect(
        (await source.setReaction(
          'issue-one',
          like: false,
          enabled: true,
        )).scrapped,
        isTrue,
      );
      expect(
        (await source.setReaction(
          'issue-one',
          like: true,
          enabled: false,
        )).liked,
        isFalse,
      );
    },
  );
  test(
    'reader lines paginate, submit trimmed text, owner counts use me endpoint',
    () async {
      respond((req) async {
        if (req.uri.path.contains('/me/issues/')) {
          return {
            'issueId': 'issue-one',
            'likeCount': 3,
            'scrapCount': 2,
            'lineCount': 1,
            'likes': [
              {'masthead': 'reader'},
            ],
            'scraps': [],
            'lines': [],
          };
        }
        if (req.method == 'POST') {
          expect(jsonDecode(await utf8.decoder.bind(req).join()), {
            'text': 'nice',
          });
        }
        if (req.method == 'GET') {
          expect(req.uri.queryParameters['cursor'], 'cursor-line');
        }
        return {
          'items': [
            {
              'id': 'line',
              'authorMasthead': 'reader',
              'text': 'nice',
              'createdAt': '2026-10-18T01:00:00Z',
            },
          ],
          'nextCursor': null,
        };
      });
      final source = IssueRemoteSource(http);
      await source.addLine('issue-one', '  nice  ');
      expect(
        (await source.lines(
          'issue-one',
          cursor: 'cursor-line',
        )).items.single.text,
        'nice',
      );
      expect((await source.ownerReactions('issue-one')).likes, 3);
    },
  );
  test(
    'records distinguish restored and issue; restore calls only record API',
    () async {
      respond((req) async {
        if (req.method == 'POST') {
          expect(req.uri.path, '/api/me/records/2026-10-17/restore');
          expect(jsonDecode(await utf8.decoder.bind(req).join()), {
            'colorId': 'sage',
          });
          return {};
        }
        expect(req.uri.queryParameters, {'month': '2026-10'});
        return {
          'month': '2026-10',
          'remainingRestores': 1,
          'days': [
            {
              'serviceDate': '2026-10-17',
              'kind': 'RESTORED',
              'color': {'id': 'sage'},
              'issueId': null,
            },
            {
              'serviceDate': '2026-10-16',
              'kind': 'ISSUE',
              'color': {'id': 'camel'},
              'issueId': 'one',
            },
          ],
        };
      });
      final source = RecordsRemoteSource(http);
      final records = await source.month('2026-10');
      expect(records.remaining, 1);
      expect(records.days.first.restored, isTrue);
      expect(records.days.last.issueId, 'one');
      await source.restore(const ServiceDate(2026, 10, 17), EselPaint.sage);
    },
  );
  test(
    'locked resources stay 404 instead of loading demo or stale detail',
    () async {
      respond((req) async {
        req.response.statusCode = 404;
        return {
          'error': {'code': 'NOT_FOUND', 'message': '찾을 수 없어요.'},
        };
      });
      await expectLater(
        IssueRemoteSource(http).issue('hidden'),
        throwsA(isA<NotFoundFailure>()),
      );
      await expectLater(
        MagazineRemoteSource(http).page(mine: false, masthead: 'hidden'),
        throwsA(isA<NotFoundFailure>()),
      );
    },
  );
  test('connection failure never becomes local content', () async {
    await server.close(force: true);
    await expectLater(
      TodayRemoteSource(http).today(),
      throwsA(isA<NetworkFailure>()),
    );
  });
}
