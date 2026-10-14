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
  Future<void> logout();
  Future<void> deleteAccount();
}
