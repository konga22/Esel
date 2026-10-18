import '../../../../core/design/tokens.g.dart';
import '../../../../core/time/service_date.dart';
import '../../domain/models/stand_shelf.dart';
import '../../domain/rules/same_color_rule.dart';

/// 팔레트를 받는 곳(DEV-03). 공개 권한은 받는 쪽(서버·mock)이 먼저 적용한다.
abstract class StandSource {
  /// [color]가 null이면 전체 칸. 잠긴 방은 최신 3장과 hiddenCount만 준다.
  Future<StandShelf> shelf({
    required SameColorViewer viewer,
    String? viewerId,
    EselPaint? color,
  });

  /// 그날 그 색으로 올린 사람 수(공개 숫자).
  Future<int> sameColorCount(ServiceDate date, EselPaint color);
}
