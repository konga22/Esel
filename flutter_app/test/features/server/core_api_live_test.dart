import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/config/app_config.dart';
import 'package:esel/core/design/tokens.g.dart';
import 'package:esel/core/errors/failures.dart';
import 'package:esel/core/network/http_client.dart';
import 'package:esel/core/storage/session_storage.dart';
import 'package:esel/core/time/service_date.dart';
import 'package:esel/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:esel/features/auth/data/sources/auth_mock_source.dart';
import 'package:esel/features/auth/data/sources/auth_remote_source.dart';
import 'package:esel/features/issue/data/sources/issue_remote_source.dart';
import 'package:esel/features/magazine/data/sources/magazine_remote_source.dart';
import 'package:esel/features/records/data/sources/records_remote_source.dart';
import 'package:esel/features/today/data/sources/today_remote_source.dart';

/// 명시적으로 준비한 로컬 Docker 전용. CI와 일반 테스트에서는 연결하지 않고 건너뛴다.
void main() {
  final fixturePath = Platform.environment['ESEL_LIVE_FIXTURE'];
  test(
    'Docker API: real sessions, profile, choice, issue reactions, records and re-login persist',
    () async {
      final fixture =
          jsonDecode(
                (await File(
                  fixturePath!,
                ).readAsString()).replaceFirst('\ufeff', ''),
              )
              as Map;
      final config = AppConfig(apiBaseUrl: fixture['baseUrl'] as String);
      if (Uri.parse(config.apiBaseUrl).host != '127.0.0.1') {
        throw StateError('Local Docker only');
      }
      final owner = fixture['owner'] as Map, reader = fixture['reader'] as Map;
      final issueId = fixture['issueId'] as String;
      final ownerStorage = InMemorySessionStorage(),
          readerStorage = InMemorySessionStorage();
      final ownerHttp = StandardHttpClient(
        config: config,
        storage: ownerStorage,
      );
      final readerHttp = StandardHttpClient(
        config: config,
        storage: readerStorage,
      );
      AuthRepositoryImpl repo(
        StandardHttpClient http,
        InMemorySessionStorage storage,
      ) => AuthRepositoryImpl(
        config: config,
        storage: storage,
        mockSource: AuthMockSource(),
        remoteSource: AuthRemoteSource(http),
      );
      final ownerRepo = repo(ownerHttp, ownerStorage),
          readerRepo = repo(readerHttp, readerStorage);
      await ownerRepo.loginWithEmail(
        owner['email'] as String,
        owner['password'] as String,
      );
      var session = await readerRepo.loginWithEmail(
        reader['email'] as String,
        reader['password'] as String,
      );
      if (session.masthead.isEmpty) {
        expect(
          await readerRepo.isMastheadAvailable(reader['masthead'] as String),
          isTrue,
        );
        session = await readerRepo.createProfile(reader['masthead'] as String);
      }
      expect(session.masthead, reader['masthead']);
      expect(
        await readerRepo.isMastheadAvailable(reader['masthead'] as String),
        isFalse,
      );
      final todaySource = TodayRemoteSource(readerHttp);
      final today = await todaySource.today();
      await todaySource.choose(today.candidates.first);
      expect((await todaySource.today()).selected, today.candidates.first);
      final magazine = MagazineRemoteSource(readerHttp),
          issue = IssueRemoteSource(readerHttp);
      expect(
        (await magazine.page(
          mine: false,
          masthead: owner['masthead'] as String,
        )).page.items.any((v) => v.id == issueId),
        isTrue,
      );
      expect(
        await magazine.subscribe(owner['masthead'] as String, true),
        isTrue,
      );
      expect(
        (await issue.setReaction(issueId, like: true, enabled: true)).liked,
        isTrue,
      );
      expect(
        (await issue.setReaction(issueId, like: false, enabled: true)).scrapped,
        isTrue,
      );
      final comment = 'live-${DateTime.now().microsecondsSinceEpoch}';
      await issue.addLine(issueId, comment);
      expect(
        (await issue.lines(issueId)).items.any((v) => v.text == comment),
        isTrue,
      );
      await expectLater(
        issue.ownerReactions(issueId),
        throwsA(isA<RuleFailure>().having((v) => v.code, 'code', 'FORBIDDEN')),
      );
      final ownStats = await IssueRemoteSource(
        ownerHttp,
      ).ownerReactions(issueId);
      expect(ownStats.likes, greaterThanOrEqualTo(1));
      expect(ownStats.lines, greaterThanOrEqualTo(1));
      expect(
        (await MagazineRemoteSource(
          ownerHttp,
        ).page(mine: true)).page.items.any((v) => v.id == issueId),
        isTrue,
      );
      final records = RecordsRemoteSource(readerHttp);
      final month = today.date.key.substring(0, 7);
      final before = await records.month(month);
      final day = today.date.addDays(-1);
      if (day.month == today.date.month &&
          before.remaining > 0 &&
          !before.days.any((v) => v.date == day)) {
        var restored = false;
        // 지난 날짜 후보 조회 API가 없어 서버 후보 검증을 통과하는 색만 저장한다.
        for (final color in EselPaint.values) {
          try {
            await records.restore(day, color);
            restored = true;
            break;
          } on RuleFailure catch (e) {
            if (e.code != 'COLOR_NOT_CANDIDATE') rethrow;
          }
        }
        expect(restored, isTrue);
        expect((await records.month(month)).remaining, before.remaining - 1);
        expect(
          (await records.month(
            month,
          )).days.any((v) => v.date == day && v.restored),
          isTrue,
        );
      }
      final monthData = await records.month(month);
      await readerRepo.logout();
      expect(await readerStorage.getTokens(), isNull);
      await readerRepo.loginWithEmail(
        reader['email'] as String,
        reader['password'] as String,
      );
      expect((await issue.issue(issueId)).liked, isTrue);
      expect((await issue.issue(issueId)).scrapped, isTrue);
      expect(
        (await magazine.page(
          mine: false,
          masthead: owner['masthead'] as String,
        )).subscribed,
        isTrue,
      );
      expect((await records.month(month)).remaining, monthData.remaining);
      expect((await todaySource.today()).published, isFalse);
      expect((await magazine.page(mine: true)).issueCount, 0);
      expect(ServiceDate.tryParse(today.date.key), isNotNull);
    },
    skip: fixturePath == null,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
