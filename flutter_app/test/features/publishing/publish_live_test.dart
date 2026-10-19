import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/config/app_config.dart';
import 'package:esel/core/errors/failures.dart';
import 'package:esel/core/network/http_client.dart';
import 'package:esel/core/storage/session_storage.dart';
import 'package:esel/core/time/service_clock.dart';
import 'package:esel/features/auth/data/sources/auth_remote_source.dart';
import 'package:esel/features/drafts/domain/cover_draft.dart';
import 'package:esel/features/garments/domain/garment.dart';
import 'package:esel/features/media/data/media_remote_source.dart';
import 'package:esel/features/media/domain/models/face_layout_mode.dart';
import 'package:esel/features/media/presentation/controllers/media_upload_controller.dart';
import 'package:esel/features/publishing/data/publishing_remote_source.dart';
import 'package:esel/features/today/data/sources/today_remote_source.dart';
import 'package:esel/features/today/presentation/controllers/today_controller.dart';
import 'package:esel/features/magazine/data/sources/magazine_remote_source.dart';
import 'package:esel/features/feed/data/sources/feed_remote_source.dart';

class LiveHttp extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final enabled = Platform.environment['ESEL_PUBLISH_LIVE'] == '1';
  test(
    'Docker: 허용 연출 3종 실제 발행·옷 저장·재조회·중복 거절·재로그인',
    () async {
      await HttpOverrides.runWithHttpOverrides(() async {
        const config = AppConfig(apiBaseUrl: 'http://127.0.0.1:3000/api');
        final random = Random.secure();
        String letters(int length) => List.generate(
          length,
          (_) => String.fromCharCode(97 + random.nextInt(26)),
        ).join();
        final accounts = <Map<String, dynamic>>[];
        final asset = await rootBundle.load('assets/models/sage-01.jpg');
        final original = asset.buffer.asUint8List(
          asset.offsetInBytes,
          asset.lengthInBytes,
        );
        final effects = [
          <FaceLayoutMode>{},
          {FaceLayoutMode.paintStroke},
          {FaceLayoutMode.belowNeck},
          <FaceLayoutMode>{},
        ];
        for (var i = 0; i < 4; i++) {
          final email =
              'qa-publish-${DateTime.now().microsecondsSinceEpoch}-$i@example.test';
          final password = 'Qa${letters(24)}9!';
          final masthead = 'qa${letters(7)}';
          final storage = InMemorySessionStorage();
          final http = StandardHttpClient(config: config, storage: storage);
          final auth = AuthRemoteSource(http);
          final session = await auth.signupWithEmail(email, password, '');
          await storage.saveTokens(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
          );
          await http.post('/profile', body: {'masthead': masthead});
          final media = MediaRemoteSource(http)..bindOwner(session.userId);
          final publishing = PublishingRemoteSource(
            http,
            MediaUploadController(media),
            readPhoto: (_) async => original,
          );
          final today = TodayController(
            clock: const SystemServiceClock(),
            remote: TodayRemoteSource(http),
            remoteMagazine: MagazineRemoteSource(http),
            publishRemote: publishing.publish,
          );
          today.bindUser(ownerId: session.userId);
          await today.reload();
          expect(today.error, isNull);
          expect(today.candidates, hasLength(3));
          final account = <String, dynamic>{
            'email': email,
            'password': password,
            'masthead': masthead,
            'ownerId': session.userId,
          };
          accounts.add(account);
          if (i == 3) {
            today.dispose();
            media.dispose();
            continue;
          }
          final draft = CoverDraft(
            id: 'local-qa-$i',
            photoPath: 'asset',
            ownerId: session.userId,
            masthead: masthead,
            color: today.candidates.first,
            caption: '실제 발행 검수',
            faceConfirmed: true,
            faceEffects: effects[i],
            faceX: .51,
            faceY: .2,
            faceWidth: .14,
            updatedAt: DateTime.now(),
            garments: [
              const Garment(
                id: 'micros-rand',
                kind: '셔츠',
                name: '검수 셔츠',
                note: '오래 입음',
                todayColor: true,
                x: .5,
                y: .8,
              ),
            ],
          );
          final result = await today.publish(draft);
          expect(result.issueNumber, 1);
          expect(today.hasPublishedToday, true);
          final data = await http.get('/issues/${result.id}');
          expect(data, isNot(contains('faceMode')));
          expect(data['faceCrop'], ['ORIGINAL', 'ORIGINAL', 'BELOW_NECK'][i]);
          expect(data['paintStroke'], i == 1);
          expect(
            (data['garments'] as List).single['garmentId'],
            matches(RegExp(r'^[0-9a-f-]{36}$')),
          );
          final garments = await http.get('/me/garments');
          expect(
            (garments['items'] as List).single['id'],
            (data['garments'] as List).single['garmentId'],
          );
          final profile = await MagazineRemoteSource(http).page(mine: true);
          expect(profile.issueCount, 1);
          expect(profile.today!.id, result.id);
          final feed = await FeedRemoteSource(
            http,
          ).today(viewer: today.viewer, signedIn: true);
          expect(feed.issues.any((v) => v.id == result.id), true);
          final id = (data['media'] as Map)['id'] as String;
          final photo = await media.photo(id);
          expect(photo, isNotEmpty);
          await expectLater(
            today.publish(draft),
            throwsA(
              isA<RuleFailure>().having(
                (e) => e.code,
                'code',
                'ISSUE_ALREADY_PUBLISHED',
              ),
            ),
          );
          await auth.logout();
          await storage.clear();
          media.bindOwner(null);
          final again = await auth.loginWithEmail(email, password);
          await storage.saveTokens(
            accessToken: again.accessToken,
            refreshToken: again.refreshToken,
          );
          final fresh = StandardHttpClient(config: config, storage: storage);
          expect((await fresh.get('/issues/${result.id}'))['id'], result.id);
          expect(
            await MediaRemoteSource(fresh).photo(id),
            orderedEquals(photo),
          );
          account['issueId'] = result.id;
          account['mediaId'] = id;
          today.dispose();
          media.dispose();
        }
        final output = Platform.environment['ESEL_PUBLISH_FIXTURE_OUTPUT'];
        if (output != null) {
          await File(output).writeAsString(
            jsonEncode({'baseUrl': config.apiBaseUrl, 'accounts': accounts}),
          );
        }
      }, LiveHttp());
    },
    skip: !enabled,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
