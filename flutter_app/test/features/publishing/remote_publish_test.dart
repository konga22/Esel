import 'package:esel/features/publishing/domain/publish_request_failure.dart';
import 'package:flutter/material.dart';
import 'package:esel/app/dependencies/service_locator.dart';
import 'package:esel/core/storage/session_storage.dart';
import 'package:esel/core/time/service_date.dart';
import 'package:esel/features/issue/domain/models/public_issue.dart';
import 'package:esel/features/issue/presentation/canvas_photo.dart';
import 'package:esel/features/media/domain/models/face_box.dart';
import 'package:esel/features/media/presentation/cover_photo.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/errors/failures.dart';
import 'package:esel/core/design/tokens.g.dart';
import 'package:esel/core/time/service_clock.dart';
import 'package:esel/features/drafts/domain/cover_draft.dart';
import 'package:esel/features/garments/domain/garment.dart';
import 'package:esel/features/media/domain/models/face_layout_mode.dart';
import 'package:esel/features/media/presentation/controllers/media_upload_controller.dart';
import 'package:esel/features/publishing/data/publishing_remote_source.dart';
import 'package:esel/features/today/data/sources/today_remote_source.dart';
import 'package:esel/features/today/presentation/controllers/today_controller.dart';
import 'package:esel/features/magazine/data/sources/magazine_remote_source.dart';
import '../media/publish_photo_renderer_test.dart' show RecordingMedia;
import '../server/core_api_widgets_test.dart' show ScreenHttp;
import '../server/core_api_test.dart' show issueDto, todayDto;

CoverDraft draft([
  Set<FaceLayoutMode> effects = const {},
  List<Garment> garments = const [],
]) => CoverDraft(
  id: 'device-id',
  ownerId: 'owner',
  photoPath: 'assets/models/sage-01.jpg',
  masthead: 'artist',
  caption: '오늘의 옷',
  color: EselPaint.sage,
  faceEffects: effects,
  faceConfirmed: true,
  garments: garments,
  updatedAt: DateTime.utc(2026, 10, 18, 3),
);
Map<String, dynamic> savedIssue() => {
  ...issueDto(),
  'serviceDate': '2026-10-18',
  'issueNumber': 2,
};
Future<Uint8List> bytes(String _) async {
  final asset = await rootBundle.load('assets/models/sage-01.jpg');
  return asset.buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final entry in <Set<FaceLayoutMode>, Map<String, dynamic>>{
    <FaceLayoutMode>{}: {'faceCrop': 'ORIGINAL', 'paintStroke': false},
    {FaceLayoutMode.paintStroke}: {'faceCrop': 'ORIGINAL', 'paintStroke': true},
    {FaceLayoutMode.belowNeck}: {
      'faceCrop': 'BELOW_NECK',
      'paintStroke': false,
    },
  }.entries) {
    test('허용된 연출은 새 두 필드 ${entry.value}로 발행하고 로컬 옷 ID를 보내지 않는다', () async {
      final media = RecordingMedia()..bindOwner('owner');
      final http = ScreenHttp((method, path, body) async {
        expect(method, 'POST');
        expect(path, '/issues');
        expect(body, isNot(contains('faceMode')));
        expect(body!['faceCrop'], entry.value['faceCrop']);
        expect(body['paintStroke'], entry.value['paintStroke']);
        expect(body['mediaId'], 'ready-id');
        expect((body['garments'] as List).single, isNot(contains('garmentId')));
        return savedIssue();
      });
      final source = PublishingRemoteSource(
        http,
        MediaUploadController(media),
        readPhoto: bytes,
      );
      final result = await source.publish(
        draft(entry.key, [
          const Garment(
            id: 'micros-rand',
            kind: '셔츠',
            name: '셔츠',
            todayColor: true,
            x: .5,
            y: .8,
          ),
        ]),
      );
      expect(media.sent, isNotEmpty);
      expect(result.issueNumber, 2);
      expect(result.id, issueDto()['id']);
    });
  }
  for (final effects in [
    {FaceLayoutMode.behindLogo},
    {FaceLayoutMode.behindLogo, FaceLayoutMode.paintStroke},
  ]) {
    test('사인 뒤로 조합은 파일 읽기와 HTTP 전에 차단', () async {
      final media = RecordingMedia()..bindOwner('owner');
      var read = false;
      final http = ScreenHttp((_, _, _) async => throw StateError('HTTP 금지'));
      final source = PublishingRemoteSource(
        http,
        MediaUploadController(media),
        readPhoto: (_) async {
          read = true;
          return Uint8List(0);
        },
      );
      await expectLater(
        source.publish(draft(effects)),
        throwsA(
          isA<RuleFailure>().having(
            (e) => e.code,
            'code',
            'SIGNATURE_UPLOAD_PENDING',
          ),
        ),
      );
      expect(read, false);
      expect(http.calls, isEmpty);
    });
  }
  test('GET 내 옷 응답 id를 읽고 실제 본인 옷 UUID만 재사용한다', () async {
    const id = '00000000-0000-4000-8000-000000000001';
    final media = RecordingMedia()..bindOwner('owner');
    final http = ScreenHttp((method, path, body) async {
      if (method == 'GET') {
        expect(path, '/me/garments');
        return {
          'items': [
            {'id': id, 'kind': '셔츠', 'name': '내 옷', 'note': ''},
          ],
          'nextCursor': null,
        };
      }
      expect((body!['garments'] as List).single['garmentId'], id);
      return savedIssue();
    });
    await PublishingRemoteSource(
      http,
      MediaUploadController(media),
      readPhoto: bytes,
    ).publish(draft({}, [const Garment(id: id, kind: '셔츠', name: '내 옷')]));
  });
  test('원본 옷 좌표는 합성 사진 기준으로 바꾸고 잘린 점은 보내지 않는다', () {
    final d = draft({FaceLayoutMode.belowNeck});
    final hidden = PublishingRemoteSource.garmentInput(
      const Garment(id: 'local', kind: '셔츠', x: .5, y: .1),
      d,
      4 / 3,
      knownServerId: false,
    );
    final visible = PublishingRemoteSource.garmentInput(
      const Garment(id: 'local', kind: '바지', x: .5, y: .8),
      d,
      4 / 3,
      knownServerId: false,
    );
    expect(hidden, isNot(contains('x')));
    expect(hidden, isNot(contains('y')));
    expect(visible['x'], closeTo(.5, .01));
    expect(visible['y'], inInclusiveRange(0, 1));
    expect(visible['y'], isNot(.8));
  });
  for (final code in ['ISSUE_ALREADY_PUBLISHED', 'MEDIA_NOT_READY']) {
    test('서버 $code 오류를 보존하고 초안 내용을 바꾸지 않는다', () async {
      final media = RecordingMedia()..bindOwner('owner');
      final source = PublishingRemoteSource(
        ScreenHttp((_, _, _) async => throw RuleFailure('서버 안내', code: code)),
        MediaUploadController(media),
        readPhoto: bytes,
      );
      final before = draft();
      await expectLater(
        source.publish(before),
        throwsA(
          isA<PublishRequestFailure>()
              .having((e) => e.code, 'code', code)
              .having((e) => e.cause, '원래 서버 오류', isA<RuleFailure>()),
        ),
      );
      expect(before.issueNumber, 0);
      expect(before.photoPath, isNotEmpty);
    });
  }
  test('사진 읽는 중 계정 변경은 발행 요청을 막는다', () async {
    final media = RecordingMedia()..bindOwner('owner');
    final http = ScreenHttp((_, _, _) async => throw StateError('HTTP 금지'));
    final source = PublishingRemoteSource(
      http,
      MediaUploadController(media),
      readPhoto: (_) async {
        media.bindOwner('other');
        return Uint8List(0);
      },
    );
    await expectLater(source.publish(draft()), throwsA(isA<AuthFailure>()));
    expect(http.calls, isEmpty);
  });
  test('오늘 상태 → 색 저장 → 발행 → 재조회, 새로고침 실패해도 성공을 취소하지 않는다', () async {
    var posted = false;
    String? selected;
    final calls = <String>[];
    final http = ScreenHttp((method, path, body) async {
      calls.add('$method $path');
      if (posted) {
        throw const NetworkFailure('조회만 실패');
      }
      if (path == '/today/choice') {
        selected = body!['colorId'] as String;
        return todayDto(selected: selected);
      }
      if (path == '/today') {
        return todayDto(selected: selected);
      }
      return {
        'masthead': 'artist',
        'issueCount': 0,
        'todayIssue': null,
        'pastIssues': [],
        'nextCursor': null,
      };
    });
    var writes = 0;
    final gate = Completer<void>();
    final c = TodayController(
      clock: ManualServiceClock(DateTime.utc(2026, 10, 18, 3)),
      remote: TodayRemoteSource(http),
      remoteMagazine: MagazineRemoteSource(http),
      publishRemote: (d) async {
        writes++;
        await gate.future;
        posted = true;
        return d.copyWith(issueNumber: 1, publishedOn: '2026-10-18');
      },
    );
    addTearDown(c.dispose);
    c.bindUser(ownerId: 'owner');
    await c.reload();
    final pending = c.publish(draft());
    await expectLater(c.publish(draft()), throwsA(isA<RuleFailure>()));
    gate.complete();
    final result = await pending;
    expect(result.issueNumber, 1);
    expect(writes, 1);
    expect(selected, 'sage');
    expect(c.hasPublishedToday, true);
    expect(c.issueCount, 1);
    expect(c.error, '조회만 실패');
    expect(calls, contains('PUT /today/choice'));
  });
  test('이전 계정의 느린 발행이 새 계정을 막거나 새 발행 잠금을 풀지 않는다', () async {
    final startedA = Completer<void>(), startedB = Completer<void>();
    final gateA = Completer<void>(), gateB = Completer<void>();
    final http = ScreenHttp(
      (method, path, body) async => path == '/today' || path == '/today/choice'
          ? todayDto(
              selected: method == 'PUT' ? body!['colorId'] as String : null,
            )
          : {
              'masthead': 'artist',
              'issueCount': 0,
              'todayIssue': null,
              'pastIssues': [],
              'nextCursor': null,
            },
    );
    final c = TodayController(
      clock: ManualServiceClock(DateTime.utc(2026, 10, 18, 3)),
      remote: TodayRemoteSource(http),
      remoteMagazine: MagazineRemoteSource(http),
      publishRemote: (d) async {
        if (d.ownerId == 'owner') {
          startedA.complete();
          await gateA.future;
        } else {
          startedB.complete();
          await gateB.future;
        }
        return d.copyWith(issueNumber: 1, publishedOn: '2026-10-18');
      },
    );
    addTearDown(c.dispose);
    c.bindUser(ownerId: 'owner');
    await c.reload();
    final first = c.publish(draft());
    final firstCheck = expectLater(first, throwsA(isA<AuthFailure>()));
    await startedA.future;
    c.bindUser(ownerId: 'other');
    await c.reload();
    final other = draft().copyWith(ownerId: 'other');
    final second = c.publish(other);
    await startedB.future;
    gateA.complete();
    await firstCheck;
    await expectLater(c.publish(other), throwsA(isA<RuleFailure>()));
    gateB.complete();
    expect((await second).ownerId, 'other');
  });
  testWidgets('서버 사진의 옷 태그를 누를 수 있고 얼굴 연출을 두 번 적용하지 않는다', (tester) async {
    ServiceLocator().initialize(
      client: ScreenHttp((_, _, _) async => {}),
      sessionStorage: InMemorySessionStorage(),
    );
    String? selected;
    final issue = PublicIssue(
      id: 'server',
      ownerId: 'owner',
      masthead: 'artist',
      issueNumber: 1,
      date: const ServiceDate(2026, 10, 18),
      publishedAt: DateTime.utc(2026, 10, 18),
      timeLabel: '',
      color: EselPaint.sage,
      photo: 'media:photo',
      face: const FaceBox(.5, .3, .16),
      faceMode: FaceLayoutMode.paintStroke,
      caption: '',
      alt: '서버 사진',
      garments: [const Garment(id: 'server-garment', kind: '셔츠', x: .5, y: .8)],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 300,
            height: 400,
            child: CanvasPhoto(
              issue: issue,
              tags: true,
              onTag: (id) => selected = id,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('garment-tag-server-garment')));
    expect(selected, 'server-garment');
    expect(find.byType(CoverPhoto), findsNothing);
    expect(tester.takeException(), isNull);
  });
  for (final outcome in [
    'timeout-saved',
    'decode-saved',
    'not-saved',
    'other-photo',
    'refresh-failed',
  ]) {
    test('POST 뒤 $outcome: 오늘 상태를 다시 읽고 같은 사진 저장이 확인된 경우만 성공', () async {
      var sent = false, posts = 0;
      String? selected;
      final calls = <String>[];
      final media = RecordingMedia()..bindOwner('owner');
      final http = ScreenHttp((method, path, body) async {
        calls.add('$method $path');
        if (path == '/issues') {
          sent = true;
          posts++;
          if (outcome == 'decode-saved') {
            return {'id': 'saved-but-incomplete-response'};
          }
          throw const NetworkFailure('원래 전송 오류', code: 'TIMEOUT');
        }
        if (path == '/today') {
          if (sent && outcome == 'refresh-failed') {
            throw const NetworkFailure('오늘 상태 조회 실패');
          }
          return todayDto(
            selected: selected,
            published: sent && outcome != 'not-saved',
          );
        }
        if (path == '/today/choice') {
          selected = body!['colorId'] as String;
          return todayDto(selected: selected);
        }
        return {
          'masthead': 'artist',
          'issueCount': sent ? 2 : 0,
          'todayIssue': sent && outcome != 'not-saved'
              ? {
                  ...savedIssue(),
                  'faceCrop': 'ORIGINAL',
                  'paintStroke': true,
                  'media': {
                    'id': outcome == 'other-photo'
                        ? 'different-media'
                        : 'ready-id',
                  },
                }
              : null,
          'pastIssues': [],
          'nextCursor': null,
        };
      });
      final publisher = PublishingRemoteSource(
        http,
        MediaUploadController(media),
        readPhoto: bytes,
      );
      final c = TodayController(
        clock: ManualServiceClock(DateTime.utc(2026, 10, 18, 3)),
        remote: TodayRemoteSource(http),
        remoteMagazine: MagazineRemoteSource(http),
        publishRemote: publisher.publish,
      );
      addTearDown(c.dispose);
      c.bindUser(ownerId: 'owner');
      await c.reload();
      if (outcome == 'timeout-saved' || outcome == 'decode-saved') {
        final result = await c.publish(draft({FaceLayoutMode.paintStroke}));
        expect(result.id, savedIssue()['id']);
        expect(result.issueNumber, 2);
        expect(result.photoPath, draft().photoPath);
        expect(result.effectiveFaceEffects, {FaceLayoutMode.paintStroke});
        expect(c.hasPublishedToday, true);
        expect(c.error, isNull);
      } else {
        await expectLater(
          c.publish(draft()),
          throwsA(
            isA<NetworkFailure>().having(
              (e) => e.message,
              '최초 오류 유지',
              '원래 전송 오류',
            ),
          ),
        );
      }
      expect(posts, 1);
      final postIndex = calls.indexOf('POST /issues');
      expect(calls.skip(postIndex + 1), contains('GET /today'));
      if (outcome != 'refresh-failed') {
        expect(calls.skip(postIndex + 1), contains('GET /me/magazine'));
      }
    });
  }
  test('이미 발행한 날과 타인의 초안은 업로드 전 거절한다', () async {
    var uploads = 0;
    final http = ScreenHttp(
      (_, path, _) async => path == '/today'
          ? todayDto(published: true)
          : {
              'masthead': 'artist',
              'issueCount': 1,
              'todayIssue': null,
              'pastIssues': [],
              'nextCursor': null,
            },
    );
    final c = TodayController(
      clock: ManualServiceClock(DateTime.utc(2026, 10, 18, 3)),
      remote: TodayRemoteSource(http),
      remoteMagazine: MagazineRemoteSource(http),
      publishRemote: (d) async {
        uploads++;
        return d;
      },
    );
    addTearDown(c.dispose);
    c.bindUser(ownerId: 'owner');
    await c.reload();
    await expectLater(
      c.publish(draft()),
      throwsA(
        isA<RuleFailure>().having(
          (e) => e.code,
          'code',
          'ISSUE_ALREADY_PUBLISHED',
        ),
      ),
    );
    await expectLater(
      c.publish(draft().copyWith(ownerId: 'other')),
      throwsA(isA<AuthFailure>()),
    );
    expect(uploads, 0);
  });
}
