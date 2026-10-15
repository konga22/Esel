import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/config/app_config.dart';
import 'package:esel/core/storage/password_digest.dart';
import 'package:esel/core/storage/session_storage.dart';
import 'package:esel/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:esel/features/auth/data/sources/auth_mock_source.dart';
import 'package:esel/features/auth/data/sources/auth_remote_source.dart';
import 'package:esel/features/auth/data/sources/mock_account_store.dart';
import 'package:esel/core/network/http_client.dart';
import 'package:esel/features/auth/presentation/controllers/auth_controller.dart';

void main() {
  group('DEV-05 mock 계정과 로그인', () {
    late AuthController controller;
    late InMemoryMockAccountVault vault;

    AuthController build() {
      const config = AppConfig(apiMode: ApiMode.mock);
      final storage = InMemorySessionStorage();
      return AuthController(
        AuthRepositoryImpl(
          config: config,
          storage: storage,
          mockSource: AuthMockSource(accounts: MockAccountStore(vault)),
          remoteSource: AuthRemoteSource(
            StandardHttpClient(config: config, storage: storage),
          ),
        ),
      );
    }

    setUp(() {
      vault = InMemoryMockAccountVault();
      controller = build();
    });

    test('잘못된 이메일 형식은 로그인되지 않는다', () async {
      final ok = await controller.loginWithEmail('invalid-email', '12345678');
      expect(ok, isFalse);
      expect(controller.isAuthenticated, isFalse);
      expect(controller.errorMessage, isNotNull);
    });

    test('가입하지 않은 이메일은 로그인되지 않는다', () async {
      final ok = await controller.loginWithEmail('new@esel.local', 'esel1234');
      expect(ok, isFalse);
      expect(controller.errorMessage, contains('회원가입'));
    });

    test('가입은 8자 이상 비밀번호만, 같은 이메일은 한 번만', () async {
      expect(
        await controller.signupWithEmail('a@esel.local', 'short', ''),
        isFalse,
      );
      expect(
        await controller.signupWithEmail('a@esel.local', 'esel1234', ''),
        isTrue,
      );
      await controller.logout();
      expect(
        await controller.signupWithEmail('A@esel.local', 'other-pass', ''),
        isFalse,
      );
      expect(controller.errorMessage, contains('이미 가입한'));
    });

    test('같은 이메일에 다른 비밀번호를 넣으면 그 계정이 열리지 않는다', () async {
      await controller.signupWithEmail('dana@esel.app', 'esel1234', '');
      final userId = controller.currentSession!.userId;
      await controller.logout();

      expect(
        await controller.loginWithEmail('dana@esel.app', 'anything!'),
        isFalse,
      );
      expect(controller.isAuthenticated, isFalse);
      expect(controller.errorMessage, '비밀번호가 맞지 않아요. 다시 입력해 주세요.');

      expect(
        await controller.loginWithEmail('DANA@esel.app', 'esel1234'),
        isTrue,
      );
      expect(controller.currentSession!.userId, userId);
    });

    test('비밀번호는 저장하지 않고 솔트를 붙인 다이제스트만 둔다', () async {
      await controller.signupWithEmail('vault@esel.local', 'esel1234', '');
      final raw = await vault.read();
      expect(raw, isNot(contains('esel1234')));
      final saved = (jsonDecode(raw!) as List).single as Map;
      expect(
        PasswordDigest.matches(
          'esel1234',
          saved['salt'] as String,
          saved['digest'] as String,
        ),
        isTrue,
      );

      // 앱을 다시 켜도(새 컨트롤러) 같은 비밀번호로만 열린다.
      final reopened = build();
      expect(
        await reopened.loginWithEmail('vault@esel.local', 'nope1234'),
        isFalse,
      );
      expect(
        await reopened.loginWithEmail('vault@esel.local', 'esel1234'),
        isTrue,
      );
    });

    test('제호는 이메일에서 만들지 않는다. 창간 때 정한다(P14)', () async {
      await controller.signupWithEmail('x@esel.local', 'esel1234', '');
      expect(controller.currentSession!.masthead, isEmpty);
      expect(await controller.isMastheadAvailable('dana'), isFalse);
      expect(await controller.isMastheadAvailable('esel'), isFalse);
      expect(await controller.isMastheadAvailable('mymag'), isTrue);

      expect(await controller.createProfile('mymag'), isTrue);
      expect(controller.currentSession!.masthead, 'mymag');
      expect(await controller.isMastheadAvailable('mymag'), isFalse);
      // 한 번 창간한 계정의 제호는 이 흐름으로 바꾸지 않는다.
      expect(await controller.createProfile('other'), isFalse);

      await controller.logout();
      await controller.loginWithEmail('x@esel.local', 'esel1234');
      expect(controller.currentSession!.masthead, 'mymag');
    });

    test('Apple·Google 시연은 예시 인물이 아니라 이 기기의 시연 계정이다(P18)', () async {
      expect(await controller.loginWithApple(), isTrue);
      final apple = controller.currentSession!;
      expect(apple.userId, 'mock_apple');
      expect(apple.masthead, isEmpty);
      expect(apple.isMinor, isFalse);
      await controller.logout();
      expect(await controller.loginWithGoogle(), isTrue);
      expect(controller.currentSession!.userId, 'mock_google');
      expect(controller.currentSession!.masthead, isNot('dana'));
    });

    test('로그아웃하면 세션이 비워진다', () async {
      await controller.signupWithEmail('out@esel.local', 'esel1234', '');
      expect(controller.isAuthenticated, isTrue);
      await controller.logout();
      expect(controller.isAuthenticated, isFalse);
      expect(controller.currentSession, isNull);
    });

    test('계정 삭제는 기기 안 계정 기록을 지운다', () async {
      await controller.signupWithEmail('bye@esel.local', 'esel1234', '');
      await controller.deleteAccount();
      expect(controller.isAuthenticated, isFalse);
      expect(
        await controller.loginWithEmail('bye@esel.local', 'esel1234'),
        isFalse,
      );
    });
  });

  test('SHA-256 표준 벡터', () {
    String hex(List<int> bytes) =>
        bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    expect(
      hex(PasswordDigest.sha256(utf8.encode('abc'))),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
    expect(
      hex(PasswordDigest.sha256(const [])),
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    );
    expect(
      hex(
        PasswordDigest.sha256(
          utf8.encode(
            'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq',
          ),
        ),
      ),
      '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1',
    );
  });
}
