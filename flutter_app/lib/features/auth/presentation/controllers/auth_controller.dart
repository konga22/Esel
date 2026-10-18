import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/models/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository _repository;

  AuthController(this._repository);

  AuthSession? _currentSession;
  bool _isLoading = false;
  String? _errorMessage;
  String? _pendingDestination; // 로그인 성공 후 이동할 목적지

  AuthSession? get currentSession => _currentSession;
  bool get isAuthenticated => _currentSession != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get pendingDestination => _pendingDestination;

  Future<void> restoreSession() async {
    try {
      _currentSession = await _repository.getCurrentSession();
    } on Failure catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '로그인 정보를 불러오지 못했어요. 다시 로그인해 주세요.';
    }
    notifyListeners();
  }

  void setPendingDestination(String? destination) {
    _pendingDestination = destination;
  }

  Future<bool> createProfile(String masthead) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _currentSession = await _repository.createProfile(masthead);
      return true;
    } on Failure catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '사인을 저장하지 못했어요. 다시 시도해 주세요.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 첫 캔버스 사인이 쓸 수 있는지. 확인하지 못하면 null.
  Future<bool?> isMastheadAvailable(String masthead) async {
    try {
      return await _repository.isMastheadAvailable(masthead);
    } catch (_) {
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> loginWithEmail(String email, String password) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentSession = await _repository.loginWithEmail(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on Failure catch (f) {
      _errorMessage = f.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = '로그인 중 오류가 발생했습니다. 다시 시도해 주세요.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signupWithEmail(
    String email,
    String password,
    String masthead,
  ) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentSession = await _repository.signupWithEmail(
        email,
        password,
        masthead,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on Failure catch (f) {
      _errorMessage = f.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = '회원가입 중 오류가 발생했습니다. 다시 시도해 주세요.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentSession = await _repository.loginWithGoogle();
      _isLoading = false;
      notifyListeners();
      return true;
    } on Failure catch (f) {
      _errorMessage = f.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Google 로그인 중 오류가 발생했습니다.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithApple() async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentSession = await _repository.loginWithApple();
      _isLoading = false;
      notifyListeners();
      return true;
    } on Failure catch (f) {
      _errorMessage = f.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Apple 로그인 중 오류가 발생했습니다.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.logout();
      _currentSession = null;
      _pendingDestination = null;
    } on Failure catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '로그아웃하지 못했어요. 다시 시도해 주세요.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccount() async {
    _isLoading = true;
    notifyListeners();
    await _repository.deleteAccount();
    _currentSession = null;
    _pendingDestination = null;
    _isLoading = false;
    notifyListeners();
  }

  void updateSession(AuthSession session) {
    _currentSession = session;
    notifyListeners();
  }
}
