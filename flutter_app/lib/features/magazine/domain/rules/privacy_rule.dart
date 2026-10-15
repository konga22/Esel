/// P18 소유자 전용 숫자 격리 규칙:
/// - 좋아요 수, 독자 한 줄 수, 스크랩 수, 읽은 사람 수는 오직 본인(소유자)에게만 표시됨
/// - 타인의 서가, 피드, 공개 API 응답, 공유 링크에는 이 필드가 노출되지 않음
class PrivacyRule {
  static bool shouldExposeReactionCounts({
    required String viewerUserId,
    required String ownerUserId,
  }) {
    return viewerUserId == ownerUserId;
  }
}
