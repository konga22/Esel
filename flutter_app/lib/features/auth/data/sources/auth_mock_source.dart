import '../../../../core/errors/failures.dart';
import '../../../../core/mock/demo_people.dart';
import '../../../onboarding/domain/rules/masthead_rule.dart';
import '../../domain/models/auth_session.dart';
import 'mock_account_store.dart';

/// 시연(mock) 인증. 기기 안 계정([MockAccountStore])으로만 확인하고 서버에 보내지 않는다.
///
/// - 이메일 로그인은 가입한 계정만, 그 계정의 비밀번호가 맞을 때만 열린다.
/// - 제호는 이메일에서 만들지 않는다. 제호가 없는 계정은 창간 흐름으로 간다(P13·P14).
/// - Apple·Google 시연 버튼은 예시 인물이 아니라 이 기기의 시연 계정을 만든다.
class AuthMockSource {
  final MockAccountStore accounts;
  AuthSession? _currentSession;

  AuthMockSource({MockAccountStore? accounts})
    : accounts = accounts ?? MockAccountStore();

  AuthSession? get currentSession => _currentSession;

  static const int minPassword = 8;
  static const int maxPassword = 128;

  AuthSession _sessionFor(MockAccount account) {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return _currentSession = AuthSession(
      userId: account.userId,
      email: account.email,
      masthead: account.masthead,
      hasPublishedToday: false,
      issueCount: 0,
      isMinor: account.isMinor,
      accessToken: 'mock_access_$stamp',
      refreshToken: 'mock_refresh_$stamp',
    );
  }

  void _checkEmail(String email) {
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim())) {
      throw const AuthFailure(
        '이메일 형식이 맞지 않아요. 예: name@example.com',
        code: 'INVALID_EMAIL',
      );
    }
  }

  Future<AuthSession> loginWithEmail(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _checkEmail(email);
    final account = await accounts.find(email);
    if (account == null) {
      throw const AuthFailure(
        '이 기기에 가입한 이메일이 아니에요. 처음이라면 회원가입을 눌러 주세요.',
        code: 'ACCOUNT_NOT_FOUND',
      );
    }
    if (!accounts.verify(account, password)) {
      throw const AuthFailure(
        '비밀번호가 맞지 않아요. 다시 입력해 주세요.',
        code: 'WRONG_CREDENTIALS',
      );
    }
    return _sessionFor(account);
  }

  Future<AuthSession> signupWithEmail(
    String email,
    String password,
    String masthead,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _checkEmail(email);
    if (password.length < minPassword || password.length > maxPassword) {
      throw const AuthFailure('비밀번호는 8~128자로 정해 주세요.', code: 'WEAK_PASSWORD');
    }
    if (masthead.isNotEmpty && !MastheadRule.isValid(masthead)) {
      throw const AuthFailure(
        '제호는 영문 소문자 2~10자로 정해 주세요.',
        code: 'INVALID_MASTHEAD',
      );
    }
    if (masthead.isNotEmpty && await isMastheadTaken(masthead)) {
      throw const AuthFailure('이미 있는 제호예요.', code: 'MASTHEAD_TAKEN');
    }
    final account = await accounts.createWithPassword(
      email: email,
      password: password,
      masthead: masthead,
    );
    if (account == null) {
      throw const AuthFailure('이미 가입한 이메일이에요. 로그인해 주세요.', code: 'EMAIL_TAKEN');
    }
    return _sessionFor(account);
  }

  Future<AuthSession> loginWithGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _sessionFor(await accounts.social('google'));
  }

  Future<AuthSession> loginWithApple() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _sessionFor(await accounts.social('apple'));
  }

  /// 창간 때 제호를 정한다(P14). 이미 제호가 있는 계정은 바꾸지 않는다.
  Future<AuthSession> createProfile(String masthead) async {
    final session = _currentSession;
    if (session == null) throw const AuthFailure('로그인이 필요해요.');
    if (!MastheadRule.isValid(masthead)) {
      throw const AuthFailure(
        '제호는 영문 소문자 2~10자로 정해 주세요.',
        code: 'INVALID_MASTHEAD',
      );
    }
    final account = await accounts.findById(session.userId);
    if (account == null) throw const AuthFailure('다시 로그인해 주세요.');
    if (account.masthead.isNotEmpty) {
      throw const AuthFailure('이미 창간한 잡지가 있는 계정이에요.', code: 'PROFILE_EXISTS');
    }
    if (await isMastheadTaken(masthead)) {
      throw const AuthFailure('이미 있는 제호예요.', code: 'MASTHEAD_TAKEN');
    }
    return _sessionFor(
      await accounts.update(account.copyWith(masthead: masthead)),
    );
  }

  /// 시연의 중복 검사: 예시 인물과 이 기기의 다른 계정 제호, 앱 이름.
  Future<bool> isMastheadTaken(String masthead) async {
    if (masthead == 'esel' || demoPersonNamed(masthead) != null) return true;
    return (await accounts.findByMasthead(masthead)) != null;
  }

  Future<void> logout() async {
    _currentSession = null;
  }

  /// 기기 안 계정 기록을 지운다. 기기 보관함의 호·사진은 앱이 따로 지운다.
  Future<void> deleteAccount() async {
    final session = _currentSession;
    if (session != null) await accounts.delete(session.userId);
    _currentSession = null;
  }
}
