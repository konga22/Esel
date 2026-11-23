import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../data/profile_remote_source.dart';
import '../../domain/profile_bio.dart';

/// 서버 모드의 한 줄 소개 저장 상태. 앱이 켜져 있는 동안 마지막으로 저장한 소개를 기억한다.
/// 서버가 소개를 다시 읽어 줄 조회 API가 없어서, 앱을 다시 켜면 [bio]는 비어 있다.
class ProfileBioController extends ChangeNotifier {
  final ProfileBioSource source;
  ProfileBioController(this.source);

  String? _bio;
  bool _saving = false;
  String? _error;
  int _generation = 0;

  /// 이번 실행에서 서버에 저장된 소개. 저장한 적이 없으면 null.
  String? get bio => _bio;
  bool get isSaving => _saving;
  String? get errorMessage => _error;

  /// 성공하면 true. 규칙 위반은 서버로 보내지 않는다.
  Future<bool> save(String text) async {
    if (_saving) return false;
    final invalid = bioError(text);
    if (invalid != null) {
      _error = invalid;
      notifyListeners();
      return false;
    }
    final generation = _generation;
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await source.updateBio(text);
      if (generation != _generation) return false;
      _bio = saved;
      return true;
    } catch (failure) {
      if (generation != _generation) return false;
      _error = failure is Failure
          ? failure.message
          : '소개를 저장하지 못했어요. 다시 시도해 주세요.';
      return false;
    } finally {
      if (generation == _generation) {
        _saving = false;
        notifyListeners();
      }
    }
  }

  /// 로그아웃·계정 전환 때. 이전 계정의 소개와 대기 중인 응답을 버린다.
  void clear() {
    _generation++;
    _bio = null;
    _saving = false;
    _error = null;
    notifyListeners();
  }
}
