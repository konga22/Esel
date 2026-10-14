/// P04 결호 없는 1일 1호 발행 규칙:
/// - 발행은 하루 한 번만 가능 (자정 기준)
/// - 당일 두 번째 발행 시도는 거절됨
/// - 발행 성공 시에만 개인 호수(issue_count)가 1 증가함
/// - 복원(restore)이나 트윈(twin) 게시로는 개인 호수가 증가하지 않음
class PublishRule {
  static bool canPublishToday({
    required bool hasPublishedToday,
    required bool isAccountActive,
  }) {
    if (!isAccountActive) return false;
    return !hasPublishedToday;
  }

  static int calculateNextIssueNumber({
    required int currentIssueCount,
    required bool isPublishingSuccessful,
  }) {
    if (!isPublishingSuccessful) return currentIssueCount;
    return currentIssueCount + 1;
  }

  static String formatIssueNumber(int issueNumber) {
    return 'Nº ${issueNumber.toString().padLeft(3, '0')}';
  }
}
