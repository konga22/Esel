import '../../../../core/config/app_config.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/storage/session_storage.dart';
import '../../domain/models/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../sources/auth_mock_source.dart';
import '../sources/auth_remote_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AppConfig config;
  final SessionStorage storage;
  final AuthMockSource mockSource;
  final AuthRemoteSource remoteSource;

  AuthRepositoryImpl({
    required this.config,
    required this.storage,
    required this.mockSource,
    required this.remoteSource,
  });

  @override
  Future<AuthSession?> getCurrentSession() async {
    if (config.isMock) {
      return mockSource.currentSession;
    }
    final tokens = await storage.getTokens();
    if (tokens == null) return null;
    try {
      final session = await remoteSource.refresh(tokens['refresh_token']!);
      await storage.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      return session;
    } on AuthFailure {
      await storage.clear();
      return null;
    }
  }

  @override
  Future<AuthSession> loginWithEmail(String email, String password) async {
    final session = config.isMock
        ? await mockSource.loginWithEmail(email, password)
        : await remoteSource.loginWithEmail(email, password);

    await storage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session;
  }

  @override
  Future<AuthSession> signupWithEmail(
    String email,
    String password,
    String masthead,
  ) async {
    final session = config.isMock
        ? await mockSource.signupWithEmail(email, password, masthead)
        : await remoteSource.signupWithEmail(email, password, masthead);

    await storage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session;
  }

  @override
  Future<AuthSession> loginWithGoogle() async {
    if (config.isServer) {
      throw const AuthFailure(
        'Google 로그인은 연결 설정을 준비 중이에요. 이메일로 로그인해 주세요.',
        code: 'OAUTH_NOT_CONFIGURED',
      );
    }
    final session = config.isMock
        ? await mockSource.loginWithGoogle()
        : throw StateError('OAuth configuration required');

    await storage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session;
  }

  @override
  Future<AuthSession> loginWithApple() async {
    if (config.isServer) {
      throw const AuthFailure(
        'Apple 로그인은 연결 설정을 준비 중이에요. 이메일로 로그인해 주세요.',
        code: 'OAUTH_NOT_CONFIGURED',
      );
    }
    final session = config.isMock
        ? await mockSource.loginWithApple()
        : throw StateError('OAuth configuration required');

    await storage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session;
  }

  @override
  Future<bool> isMastheadAvailable(String masthead) async {
    if (config.isMock) return !await mockSource.isMastheadTaken(masthead);
    return remoteSource.isMastheadAvailable(masthead);
  }

  @override
  Future<AuthSession> createProfile(String masthead) async {
    if (config.isMock) return mockSource.createProfile(masthead);
    await remoteSource.httpClient.post(
      '/profile',
      body: {'masthead': masthead},
    );
    final session = await getCurrentSession();
    if (session == null) throw const AuthFailure('다시 로그인해 주세요.');
    return session;
  }

  @override
  Future<void> logout() async {
    if (config.isMock) {
      await mockSource.logout();
    } else {
      await remoteSource.logout();
    }
    await storage.clear();
  }

  @override
  Future<void> deleteAccount() async {
    if (config.isMock) {
      await mockSource.deleteAccount();
    } else {
      await remoteSource.deleteAccount();
    }
    await storage.clear();
  }
}
