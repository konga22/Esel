import '../../../../core/errors/failures.dart';
import '../../../../core/network/http_client.dart';
import '../../../stand/domain/rules/same_color_rule.dart';
import '../../domain/models/feed_page.dart';
import 'feed_source.dart';

/// 서버 피드. 아직 서버가 없어 미구현이다.
/// 초안 API: `GET /api/feed?tab=all|subs&cursor=`(DEV-10), 비로그인 `GET /api/today/cover`(DEV-04).
class FeedRemoteSource implements FeedSource {
  final AppHttpClient http;

  FeedRemoteSource(this.http);

  @override
  Future<FeedPage> today({
    required SameColorViewer viewer,
    required bool signedIn,
    FeedTab tab = FeedTab.all,
    Set<String> subscribedOwnerIds = const {},
  }) async {
    throw const NotImplementedFailure('서버 피드는 아직 연결하지 않았어요.');
  }
}
