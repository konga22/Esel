import 'service_date.dart';

/// 앱이 "지금"과 "오늘"을 묻는 단 하나의 시계. 화면과 규칙은 DateTime.now()를 직접 부르지 않는다.
/// 테스트와 시연은 [ManualServiceClock]으로 시간을 주입한다.
abstract class ServiceClock {
  const ServiceClock();

  DateTime now();

  /// 서울 기준 서비스 날짜.
  ServiceDate get today => ServiceDate.of(now());
}

class SystemServiceClock extends ServiceClock {
  const SystemServiceClock();

  @override
  DateTime now() => DateTime.now();
}

/// 손으로 움직이는 시계. 자정 경계 테스트에 쓴다.
class ManualServiceClock extends ServiceClock {
  DateTime _now;

  ManualServiceClock(DateTime now) : _now = now;

  @override
  DateTime now() => _now;

  void set(DateTime now) => _now = now;

  void advance(Duration duration) => _now = _now.add(duration);
}
