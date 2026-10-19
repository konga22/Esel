import '../../../auth/domain/models/auth_session.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/network/http_client.dart';
import '../../../../core/time/service_date.dart';
import '../../../issue/data/sources/issue_remote_source.dart';
import '../../../issue/domain/models/public_issue.dart';
import '../../../stand/domain/rules/same_color_rule.dart';
import '../../domain/models/feed_page.dart';
import 'feed_source.dart';

/// 서버 피드(DEV-10). 공개 권한(P01)은 서버가 먼저 거르므로 다시 고르지 않는다.
/// 로그인: `GET /feed` → `{items: [IssuePublicDto + source], nextCursor}`.
/// 비로그인: `GET /today/cover` → `{serviceDate, cover, pages}`(표지와 안쪽 2쪽, P12).
class FeedRemoteSource implements FeedSource {
  final AppHttpClient http;

  final AuthSession? Function()? currentSession;
  FeedRemoteSource(this.http, {this.currentSession});

  @override
  Future<FeedPage> today({
    required SameColorViewer viewer,
    required bool signedIn,
    FeedTab tab = FeedTab.all,
    Set<String> subscribedOwnerIds = const {},
  }) async {
    if (!signedIn) {
      final data = await http.get('/today/cover');
      final date =
          ServiceDate.tryParse(data['serviceDate'] as String?) ?? viewer.today;
      return FeedPage(
        date: date,
        appIssueNumber: date.dayOfYear,
        issues: [
          if (data['cover'] case final Map cover) _issue(cover, date),
          for (final page in data['pages'] as List? ?? const [])
            _issue(page as Map, date),
        ],
      );
    }
    // 같은 색 인원은 피드와 함께 받기 시작하되 실패를 밖으로 내지 않는다. 피드 오류는 그대로
    // Failure로 올라가 화면이 안내한다.
    final counts = _sameColorCounts();
    final feed = await http.get('/feed');
    final items = [
      for (final value in feed['items'] as List)
        if (tab == FeedTab.all || (value as Map)['source'] == 'SUBSCRIPTION')
          _issue(value as Map, viewer.today),
    ];
    return FeedPage(
      date: viewer.today,
      appIssueNumber: viewer.today.dayOfYear,
      issues: items,
      // 서버는 올리기 전 후보 3색 표지를 피드에서 뺀다(P01). 그때 안내를 한 번 넣는다.
      heldBack: !viewer.hasPublishedToday && !viewer.isMinor,
      sameColorCounts: await counts,
    );
  }

  PublicIssue _issue(Map value, ServiceDate date) => serverIssueToPublic(
    parseServerIssue(Map<String, dynamic>.from(value), date: date),
    viewer: currentSession?.call(),
  );

  /// 색별 같은 색 인원(공개 숫자, P18). 서버 `/palette/colors` 항목에 `count`가 있을 때만 채운다.
  /// 아직 없으면 빈 값이고, 화면은 숫자 없이 색 이름만 보인다. 실패해도 피드는 그대로 보인다.
  Future<Map<EselPaint, int>> _sameColorCounts() async {
    try {
      final data = await http.get('/palette/colors');
      return {
        for (final value in data['items'] as List? ?? const [])
          if ((value as Map)['count'] case final int count)
            EselPaint.values.byName(value['id'] as String): count,
      };
    } catch (_) {
      return const {};
    }
  }
}
