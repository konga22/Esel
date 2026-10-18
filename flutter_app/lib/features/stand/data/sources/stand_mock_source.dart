import '../../../../core/design/tokens.g.dart';
import '../../../../core/time/service_date.dart';
import '../../../drafts/data/local_library.dart';
import '../../../issue/data/demo_issue_catalog.dart';
import '../../../issue/domain/models/public_issue.dart';
import '../../domain/models/stand_shelf.dart';
import '../../domain/rules/same_color_rule.dart';
import 'stand_source.dart';

/// 시연 팔레트: 예시 인물의 오늘 표지 + 이 기기에서 내가 오늘 낸 호.
class StandMockSource implements StandSource {
  final LocalLibrary? Function() _library;

  StandMockSource({LocalLibrary? Function()? library})
    : _library = library ?? (() => null);

  List<PublicIssue> _coversOn(ServiceDate date, String? viewerId) {
    final covers = DemoIssueCatalog.issuesOn(date);
    final library = _library();
    if (viewerId != null && library != null) {
      for (final issue in library.issuesFor(viewerId)) {
        if (issue.publishedOn == date.key) {
          covers.add(DemoIssueCatalog.fromLocal(issue));
        }
      }
    }
    return covers;
  }

  @override
  Future<StandShelf> shelf({
    required SameColorViewer viewer,
    String? viewerId,
    EselPaint? color,
  }) async {
    final covers = _coversOn(viewer.today, viewerId);
    if (color == null) {
      // 전체에는 열린 방의 표지만 꽂는다. 잠긴 방은 그 색 칩에서 3장만 본다.
      final open =
          covers
              .where(
                (item) =>
                    SameColorRule.accessFor(
                      color: item.color,
                      date: item.date,
                      viewer: viewer,
                    ) ==
                    SameColorRoomAccess.open,
              )
              .toList()
            ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      return StandShelf(
        color: null,
        access: SameColorRoomAccess.open,
        items: open,
        hiddenCount: 0,
      );
    }
    final inRoom = covers.where((item) => item.color == color).toList();
    final room = SameColorRule.evaluateRoom(
      color: color,
      date: viewer.today,
      viewer: viewer,
      covers: [
        for (final item in inRoom)
          RoomCover(id: item.id, publishedAt: item.publishedAt),
      ],
    );
    final byId = {for (final item in inRoom) item.id: item};
    return StandShelf(
      color: color,
      access: room.access,
      items: [for (final id in room.visibleCoverIds) byId[id]!],
      hiddenCount: room.hiddenCount,
    );
  }

  @override
  Future<int> sameColorCount(ServiceDate date, EselPaint color) async =>
      DemoIssueCatalog.issuesOn(date).where((i) => i.color == color).length;
}
