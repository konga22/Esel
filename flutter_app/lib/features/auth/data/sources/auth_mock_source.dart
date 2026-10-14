import '../../../../core/errors/failures.dart';
import '../../domain/models/auth_session.dart';

class AuthMockSource {
  AuthSession? _currentSession;

  AuthSession? get currentSession => _currentSession;

  Future<AuthSession> loginWithEmail(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final trimmedEmail = email.trim();
    if (!trimmedEmail.contains('@') || !trimmedEmail.contains('.')) {
      throw const AuthFailure('올바른 이메일 형식을 입력해 주세요.', code: 'INVALID_EMAIL');
    }
    if (password.length < 6) {
      throw const AuthFailure('비밀번호는 6자리 이상이어야 합니다.', code: 'INVALID_PASSWORD');
    }

    final masthead = trimmedEmail
        .split('@')
        .first
        .replaceAll(RegExp(r'[^a-zA-Z]'), '')
        .toLowerCase();
    final validMasthead = masthead.length < 2
        ? 'selin'
        : masthead.substring(0, masthead.length.clamp(2, 10));

    _currentSession = AuthSession(
      userId: 'mock_${trimmedEmail.toLowerCase()}',
      email: trimmedEmail,
      masthead: validMasthead,
      hasPublishedToday: false,
      issueCount: 0,
      accessToken: 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken:
          'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
    );
    return _currentSession!;
  }

  Future<AuthSession> signupWithEmail(
    String email,
    String password,
    String masthead,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final trimmedEmail = email.trim();
    if (!trimmedEmail.contains('@') || !trimmedEmail.contains('.')) {
      throw const AuthFailure('올바른 이메일 형식을 입력해 주세요.', code: 'INVALID_EMAIL');
    }
    if (password.length < 6) {
      throw const AuthFailure('비밀번호는 6자리 이상이어야 합니다.', code: 'WEAK_PASSWORD');
    }
    if (masthead.isNotEmpty && !RegExp(r'^[a-z]{2,10}$').hasMatch(masthead)) {
      throw const AuthFailure('제호는 영문 2자 이상이어야 합니다.', code: 'INVALID_MASTHEAD');
    }

    _currentSession = AuthSession(
      userId: 'mock_${trimmedEmail.toLowerCase()}',
      email: trimmedEmail,
      masthead: masthead.isEmpty
          ? _localMasthead(trimmedEmail)
          : masthead.trim().toLowerCase(),
      hasPublishedToday: false,
      issueCount: 0,
      accessToken: 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken:
          'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
    );
    return _currentSession!;
  }

  Future<AuthSession> loginWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 350));
    _currentSession = AuthSession(
      userId: 'google_mock_user',
      email: 'dana.google@esel.app',
      masthead: 'dana',
      hasPublishedToday: false,
      issueCount: 1,
      accessToken: 'mock_google_token',
      refreshToken: 'mock_google_refresh',
    );
    return _currentSession!;
  }

  Future<AuthSession> loginWithApple() async {
    await Future.delayed(const Duration(milliseconds: 350));
    _currentSession = AuthSession(
      userId: 'apple_mock_user',
      email: 'dana.apple@privaterelay.appleid.com',
      masthead: 'dana',
      hasPublishedToday: false,
      issueCount: 1,
      accessToken: 'mock_apple_token',
      refreshToken: 'mock_apple_refresh',
    );
    return _currentSession!;
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _currentSession = null;
  }

  Future<void> deleteAccount() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentSession = null;
  }

  void updateSession(AuthSession session) {
    _currentSession = session;
  }

  String _localMasthead(String email) {
    final name = email
        .split('@')
        .first
        .toLowerCase()
        .replaceAll(RegExp('[^a-z]'), '');
    return name.length < 2
        ? 'selin'
        : name.substring(0, name.length.clamp(2, 10));
  }
}
