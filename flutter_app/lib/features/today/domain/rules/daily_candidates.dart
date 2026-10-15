import '../../../../core/design/tokens.g.dart';
import '../../../../core/time/service_date.dart';

/// P17 오늘의 색 후보 3가지(12색 중).
class DailyCandidates {
  static const int count = 3;

  /// 창간 시안의 후보(카멜·라일락·올리브)를 한곳에 모았다. 날짜별 후보는 아직 없다.
  static List<EselPaint> forDate(ServiceDate date) => const [
    EselPaint.camel,
    EselPaint.lilac,
    EselPaint.olive,
  ];
}
