/// 서비스 날짜. 하루 한 호(P04), 같은 색 잠금(P01), 오늘의 색 후보(P17)가 모두 이 날짜를 쓴다.
///
/// 기준 시간대는 Asia/Seoul(`AppConfig.serviceTimeZone`)이다. 서울은 1988년 이후 일광 절약
/// 시간이 없어서 시간대 패키지 없이 UTC+9로 계산한다. 기기 현지 시간대는 쓰지 않는다.
class ServiceDate implements Comparable<ServiceDate> {
  static const Duration seoulOffset = Duration(hours: 9);
  static const List<String> _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  final int year;
  final int month;
  final int day;

  const ServiceDate(this.year, this.month, this.day);

  /// 이 순간이 서울에서 며칠인지.
  factory ServiceDate.of(DateTime instant) {
    final seoul = instant.toUtc().add(seoulOffset);
    return ServiceDate(seoul.year, seoul.month, seoul.day);
  }

  /// `2026-09-06` 형식만 받는다. 달력에 없는 날짜(2월 30일 등)는 null.
  static ServiceDate? tryParse(String? key) {
    if (key == null) return null;
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(key);
    if (match == null) return null;
    final date = ServiceDate(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
    );
    final normalized = DateTime.utc(date.year, date.month, date.day);
    if (normalized.month != date.month || normalized.day != date.day) {
      return null;
    }
    return date;
  }

  /// 저장·비교용 키. `2026-09-06`.
  String get key =>
      '${year.toString().padLeft(4, '0')}-${_two(month)}-${_two(day)}';

  /// 화면 표기. `2026. 9. 6.`
  String get label => '$year. $month. $day.';

  /// 연도 없는 표기. `9. 6.`
  String get shortLabel => '$month. $day.';

  /// `일요일`
  String get weekdayLabel =>
      '${_weekdays[DateTime.utc(year, month, day).weekday - 1]}요일';

  /// 그해 몇 번째 날인지(1월 1일 = 1).
  int get dayOfYear =>
      DateTime.utc(year, month, day).difference(DateTime.utc(year)).inDays + 1;

  /// 이 날짜가 시작되는 순간(서울 자정)과 다음 날이 시작되는 순간.
  DateTime get startsAt => DateTime.utc(year, month, day).subtract(seoulOffset);
  DateTime get endsAt =>
      DateTime.utc(year, month, day + 1).subtract(seoulOffset);

  ServiceDate addDays(int days) {
    final moved = DateTime.utc(year, month, day + days);
    return ServiceDate(moved.year, moved.month, moved.day);
  }

  bool isBefore(ServiceDate other) => compareTo(other) < 0;
  bool isAfter(ServiceDate other) => compareTo(other) > 0;

  @override
  int compareTo(ServiceDate other) => key.compareTo(other.key);

  @override
  bool operator ==(Object other) =>
      other is ServiceDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => key;

  static String _two(int value) => value.toString().padLeft(2, '0');
}

/// 지면 머리의 시각 표기(서울 기준, `오전 8:12`).
String seoulTimeLabel(DateTime instant) {
  final seoul = instant.toUtc().add(ServiceDate.seoulOffset);
  final half = seoul.hour < 12 ? '오전' : '오후';
  final hour = seoul.hour % 12 == 0 ? 12 : seoul.hour % 12;
  return '$half $hour:${seoul.minute.toString().padLeft(2, '0')}';
}
