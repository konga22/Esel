import 'package:flutter_test/flutter_test.dart';
import 'package:esel/core/config/app_config.dart';
import 'package:esel/core/storage/session_storage.dart';
import 'package:esel/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:esel/features/auth/data/sources/auth_mock_source.dart';
import 'package:esel/features/auth/data/sources/auth_remote_source.dart';
import 'package:esel/core/network/http_client.dart';
import 'package:esel/features/auth/presentation/controllers/auth_controller.dart';

void main() {
  group('DEV-05 Auth Controller & Repository Tests', () {
    late AuthController controller;

    setUp(() {
      final config = const AppConfig(apiMode: ApiMode.mock);
      final storage = InMemorySessionStorage();
      final mockSource = AuthMockSource();
      final remoteSource = AuthRemoteSource(StandardHttpClient(config: config, storage: storage));
      final repo = AuthRepositoryImpl(
        config: config,
        storage: storage,
        mockSource: mockSource,
        remoteSource: remoteSource,
      );
      controller = AuthController(repo);
    });

    test('invalid email returns false and keeps unauthenticated', () async {
      final ok = await controller.loginWithEmail('invalid-email', '123456');
      expect(ok, isFalse);
      expect(controller.isAuthenticated, isFalse);
      expect(controller.errorMessage, isNotNull);
    });

    test('short password returns false and keeps unauthenticated', () async {
      final ok = await controller.loginWithEmail('dana@esel.app', '123');
      expect(ok, isFalse);
      expect(controller.isAuthenticated, isFalse);
    });

    test('valid email/password updates session and becomes authenticated', () async {
      final ok = await controller.loginWithEmail('dana@esel.app', 'esel1234');
      expect(ok, isTrue);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.currentSession?.email, equals('dana@esel.app'));
    });

    test('logout clears session and resets state', () async {
      await controller.loginWithEmail('dana@esel.app', 'esel1234');
      expect(controller.isAuthenticated, isTrue);

      await controller.logout();
      expect(controller.isAuthenticated, isFalse);
      expect(controller.currentSession, isNull);
    });
  });
}
