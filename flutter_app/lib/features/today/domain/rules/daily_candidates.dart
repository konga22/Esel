import '../../../../core/design/tokens.g.dart';
import '../../../../core/time/service_date.dart';

/// P17 오늘의 색 후보: 12색 중 하루 3가지(`harness.json.dailyCandidates`).
///
/// 실제 배정 방식(확률·시차·공급처)은 아직 정하지 않았다(하네스 §2 미확정). 시연(mock)은
/// 서비스 날짜만으로 정해지는 결정적 함수로 고른다. 같은 날은 몇 번을 열어도, 누가 열어도
/// 같은 3색이다(로그인 전 첫 캔버스에서 고른 색이 가입 뒤에도 후보로 남는다). 트윈의 "각자 추천
/// 3개"(P08)는 개인 색과 독립이라 이 함수를 쓰지 않는다. 결제·가입 기간 같은 값은 입력으로
/// 받지 않는다(P05).
class DailyCandidates {
  static const int count = 3;

  /// 디자인 시안의 날짜. 이날은 시안과 같은 카멜·라일락·올리브를 준다.
  static const ServiceDate demoDate = ServiceDate(2026, 9, 6);
  static const List<EselPaint> demoCandidates = [
    EselPaint.camel,
    EselPaint.lilac,
    EselPaint.olive,
  ];

  static const int _modulus = 2147483647; // 2^31 - 1

  static List<EselPaint> forDate(ServiceDate date) {
    if (date == demoDate) return demoCandidates;
    // 웹(JS 숫자)에서도 같은 결과가 나오도록 2^53 안에서만 곱한다.
    var state = 1;
    for (final unit in 'esel|${date.key}'.codeUnits) {
      state = (state * 31 + unit) % _modulus;
    }
    if (state == 0) state = 1;
    final pool = [...EselPaints.order];
    final picked = <EselPaint>[];
    for (var i = 0; i < count; i++) {
      state = state * 48271 % _modulus; // Park–Miller
      picked.add(pool.removeAt(state % pool.length));
    }
    return List.unmodifiable(picked);
  }
}
