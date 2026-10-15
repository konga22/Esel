/// P04 결호 없는 하루 한 호 발행 규칙. 기기 보관함 발행(LocalLibrary.publish)이 이 규칙을 쓴다.
/// - 발행은 서비스 날짜(Asia/Seoul) 하루에 한 번만. 같은 날 두 번째 발행은 거절
/// - 호수는 발행으로만 1 오른다(결호 없음). 복원·트윈 게시로는 오르지 않는다
class PublishRule {
  static bool canPublishToday({required bool hasPublishedToday}) =>
      !hasPublishedToday;

  /// 지금까지 낸 호 수 다음 호수.
  static int nextIssueNumber(int publishedCount) => publishedCount + 1;

  /// `Nº 001`
  static String formatIssueNumber(int issueNumber) =>
      'Nº ${issueNumber.toString().padLeft(3, '0')}';
}
