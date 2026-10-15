import '../../../stand/domain/rules/same_color_rule.dart';
import '../../domain/models/feed_page.dart';

/// 표지 피드를 받는 곳. `--dart-define=ESEL_API_MODE`로 mock과 서버 중 하나를 쓴다(DEV-03).
abstract class FeedSource {
  /// 공개 권한(P01·P02)을 먼저 적용한 오늘 피드. 비로그인은 표지와 안쪽 2쪽까지(P12).
  Future<FeedPage> today({
    required SameColorViewer viewer,
    required bool signedIn,
    FeedTab tab = FeedTab.all,
    Set<String> subscribedOwnerIds = const {},
  });
}
