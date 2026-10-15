import '../../../../core/design/tokens.g.dart';
import '../../../../core/time/service_date.dart';

enum SameColorRoomAccess {
  open, // 전부 공개
  preview, // 최신 3장 + 나머지는 개수만(흐린 책등)
  closed, // 미래·잘못된 날짜
}

/// 같은 색 방을 보는 사람의 오늘 상태(P01).
///
/// 2026-10-15 결정: 발행 전에는 그날 나의 후보 3색 방이 모두 미리보기다. 그중 무엇을 골랐는지,
/// 몇 번 바꿨는지는 넣지 않는다. 그래서 색을 바꿔도 어떤 방도 열리지 않는다.
class SameColorViewer {
  /// 서비스 날짜(Asia/Seoul).
  final ServiceDate today;

  /// 오늘 나의 후보 3색(P17).
  final List<EselPaint> candidates;

  /// 오늘 나의 개인 발행이 있는지. 색 확정·복원·트윈 게시는 여기에 넣지 않는다(P03, P09).
  final bool hasPublishedToday;

  /// 미성년자는 잠금이 없다.
  final bool isMinor;

  const SameColorViewer({
    required this.today,
    required this.candidates,
    required this.hasPublishedToday,
    required this.isMinor,
  });

  /// 비로그인 독자. 후보가 없어 잠긴 방이 없고, 대신 피드는 2쪽까지만 받는다(P12).
  const SameColorViewer.reader(this.today)
    : candidates = const [],
      hasPublishedToday = false,
      isMinor = false;
}

/// 방에 꽂힌 표지 하나. 규칙은 id와 발행 시각만 본다.
class RoomCover {
  final String id;
  final DateTime publishedAt;

  const RoomCover({required this.id, required this.publishedAt});
}

class SameColorRoom {
  final SameColorRoomAccess access;

  /// 화면에 그려도 되는 표지 id(최신순).
  final List<String> visibleCoverIds;

  /// 이름·사진 없이 개수만 알리는 표지 수.
  final int hiddenCount;

  const SameColorRoom({
    required this.access,
    required this.visibleCoverIds,
    required this.hiddenCount,
  });

  /// 같은 색 인원(공개 숫자, P18).
  int get total => visibleCoverIds.length + hiddenCount;

  bool get isPreview => access == SameColorRoomAccess.preview;
}

/// P01·P02 같은 색 방 공개 규칙. 기준 구현은 social-state.js의 sameColorRoom.
class SameColorRule {
  static const int previewCount = 3;
  static const String bannerMessage = '발행하면 함께 펼쳐집니다';

  static SameColorRoomAccess accessFor({
    required EselPaint color,
    required ServiceDate date,
    required SameColorViewer viewer,
  }) {
    if (date.isAfter(viewer.today)) return SameColorRoomAccess.closed;
    if (date.isBefore(viewer.today)) return SameColorRoomAccess.open;
    if (viewer.isMinor || viewer.hasPublishedToday) {
      return SameColorRoomAccess.open;
    }
    return viewer.candidates.contains(color)
        ? SameColorRoomAccess.preview
        : SameColorRoomAccess.open;
  }

  /// 가판대 칩의 자물쇠. 오늘 발행 전, 나의 후보 3색에 모두 붙는다.
  static bool isLockedToday(EselPaint color, SameColorViewer viewer) =>
      accessFor(color: color, date: viewer.today, viewer: viewer) ==
      SameColorRoomAccess.preview;

  static SameColorRoom evaluateRoom({
    required EselPaint color,
    required ServiceDate date,
    required SameColorViewer viewer,
    required List<RoomCover> covers,
  }) {
    final access = accessFor(color: color, date: date, viewer: viewer);
    final newest = [...covers]
      ..sort((a, b) {
        final byTime = b.publishedAt.compareTo(a.publishedAt);
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });
    final shown = switch (access) {
      SameColorRoomAccess.open => newest,
      SameColorRoomAccess.preview => newest.take(previewCount).toList(),
      SameColorRoomAccess.closed => const <RoomCover>[],
    };
    return SameColorRoom(
      access: access,
      visibleCoverIds: shown.map((c) => c.id).toList(),
      hiddenCount: newest.length - shown.length,
    );
  }
}
