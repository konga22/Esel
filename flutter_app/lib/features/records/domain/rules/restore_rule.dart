/// P06, P07 월 2회 빈 날짜 복원 규칙:
/// - 이번 달 지난 빈 날짜만 복원 가능
/// - 미래 날짜, 오늘, 다른 달, 이미 기록된 날짜는 복원 불가
/// - 월 최대 2회 제한 (3회째 시도는 거절됨)
/// - 복원은 오직 내 달력 기록용이며, 발행 호수(issue_count)나 피드, 같은 색 방에는 영향을 주지 않음
class RestoreRule {
  static const int maxMonthlyRestores = 2;

  static bool canRestoreDate({
    required DateTime targetDate,
    required DateTime currentDate,
    required bool isAlreadyRecorded,
    required int usedRestoreCountThisMonth,
  }) {
    // 1. 월 2회 한도 초과 검사
    if (usedRestoreCountThisMonth >= maxMonthlyRestores) {
      return false;
    }

    // 2. 이미 기록된 날짜 검사
    if (isAlreadyRecorded) {
      return false;
    }

    // 3. 같은 달 검사
    if (targetDate.year != currentDate.year ||
        targetDate.month != currentDate.month) {
      return false;
    }

    // 4. 지난 날짜인지 검사 (오늘 포함 미래는 복원 불가)
    final isPast = targetDate.isBefore(
      DateTime(currentDate.year, currentDate.month, currentDate.day),
    );
    return isPast;
  }

  static String? getRestoreDenialReason({
    required DateTime targetDate,
    required DateTime currentDate,
    required bool isAlreadyRecorded,
    required int usedRestoreCountThisMonth,
  }) {
    if (usedRestoreCountThisMonth >= maxMonthlyRestores) {
      return '이번 달 복원 가능 횟수(2회)를 모두 사용하셨습니다.';
    }
    if (isAlreadyRecorded) {
      return '이미 색이 기록된 날짜입니다.';
    }
    if (targetDate.year != currentDate.year ||
        targetDate.month != currentDate.month) {
      return '이번 달의 날짜만 복원할 수 있습니다.';
    }
    final isPast = targetDate.isBefore(
      DateTime(currentDate.year, currentDate.month, currentDate.day),
    );
    if (!isPast) {
      return '지난 날짜만 복원할 수 있습니다.';
    }
    return null;
  }
}
