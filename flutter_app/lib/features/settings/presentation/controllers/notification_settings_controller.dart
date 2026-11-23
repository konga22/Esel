import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../data/notification_settings_source.dart';
import '../../domain/notification_settings.dart';

/// 알림 설정 화면 상태. 설정 화면이 열려 있는 동안만 산다(계정이 바뀌면 화면이 새로 만들어진다).
/// 서버가 답하기 전에는 스위치를 바꾼 것으로 보이지 않고, 저장 중에는 다음 변경을 받지 않는다.
class NotificationSettingsController extends ChangeNotifier {
  final NotificationSettingsSource source;
  NotificationSettingsController(this.source);

  NotificationSettings? _settings;
  bool _loading = false, _saving = false, _disposed = false;
  String? _loadError, _saveError;

  NotificationSettings? get settings => _settings;
  bool get isLoading => _loading;
  bool get isSaving => _saving;
  String? get loadError => _loadError;
  String? get saveError => _saveError;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _loadError = null;
    _notify();
    try {
      _settings = await source.load();
    } catch (failure) {
      _loadError = _message(failure, '알림 설정을 불러오지 못했어요. 다시 시도해 주세요.');
    }
    _loading = false;
    _notify();
  }

  Future<void> update(NotificationSettings next) async {
    if (_saving || _settings == null) return;
    _saving = true;
    _saveError = null;
    _notify();
    try {
      _settings = await source.save(next);
    } catch (failure) {
      // 이전 값을 그대로 둔다.
      _saveError = _message(failure, '알림 설정을 저장하지 못했어요. 다시 시도해 주세요.');
    }
    _saving = false;
    _notify();
  }

  String _message(Object failure, String fallback) =>
      failure is Failure ? failure.message : fallback;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
