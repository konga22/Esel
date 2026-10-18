import '../../../issue/data/demo_issue_catalog.dart';
import '../../../issue/domain/models/public_issue.dart';
import '../../../stand/domain/rules/same_color_rule.dart';
import '../../domain/models/feed_page.dart';
import 'feed_source.dart';

/// 시연 피드. 서버가 할 일(공개 권한 필터, 비로그인 2쪽 제한)을 똑같이 여기서 한다.
class FeedMockSource implements FeedSource {
  static const int readerInnerPages = 2;

  @override
  Future<FeedPage> today({
    required SameColorViewer viewer,
    required bool signedIn,
    FeedTab tab = FeedTab.all,
    Set<String> subscribedOwnerIds = const {},
  }) async {
    final all = DemoIssueCatalog.issuesOn(viewer.today);
    final byName = {for (final issue in all) issue.masthead: issue};
    final curated = [
      for (final name in DemoIssueCatalog.feedOrder) ?byName[name],
    ];
    final rest =
        all
            .where((i) => !DemoIssueCatalog.feedOrder.contains(i.masthead))
            .toList()
          ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    final ordered = [...curated, ...rest];

    // 잠긴 방(오늘 후보 3색, 올리기 전)의 표지는 피드로도 새지 않게 뺀다(P01).
    final open = ordered.where((issue) => _isOpen(issue, viewer)).toList();
    final heldBack = open.length < ordered.length;

    var shown = tab == FeedTab.subscribed
        ? open.where((i) => subscribedOwnerIds.contains(i.ownerId)).toList()
        : open;
    var forMembers = 0;
    if (!signedIn && shown.length > 1 + readerInnerPages) {
      forMembers = shown.length - 1 - readerInnerPages;
      shown = shown.sublist(0, 1 + readerInnerPages);
    }
    return FeedPage(
      date: viewer.today,
      appIssueNumber: viewer.today.dayOfYear,
      issues: shown,
      heldBack: heldBack,
      pagesForMembers: forMembers,
      sameColorCounts: {
        for (final issue in all)
          issue.color: all.where((i) => i.color == issue.color).length,
      },
    );
  }

  bool _isOpen(PublicIssue issue, SameColorViewer viewer) =>
      SameColorRule.accessFor(
        color: issue.color,
        date: issue.date,
        viewer: viewer,
      ) ==
      SameColorRoomAccess.open;
}
