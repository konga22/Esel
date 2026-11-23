import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/config/app_config.dart';
import 'package:esel/core/errors/failures.dart';
import 'package:esel/core/network/http_client.dart';
import 'package:esel/core/storage/session_storage.dart';
import 'package:esel/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:esel/features/auth/data/sources/auth_mock_source.dart';
import 'package:esel/features/auth/data/sources/auth_remote_source.dart';
import 'package:esel/features/auth/data/sources/mock_account_store.dart';
import 'package:esel/features/auth/presentation/controllers/auth_controller.dart';
import 'package:esel/features/settings/data/profile_remote_source.dart';
import 'package:esel/features/settings/domain/profile_bio.dart';
import 'package:esel/features/settings/presentation/controllers/profile_bio_controller.dart';
import 'package:esel/features/settings/presentation/screens/settings_screen.dart';
import '../server/core_api_widgets_test.dart' show ScreenHttp;

/// DEV-19 프로필 수정: 한 줄 소개만 PATCH /me/profile로 저장한다.
/// 사인 변경은 정책 미정이라 잠가 둔다(2026-11-23 사용자 결정).
/// 서버에 소개를 다시 읽는 조회 API가 없어 서버는 바꾸지 않는다(같은 날 사용자 결정).
void main() {
  group('소개 규칙', () {
    test('80자(서버와 같은 UTF-16 길이)까지만, 앞뒤 공백은 빼고 센다', () {
      expect(bioError('가' * 80), isNull);
      expect(bioError('가' * 81), isNotNull);
      expect(bioError('  ${'a' * 80}  '), isNull);
      // 이모지 하나는 UTF-16 두 칸이다. 서버(class-validator)와 같은 기준으로 센다.
      expect(bioError('😀' * 40), isNull);
      expect(bioError('😀' * 41), isNotNull);
    });

    test('서버가 준 소개가 없으면 이번 실행에서 저장한 소개를 보인다', () {
      expect(shownBio(fromServer: '', savedThisSession: '새 소개'), '새 소개');
      expect(shownBio(fromServer: '서버 소개', savedThisSession: '새 소개'), '서버 소개');
      expect(shownBio(fromServer: '', savedThisSession: null), '');
    });
  });

  test('PATCH /me/profile은 소개만 보내고 사인은 보내지 않는다', () async {
    final bodies = <Map<String, dynamic>?>[];
    final http = ScreenHttp((method, path, body) async {
      expect('$method $path', 'PATCH /me/profile');
      bodies.add(body);
      return {
        'id': 'profile-id',
        'masthead': 'selin',
        'bio': (body!['bio'] as String).trim(),
        'issueCount': 3,
      };
    });
    final saved = await ProfileRemoteSource(http).updateBio('  옷으로 남기는 계절  ');
    expect(bodies.single, {'bio': '옷으로 남기는 계절'});
    expect(saved, '옷으로 남기는 계절');
  });

  group('설정 화면 · 프로필 편집(S2)', () {
    AuthController auth() {
      const config = AppConfig(apiMode: ApiMode.mock);
      final storage = InMemorySessionStorage();
      return AuthController(
        AuthRepositoryImpl(
          config: config,
          storage: storage,
          mockSource: AuthMockSource(
            accounts: MockAccountStore(InMemoryMockAccountVault()),
          ),
          remoteSource: AuthRemoteSource(
            StandardHttpClient(config: config, storage: storage),
          ),
        ),
      );
    }

    Future<void> openProfile(
      WidgetTester tester, {
      ProfileBioController? bio,
    }) async {
      final controller = auth();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            authController: controller,
            profileBio: bio,
            openProfile: true,
            onBack: () {},
            onLogoutComplete: () {},
            onDeleteComplete: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    TextField field(WidgetTester tester, String key) =>
        tester.widget<TextField>(find.byKey(ValueKey(key)));

    testWidgets('서버 모드: 사인은 잠겨 있고 소개는 써서 저장할 수 있다', (tester) async {
      final posted = <String>[];
      final bio = ProfileBioController(
        _FakeProfile((text) async {
          posted.add(text);
          return text.trim();
        }),
      );
      addTearDown(bio.dispose);
      await openProfile(tester, bio: bio);
      expect(field(tester, 'profile-masthead').enabled, isFalse);
      expect(field(tester, 'profile-bio').enabled, isTrue);
      // 서버가 소개를 다시 주지 않는다는 한계를 숨기지 않는다.
      expect(find.textContaining('다시 불러오지 못해요'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('profile-bio')),
        '계절을 입어요',
      );
      await tester.tap(find.byKey(const ValueKey('profile-save')));
      await tester.pumpAndSettle();
      expect(posted, ['계절을 입어요']);
      expect(bio.bio, '계절을 입어요');
      expect(find.text('소개를 저장했어요.'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('profile-save'))).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('80자를 넘으면 보내지 않고 이유를 알린다', (tester) async {
      final posted = <String>[];
      final bio = ProfileBioController(
        _FakeProfile((text) async {
          posted.add(text);
          return text;
        }),
      );
      addTearDown(bio.dispose);
      await openProfile(tester, bio: bio);
      await tester.enterText(
        find.byKey(const ValueKey('profile-bio')),
        '가' * 81,
      );
      await tester.tap(find.byKey(const ValueKey('profile-save')));
      await tester.pumpAndSettle();
      expect(posted, isEmpty);
      expect(find.text('소개는 80자까지 쓸 수 있어요.'), findsOneWidget);
    });

    testWidgets('저장하는 동안 버튼을 막고, 실패하면 쓴 글을 지우지 않는다', (tester) async {
      final gate = Completer<void>();
      final bio = ProfileBioController(
        _FakeProfile((_) async {
          await gate.future;
          throw const NetworkFailure('서버에 연결하지 못했어요. 연결을 확인해 주세요.');
        }),
      );
      addTearDown(bio.dispose);
      await openProfile(tester, bio: bio);
      await tester.enterText(find.byKey(const ValueKey('profile-bio')), '남길 글');
      await tester.tap(find.byKey(const ValueKey('profile-save')));
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('profile-save')))
            .onPressed,
        isNull,
      );
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('서버에 연결하지 못했어요. 연결을 확인해 주세요.'), findsOneWidget);
      expect(field(tester, 'profile-bio').controller!.text, '남길 글');
      expect(bio.bio, isNull);
    });

    testWidgets('mock 모드(소개 저장소 없음)는 기존처럼 소개 칸이 잠겨 있다', (tester) async {
      await openProfile(tester);
      expect(field(tester, 'profile-bio').enabled, isFalse);
      expect(find.byKey(const ValueKey('profile-save')), findsNothing);
    });
  });

  test('계정이 바뀌면 이전 계정의 소개와 늦게 온 응답을 버린다', () async {
    final gate = Completer<void>();
    final bio = ProfileBioController(
      _FakeProfile((text) async {
        await gate.future;
        return text;
      }),
    );
    addTearDown(bio.dispose);
    final saving = bio.save('이전 계정 소개');
    bio.clear();
    gate.complete();
    await saving;
    expect(bio.bio, isNull);
  });
}

class _FakeProfile implements ProfileBioSource {
  final Future<String> Function(String) onSave;
  _FakeProfile(this.onSave);
  @override
  Future<String> updateBio(String bio) => onSave(bio);
}
