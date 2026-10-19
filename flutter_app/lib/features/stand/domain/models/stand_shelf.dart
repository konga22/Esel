import '../../../../core/design/tokens.g.dart';
import '../../../issue/domain/models/public_issue.dart';
import '../rules/same_color_rule.dart';

/// 팔레트 한 칸(전체 또는 한 색)을 보는 결과. 잠긴 표지는 이름·사진 없이 개수만 온다(P01).
enum PaletteTab { recommended, colors, subscriptions }

class StandShelf {
  /// null이면 전체.
  final EselPaint? color;
  final SameColorRoomAccess access;
  final List<PublicIssue> items;
  final int hiddenCount;

  /// 서버가 사람마다 한 장으로 이미 골라 준 추천·구독 목록인지. 그러면 앱이 다시 거르지 않는다.
  final bool curated;

  /// 서버가 알려 준 같은 색 인원. 없으면 받은 장수 + 숨긴 수.
  final int? count;

  /// 페이지 일부만 받은 서버 응답을 전체 인원으로 오해하지 않도록 한다.
  final bool countKnown;

  const StandShelf({
    required this.color,
    required this.access,
    required this.items,
    required this.hiddenCount,
    this.curated = false,
    this.count,
    this.countKnown = true,
  });

  bool get isPreview => access == SameColorRoomAccess.preview;

  /// 같은 색 인원(공개 숫자, P18).
  int get total => count ?? items.length + hiddenCount;
}
