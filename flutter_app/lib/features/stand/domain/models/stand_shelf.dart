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

  const StandShelf({
    required this.color,
    required this.access,
    required this.items,
    required this.hiddenCount,
  });

  bool get isPreview => access == SameColorRoomAccess.preview;

  /// 같은 색 인원(공개 숫자, P18).
  int get total => items.length + hiddenCount;
}
