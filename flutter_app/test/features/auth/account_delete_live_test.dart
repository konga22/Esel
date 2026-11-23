import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/config/app_config.dart';
import 'package:esel/core/errors/failures.dart';
import 'package:esel/core/network/http_client.dart';
import 'package:esel/core/storage/session_storage.dart';
import 'package:esel/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:esel/features/auth/data/sources/auth_mock_source.dart';
import 'package:esel/features/auth/data/sources/auth_remote_source.dart';
import 'package:esel/features/issue/data/sources/issue_remote_source.dart';
import 'package:esel/features/magazine/data/sources/magazine_remote_source.dart';
import 'package:esel/features/magazine/data/sources/scraps_remote_source.dart';

/// DEV-19 탈퇴(DELETE /me)를 앱의 실제 탈퇴 코드로 로컬 서버에서 확인한다.
/// 로컬 Docker 전용이고, CI와 일반 `flutter test`에서는 건너뛴다.
///
/// PowerShell(저장소 루트):
///   $env:ESEL_DELETE_FIXTURE = node flutter_app/tool/prepare_account_delete_fixture.mjs
///   cd flutter_app; flutter test --no-pub test/features/auth/account_delete_live_test.dart
///
/// 준비 도구가 만든 새 테스트 계정 하나(탈퇴자)만 지운다. 다른 계정과 기존 데이터는 건드리지 않는다.
void main() {
  final fixturePath = Platform.environment['ESEL_DELETE_FIXTURE'];
  test(
    'Docker API: 앱 탈퇴는 계정·캔버스·반응을 지우고 다시 로그인할 수 없게 한다',
    () async {
      final fixture =
          jsonDecode(
                (await File(fixturePath!).readAsString()).replaceFirst('﻿', ''),
              )
              as Map;
      final config = AppConfig(apiBaseUrl: fixture['baseUrl'] as String);
      if (Uri.parse(config.apiBaseUrl).host != '127.0.0.1') {
        throw StateError('Local Docker only');
      }
      final victim = fixture['victim'] as Map, other = fixture['other'] as Map;
      final issueId = fixture['issueId'] as String;
      final mediaId = fixture['mediaId'] as String;

      ({
        AuthRepositoryImpl repo,
        StandardHttpClient http,
        InMemorySessionStorage storage,
      })
      client() {
        final storage = InMemorySessionStorage();
        final http = StandardHttpClient(config: config, storage: storage);
        return (
          repo: AuthRepositoryImpl(
            config: config,
            storage: storage,
            mockSource: AuthMockSource(),
            remoteSource: AuthRemoteSource(http),
          ),
          http: http,
          storage: storage,
        );
      }

      final mine = client(), theirs = client();
      await mine.repo.loginWithEmail(
        victim['email'] as String,
        victim['password'] as String,
      );
      await theirs.repo.loginWithEmail(
        other['email'] as String,
        other['password'] as String,
      );

      // 탈퇴 전: 다른 사람이 탈퇴자의 캔버스를 보고, 저장해 두었다.
      final issues = IssueRemoteSource(theirs.http);
      expect((await issues.issue(issueId)).masthead, victim['masthead']);
      expect(
        (await ScrapsRemoteSource(
          theirs.http,
        ).page()).items.any((v) => v.id == issueId),
        isTrue,
      );
      expect(
        await theirs.repo.isMastheadAvailable(victim['masthead'] as String),
        isFalse,
      );

      // 앱의 탈퇴 경로: DELETE /me {confirmed: true} → 기기 토큰 삭제.
      await mine.repo.deleteAccount();
      expect(await mine.storage.getTokens(), isNull);

      // 같은 이메일·비밀번호로는 다시 로그인할 수 없다.
      await expectLater(
        client().repo.loginWithEmail(
          victim['email'] as String,
          victim['password'] as String,
        ),
        throwsA(
          isA<AuthFailure>().having((e) => e.code, 'code', 'WRONG_CREDENTIALS'),
        ),
      );

      // 다른 사람 화면에서 캔버스·스케치북·사진·저장함 항목이 사라진다.
      await expectLater(issues.issue(issueId), throwsA(isA<NotFoundFailure>()));
      await expectLater(
        MagazineRemoteSource(
          theirs.http,
        ).page(mine: false, masthead: victim['masthead'] as String),
        throwsA(isA<NotFoundFailure>()),
      );
      await expectLater(
        theirs.http.getBytes(
          '/media/${Uri.encodeComponent(mediaId)}',
          queryParams: {'size': 'thumb'},
        ),
        throwsA(isA<NotFoundFailure>()),
      );
      expect(
        (await ScrapsRemoteSource(
          theirs.http,
        ).page()).items.any((v) => v.id == issueId),
        isFalse,
      );

      // 탈퇴자의 사인은 다시 쓸 수 있다(프로필이 지워졌다).
      expect(
        await theirs.repo.isMastheadAvailable(victim['masthead'] as String),
        isTrue,
      );
    },
    skip: fixturePath == null,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
