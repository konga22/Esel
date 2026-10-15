import 'package:flutter/foundation.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/mock/demo_people.dart';
import '../../../../core/time/service_date.dart';
import '../../domain/rules/same_color_rule.dart';

/// 가판대에 꽂힌 작은 표지 하나.
class StandItem {
  final String id;
  final String masthead;
  final String photoAsset;
  final EselPaint color;
  final ServiceDate date;
  final DateTime publishedAt;
  final int issueNumber;
  final String caption;

  const StandItem({
    required this.id,
    required this.masthead,
    required this.photoAsset,
    required this.color,
    required this.date,
    required this.publishedAt,
    required this.issueNumber,
    required this.caption,
  });

  String get issueLabel => 'Nº ${issueNumber.toString().padLeft(3, '0')}';
}

/// 가판대 한 칸(전체 또는 한 색)을 보는 결과. 잠긴 표지는 개수만 온다.
class StandShelf {
  /// null이면 전체.
  final EselPaint? color;
  final SameColorRoomAccess access;
  final List<StandItem> items;
  final int hiddenCount;

  const StandShelf({
    required this.color,
    required this.access,
    required this.items,
    required this.hiddenCount,
  });

  bool get isPreview => access == SameColorRoomAccess.preview;

  /// 같은 색 인원(공개 숫자).
  int get total => items.length + hiddenCount;
}

class StandController extends ChangeNotifier {
  final List<StandItem> Function(ServiceDate today) _coversFor;
  EselPaint? _selected;

  StandController({List<StandItem> Function(ServiceDate today)? covers})
    : _coversFor = covers ?? demoStandCovers;

  /// null이면 전체.
  EselPaint? get selected => _selected;

  void select(EselPaint? color) {
    if (_selected == color) return;
    _selected = color;
    notifyListeners();
  }

  /// 그날 그 색으로 발행한 사람 수(같은 색 인원, 공개 숫자 P18).
  int countOn(ServiceDate date, EselPaint color) => _coversFor(
    date,
  ).where((item) => item.date == date && item.color == color).length;

  /// 지금 고른 칸을 [viewer]의 권한으로 본다(P01·P02).
  StandShelf shelfFor(SameColorViewer viewer) {
    final covers = _coversFor(viewer.today);
    final color = _selected;
    if (color == null) {
      // 전체에는 열린 방의 표지만 꽂는다. 잠긴 방의 표지는 그 색 칩에서 3장만 본다.
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
    final inRoom = covers
        .where((item) => item.color == color && item.date == viewer.today)
        .toList();
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
}

/// 시연용 오늘의 표지: 예시 인물 모두가 오늘 그 시각에 발행했다고 둔다.
List<StandItem> demoStandCovers(ServiceDate today) => [
  for (final person in demoPeople)
    StandItem(
      id: '${person.name}-${today.key}',
      masthead: person.name,
      photoAsset: person.photoAsset,
      color: person.color,
      date: today,
      publishedAt: today.startsAt.add(Duration(minutes: person.minuteOfDay)),
      issueNumber: 12 + person.name.codeUnits.fold(0, (a, b) => a + b) % 80,
      caption: person.caption,
    ),
];
