import '../models/auth_session.dart';

abstract class AuthRepository {
  Future<AuthSession?> getCurrentSession();
  Future<AuthSession> loginWithEmail(String email, String password);
  Future<AuthSession> signupWithEmail(
    String email,
    String password,
    String masthead,
  );
  Future<AuthSession> loginWithGoogle();
  Future<AuthSession> loginWithApple();
  Future<AuthSession> createProfile(String masthead);

  /// 제호 중복 확인(P14). mock은 예시 인물과 이 기기의 계정만 본다.
  Future<bool> isMastheadAvailable(String masthead);
  Future<void> logout();
  Future<void> deleteAccount();
}
