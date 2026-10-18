/// P18 소유자 전용 숫자 격리 규칙:
/// - 좋아요 수, 한 줄 수, 스크랩 수, 읽은 사람 수는 오직 본인(소유자)에게만 표시됨
/// - 타인의 스케치북, 피드, 공개 API 응답, 공유 링크에는 이 필드가 노출되지 않음
class PrivacyRule {
  /// 본인 판정은 사인 문자열이 아니라 계정 id로 한다. 로그인하지 않았거나 id가 비면 남이다.
  static bool shouldExposeReactionCounts({
    required String? viewerUserId,
    required String ownerUserId,
  }) {
    if (viewerUserId == null || viewerUserId.isEmpty) return false;
    return viewerUserId == ownerUserId;
  }
}
