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

  // Apple·Google 로그인은 서버 약속(api-contract.json)에 없다. 도입 시점이
  // 정해지면 약속에 주소가 생긴 뒤 여기에 더한다. 그 전까지 서버 모드는
  // 저장소가 OAUTH_NOT_CONFIGURED로 막고, mock 모드는 기기 시연 계정을 쓴다.

  /// DEV-06 서버 계약: `{ masthead, available }`을 받는다.
  Future<bool> isMastheadAvailable(String masthead) async {
    final res = await httpClient.get('/mastheads/$masthead/availability');
    return res['available'] == true;
  }

  Future<void> logout() async {
    await httpClient.post('/auth/logout');
  }

  Future<void> deleteAccount() async {
    // 서버는 삭제 내용을 확인했다는 표시가 있어야 지운다(DeleteAccountDto).
    await httpClient.delete('/me', body: {'confirmed': true});
  }
}
