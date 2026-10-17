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

void main() {
  late HttpServer server;
  late InMemorySessionStorage storage;
  late AppConfig config;
  late StandardHttpClient http;
  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    storage = InMemorySessionStorage();
    config = AppConfig(apiBaseUrl: 'http://127.0.0.1:${server.port}/api');
    http = StandardHttpClient(config: config, storage: storage);
  });
  tearDown(() async => server.close(force: true));
  AuthRepositoryImpl repository() => AuthRepositoryImpl(
    config: config,
    storage: storage,
    mockSource: AuthMockSource(),
    remoteSource: AuthRemoteSource(http),
  );
  Map<String, dynamic> session(String access, String refresh) => {
    'userId': 'real-user-id',
    'email': 'real@example.test',
    'masthead': null,
    'hasPublishedToday': false,
    'issueCount': 0,
    'accessToken': access,
    'refreshToken': refresh,
  };

  test(
    'default configuration uses server and preserves login errors without mock fallback',
    () async {
      expect(const AppConfig().isServer, isTrue);
      server.listen((req) async {
        req.response.statusCode = 401;
        req.response.write(
          jsonEncode({
            'error': {
              'code': 'WRONG_CREDENTIALS',
              'message': '비밀번호를 확인해 주세요.',
              'hint': '다시 입력해 주세요.',
            },
          }),
        );
        await req.response.close();
      });
      await expectLater(
        repository().loginWithEmail('real@example.test', 'wrong password'),
        throwsA(
          isA<AuthFailure>().having((e) => e.code, 'code', 'WRONG_CREDENTIALS'),
        ),
      );
      expect(await storage.getTokens(), isNull);
    },
  );
  test(
    'signup follows server DTO and a new repository restores using the saved refresh token',
    () async {
      final paths = <String>[];
      server.listen((req) async {
        final body = jsonDecode(await utf8.decoder.bind(req).join()) as Map;
        paths.add(req.uri.path);
        if (req.uri.path.endsWith('signup')) {
          expect(body.keys.toSet(), {'email', 'password'});
          req.response.statusCode = 201;
          req.response.write(jsonEncode(session('access-one', 'refresh-one')));
        } else {
          expect(body['refreshToken'], 'refresh-one');
          req.response.write(jsonEncode(session('access-two', 'refresh-two')));
        }
        await req.response.close();
      });
      final first = await repository().signupWithEmail(
        'real@example.test',
        'long password',
        'ignored',
      );
      expect(first.masthead, isEmpty);
      final restored = await repository().getCurrentSession();
      expect(restored?.userId, first.userId);
      expect((await storage.getTokens())?['refresh_token'], 'refresh-two');
      expect(paths, ['/api/auth/email/signup', '/api/auth/refresh']);
    },
  );
  test(
    'expired access refreshes once and retries the protected request',
    () async {
      await storage.saveTokens(accessToken: 'expired', refreshToken: 'refresh');
      var refreshCount = 0;
      server.listen((req) async {
        if (req.uri.path.endsWith('/auth/refresh')) {
          refreshCount++;
          req.response.write(jsonEncode(session('renewed', 'rotated')));
        } else if (req.headers.value(HttpHeaders.authorizationHeader) ==
            'Bearer expired') {
          req.response.statusCode = 401;
          req.response.write(
            jsonEncode({
              'error': {'code': 'TOKEN_EXPIRED', 'message': 'expired'},
            }),
          );
        } else {
          expect(
            req.headers.value(HttpHeaders.authorizationHeader),
            'Bearer renewed',
          );
          req.response.write(jsonEncode({'available': true}));
        }
        await req.response.close();
      });
      expect(await http.get('/mastheads/test/availability'), {
        'available': true,
      });
      expect(refreshCount, 1);
    },
  );
  test('masthead availability calls the protected server contract', () async {
    await storage.saveTokens(accessToken: 'access', refreshToken: 'refresh');
    server.listen((req) async {
      expect(req.method, 'GET');
      expect(req.uri.path, '/api/mastheads/taken/availability');
      expect(
        req.headers.value(HttpHeaders.authorizationHeader),
        'Bearer access',
      );
      req.response.write(
        jsonEncode({'masthead': 'taken', 'available': false}),
      );
      await req.response.close();
    });

    expect(await repository().isMastheadAvailable('taken'), isFalse);
  });
  test('logout refreshes an expired access token, then clears local tokens', () async {
    await storage.saveTokens(accessToken: 'expired', refreshToken: 'refresh');
    final paths = <String>[];
    server.listen((req) async {
      paths.add(req.uri.path);
      if (req.uri.path.endsWith('/auth/refresh')) {
        req.response.write(jsonEncode(session('renewed', 'rotated')));
      } else if (req.headers.value(HttpHeaders.authorizationHeader) ==
          'Bearer expired') {
        req.response.statusCode = 401;
        req.response.write(
          jsonEncode({
            'error': {'code': 'TOKEN_EXPIRED', 'message': 'expired'},
          }),
        );
      } else {
        expect(
          req.headers.value(HttpHeaders.authorizationHeader),
          'Bearer renewed',
        );
        req.response.statusCode = 204;
      }
      await req.response.close();
    });

    await repository().logout();

    expect(paths, [
      '/api/auth/logout',
      '/api/auth/refresh',
      '/api/auth/logout',
    ]);
    expect(await storage.getTokens(), isNull);
  });
  test(
    'unconfigured social auth never calls an API with a placeholder token',
    () async {
      await expectLater(
        repository().loginWithGoogle(),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.code,
            'code',
            'OAUTH_NOT_CONFIGURED',
          ),
        ),
      );
      await expectLater(
        repository().loginWithApple(),
        throwsA(isA<AuthFailure>()),
      );
      expect(await storage.getTokens(), isNull);
    },
  );
  test(
    'offline server remains a connection error, not a fake successful login',
    () async {
      await server.close(force: true);
      await expectLater(
        repository().loginWithEmail('dana@esel.app', 'esel1234'),
        throwsA(isA<NetworkFailure>()),
      );
      expect(await storage.getTokens(), isNull);
    },
  );
}
