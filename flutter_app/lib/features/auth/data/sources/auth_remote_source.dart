import '../../../../core/network/http_client.dart';
import '../../domain/models/auth_session.dart';

class AuthRemoteSource {
  final AppHttpClient httpClient;

  AuthRemoteSource(this.httpClient);

  Future<AuthSession> loginWithEmail(String email, String password) async {
    final res = await httpClient.post(
      '/auth/email/login',
      body: {'email': email, 'password': password},
    );
    return AuthSession.fromJson(res);
  }

  Future<AuthSession> signupWithEmail(
    String email,
    String password,
    String masthead,
  ) async {
    final res = await httpClient.post(
      '/auth/email/signup',
      body: {'email': email, 'password': password},
    );
    return AuthSession.fromJson(res);
  }

  Future<AuthSession> refresh(String refreshToken) async {
    return AuthSession.fromJson(
      await httpClient.post(
        '/auth/refresh',
        body: {'refreshToken': refreshToken},
      ),
    );
  }

  Future<AuthSession> loginWithGoogle(String idToken) async {
    final res = await httpClient.post(
      '/auth/google',
      body: {'idToken': idToken},
    );
    return AuthSession.fromJson(res);
  }

  Future<AuthSession> loginWithApple(String authorizationCode) async {
    final res = await httpClient.post(
      '/auth/apple',
      body: {'authorizationCode': authorizationCode},
    );
    return AuthSession.fromJson(res);
  }

  /// DEV-06 서버 계약: `{ masthead, available }`을 받는다.
  Future<bool> isMastheadAvailable(String masthead) async {
    final res = await httpClient.get('/mastheads/$masthead/availability');
    return res['available'] == true;
  }

  Future<void> logout() async {
    await httpClient.post('/auth/logout');
  }

  Future<void> deleteAccount() async {
    await httpClient.delete('/me');
  }
}
