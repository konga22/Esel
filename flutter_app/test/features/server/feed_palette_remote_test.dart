import 'package:esel/features/auth/domain/models/auth_session.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/config/app_config.dart';
import 'package:esel/core/design/tokens.g.dart';
import 'package:esel/core/network/http_client.dart';
import 'package:esel/core/storage/session_storage.dart';
import 'package:esel/core/time/service_date.dart';
import 'package:esel/features/auth/data/sources/auth_remote_source.dart';
import 'package:esel/features/feed/data/sources/feed_remote_source.dart';
import 'package:esel/features/feed/domain/models/feed_page.dart';
import 'package:esel/features/media/domain/models/face_layout_mode.dart';
import 'package:esel/features/stand/data/sources/stand_remote_source.dart';
import 'package:esel/features/stand/domain/models/stand_shelf.dart';
import 'package:esel/features/stand/domain/rules/same_color_rule.dart';

/// 서버 IssuePublicDto 모양(server/src/issues/dto/issue-public.dto.ts).
Map<String, dynamic> issue(
  String id,
  String masthead, {
  String color = 'sage',
  String faceMode = 'PLAIN',
  bool withDate = true,
}) => {
  'id': id,
  'masthead': masthead,
  'issueNumber': 3,
  if (withDate) 'serviceDate': '2026-10-18',
  'publishedAt': '2026-10-18T01:00:00.000Z',
  'color': {'id': color, 'nameKo': '이름', 'nameEn': 'name', 'hex': '#000000'},
  'media': {'id': 'media-$id', 'mimeType': 'image/png'},
  'caption': '캡션 $id',
  'faceMode': faceMode,
  'garments': const [],
  if (withDate) 'liked': false,
  if (withDate) 'scrapped': true,
};

void main() {
  late HttpServer server;
  late StandardHttpClient http;
  final requests = <String>[];
  const viewer = SameColorViewer(
    today: ServiceDate(2026, 10, 18),
    candidates: [EselPaint.sage, EselPaint.camel, EselPaint.powder],
    hasPublishedToday: false,
    isMinor: false,
  );

  setUp(() async {
    requests.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final storage = InMemorySessionStorage();
    await storage.saveTokens(accessToken: 'access', refreshToken: 'refresh');
    http = StandardHttpClient(
      config: AppConfig(apiBaseUrl: 'http://127.0.0.1:${server.port}/api'),
      storage: storage,
    );
  });
  tearDown(() => server.close(force: true));

  void respond(Object? Function(HttpRequest req, String body) handler) {
    server.listen((req) async {
      final body = await utf8.decoder.bind(req).join();
      requests.add(
        '${req.method} ${req.uri.path}'
        '${req.uri.hasQuery ? '?${req.uri.query}' : ''}',
      );
      final value = handler(req, body);
      req.response.headers.contentType = ContentType.json;
      if (value == null) {
        req.response.statusCode = 204;
      } else {
        req.response.write(jsonEncode(value));
      }
      await req.response.close();
    });
  }

  test('서버 공개 목록에서도 본인 UUID는 유지하고 남의 식별자를 지어내지 않는다', () async {
    respond(
      (req, _) => req.uri.path == '/api/palette/colors'
          ? {'items': []}
          : {
              'items': [
                {...issue('own', 'mina'), 'source': 'RECOMMENDED'},
                {...issue('other', 'jun'), 'source': 'RECOMMENDED'},
              ],
            },
    );
    const session = AuthSession(
      userId: 'own-uuid',
      email: 'qa@example.invalid',
      masthead: 'mina',
      hasPublishedToday: true,
      issueCount: 1,
      accessToken: '',
      refreshToken: '',
    );
    final page = await FeedRemoteSource(
      http,
      currentSession: () => session,
    ).today(viewer: viewer, signedIn: true);
    expect(page.issues.first.ownerId, 'own-uuid');
    expect(page.issues.last.ownerId, 'jun');
  });
  test('페이지 일부만 받은 열린 색 방에는 확정되지 않은 전체 인원을 표시하지 않는다', () async {
    respond(
      (_, _) => {
        'items': [issue('a', 'mina')],
        'hiddenCount': 0,
        'locked': false,
        'closed': false,
        'nextCursor': 'next',
      },
    );
    final source = StandRemoteSource(http);
    final room = await source.shelf(viewer: viewer, color: EselPaint.sage);
    expect(room.countKnown, isFalse);
    expect(await source.sameColorCount(viewer.today, EselPaint.sage), 0);
  });

  group('피드(DEV-10)', () {
    test('로그인: /feed 순서 그대로, 구독 탭은 SUBSCRIPTION만, 남의 표지는 사인으로 연다', () async {
      respond(
        (req, _) => switch (req.uri.path) {
          '/api/feed' => {
            'items': [
              {...issue('a', 'mina'), 'source': 'RECOMMENDED'},
              {
                ...issue('b', 'jun', faceMode: 'PAINT'),
                'source': 'SUBSCRIPTION',
              },
            ],
            'nextCursor': null,
          },
          // 같은 색 인원은 서버가 count를 주면 채운다.
          '/api/palette/colors' => {
            'serviceDate': '2026-10-18',
            'items': [
              {'id': 'sage', 'locked': true, 'selected': false, 'count': 4},
            ],
          },
          _ => throw StateError(req.uri.path),
        },
      );
      final source = FeedRemoteSource(http);
      final page = await source.today(viewer: viewer, signedIn: true);
      expect(page.issues.map((v) => v.id), ['a', 'b']);
      expect(page.cover!.ownerId, 'mina');
      expect(page.cover!.scrapped, isTrue);
      expect(page.innerPages.single.faceMode, FaceLayoutMode.paintStroke);
      expect(page.sameColorCount(EselPaint.sage), 4);
      expect(page.heldBack, isTrue); // 올리기 전: 서버가 후보 3색을 뺐다는 안내
      expect(page.appIssueNumber, viewer.today.dayOfYear);

      final subs = await source.today(
        viewer: viewer,
        signedIn: true,
        tab: FeedTab.subscribed,
      );
      expect(subs.issues.map((v) => v.id), ['b']);
    });

    test('같은 색 인원을 서버가 아직 주지 않거나 실패해도 피드는 보인다', () async {
      respond(
        (req, _) => switch (req.uri.path) {
          '/api/feed' => {
            'items': [
              {...issue('a', 'mina'), 'source': 'RECOMMENDED'},
            ],
            'nextCursor': null,
          },
          _ => {'serviceDate': '2026-10-18', 'items': const []},
        },
      );
      final page = await FeedRemoteSource(
        http,
      ).today(viewer: viewer, signedIn: true);
      expect(page.issues, hasLength(1));
      expect(page.sameColorCount(EselPaint.sage), 0);
    });

    test('비로그인: /today/cover의 표지와 안쪽 2쪽(날짜·반응 없는 항목)', () async {
      respond(
        (req, _) => {
          'serviceDate': '2026-10-18',
          'cover': issue('c', 'dana', withDate: false),
          'pages': [
            issue('d', 'ama', withDate: false),
            issue('e', 'lise', withDate: false),
          ],
        },
      );
      final page = await FeedRemoteSource(
        http,
      ).today(viewer: viewer, signedIn: false);
      expect(requests, ['GET /api/today/cover']);
      expect(page.issues.map((v) => v.id), ['c', 'd', 'e']);
      expect(page.cover!.date, const ServiceDate(2026, 10, 18));
      expect(page.cover!.liked, isFalse);
      expect(page.pagesForMembers, 0);
    });
  });

  group('팔레트(DEV-12)', () {
    test('추천·구독은 서버가 고른 사람마다 한 장을 그대로 쓴다', () async {
      respond(
        (req, _) => {
          'items': [
            {
              'issueId': 'tile-${req.uri.path.split('/').last}',
              'masthead': 'mina',
              'serviceDate': '2026-10-18',
              'color': {'id': 'camel'},
              'media': {'id': 'm', 'mimeType': 'image/png'},
            },
          ],
          'nextCursor': null,
        },
      );
      final source = StandRemoteSource(http);
      final recommended = await source.shelf(viewer: viewer);
      expect(recommended.curated, isTrue);
      expect(recommended.items.single.id, 'tile-recommended');
      expect(recommended.items.single.ownerId, 'mina');
      final subscriptions = await source.shelf(
        viewer: viewer,
        tab: PaletteTab.subscriptions,
      );
      expect(subscriptions.items.single.id, 'tile-subscriptions');
      expect(requests, [
        'GET /api/palette/recommended',
        'GET /api/palette/subscriptions',
      ]);
    });

    test('색 방: 잠긴 방은 먼저 3장과 숨긴 개수, 같은 색 인원은 total이 있으면 그 값', () async {
      respond(
        (req, _) => {
          'serviceDate': '2026-10-18',
          'color': {'id': 'sage'},
          'locked': true,
          'closed': false,
          'hiddenCount': 5,
          'items': [issue('a', 'mina'), issue('b', 'jun'), issue('c', 'kai')],
          'nextCursor': null,
          if (req.uri.queryParameters['date'] != null) 'total': 9,
        },
      );
      final source = StandRemoteSource(http);
      final room = await source.shelf(viewer: viewer, color: EselPaint.sage);
      expect(room.access, SameColorRoomAccess.preview);
      expect(room.items, hasLength(3));
      expect(room.total, 8); // total 없음 → 3 + 5
      expect(
        await source.sameColorCount(viewer.today, EselPaint.sage),
        9, // total 있음
      );
      expect(requests, [
        'GET /api/stand?colorId=sage',
        'GET /api/stand?colorId=sage&date=2026-10-18',
      ]);
    });
  });

  test('탈퇴는 확인 표시를 함께 보낸다(DeleteAccountDto)', () async {
    String? sent;
    respond((req, body) {
      sent = body;
      return null;
    });
    await AuthRemoteSource(http).deleteAccount();
    expect(requests, ['DELETE /api/me']);
    expect(jsonDecode(sent!), {'confirmed': true});
  });
}
