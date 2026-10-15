import 'dart:math';

enum SameColorRoomAccess {
  open,    // 완전 공개 (내 호 발행 완료 또는 타인 색상)
  preview, // 3장 미리보기 + 흐린 책등 (발행 전 내 색상)
  closed,  // 닫힘
}

class SameColorPreviewResult {
  final SameColorRoomAccess access;
  final List<String> visibleCoverIds;
  final int hiddenCount;
  final String? bannerMessage;

  const SameColorPreviewResult({
    required this.access,
    required this.visibleCoverIds,
    required this.hiddenCount,
    this.bannerMessage,
  });
}

/// P01, P02 같은 색 방 공개 규칙
class SameColorRule {
  static const int maxPreviewCount = 3;

  static SameColorPreviewResult evaluateRoom({
    required String roomColorKey,
    required String mySelectedColorKey,
    required bool hasPublishedToday,
    required List<String> allCoverIdsInRoom,
  }) {
    final isMyColor = roomColorKey == mySelectedColorKey;

    if (!isMyColor || hasPublishedToday) {
      return SameColorPreviewResult(
        access: SameColorRoomAccess.open,
        visibleCoverIds: allCoverIdsInRoom,
        hiddenCount: 0,
      );
    }

    // 발행 전 내 색상: 최신 3장만 노출, 나머지는 hiddenCount로 격리
    final visibleCount = min(maxPreviewCount, allCoverIdsInRoom.length);
    final visibleList = allCoverIdsInRoom.take(visibleCount).toList();
    final hidden = max(0, allCoverIdsInRoom.length - visibleCount);

    return SameColorPreviewResult(
      access: SameColorRoomAccess.preview,
      visibleCoverIds: visibleList,
      hiddenCount: hidden,
      bannerMessage: '발행하면 함께 펼쳐집니다',
    );
  }
}
