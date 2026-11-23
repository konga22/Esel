import '../../../core/network/http_client.dart';
import '../domain/notification_settings.dart';

/// 알림 설정을 읽고 저장하는 곳. `ESEL_API_MODE`에 따라 서버 또는 앱 메모리를 쓴다.
abstract class NotificationSettingsSource {
  Future<NotificationSettings> load();

  /// 저장한 뒤 서버가 확정한 값을 돌려준다. 화면은 이 값으로만 바꾼다.
  Future<NotificationSettings> save(NotificationSettings next);
}

/// 서버 모드: `GET`·`PUT /me/notifications`. PUT은 세 값을 모두 보낸다(서버 DTO가 셋 다 필수).
class NotificationSettingsRemoteSource implements NotificationSettingsSource {
  final AppHttpClient http;
  NotificationSettingsRemoteSource(this.http);

  @override
  Future<NotificationSettings> load() async =>
      NotificationSettings.fromJson(await http.get('/me/notifications'));

  @override
  Future<NotificationSettings> save(NotificationSettings next) async =>
      NotificationSettings.fromJson(
        await http.put('/me/notifications', body: next.toJson()),
      );
}

/// mock 모드: 앱이 켜져 있는 동안 메모리에만 둔다. 기기에 저장하거나 서버로 보내지 않는다.
class NotificationSettingsMemorySource implements NotificationSettingsSource {
  NotificationSettings _value = const NotificationSettings.defaults();

  @override
  Future<NotificationSettings> load() async => _value;

  @override
  Future<NotificationSettings> save(NotificationSettings next) async =>
      _value = next;
}
