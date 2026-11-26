import '../../../core/errors/failures.dart';

/// 내가 차단한 사람(DEV-20). 서버 `BlockedUserDto`는 사인과 차단한 때만 준다.
class BlockedUser {
  final String masthead;
  final DateTime? blockedAt;

  const BlockedUser({required this.masthead, this.blockedAt});
}

/// cursor 페이지. [nextCursor]가 null이면 마지막 페이지다. 서버는 개수를 주지 않는다.
class BlockedUsersPage {
  final List<BlockedUser> items;
  final String? nextCursor;

  const BlockedUsersPage(this.items, [this.nextCursor]);
}

/// 차단하기·풀기 실패 문구.
String blockFailureMessage(Object failure, {required bool blocking}) {
  if (failure is Failure) {
    // 서버는 없는 사인과 나 자신을 모두 404로 답한다.
    if (failure.code == 'NOT_FOUND') return '찾을 수 없는 사람이에요.';
    return failure.message;
  }
  return blocking ? '차단하지 못했어요. 다시 시도해 주세요.' : '차단을 풀지 못했어요. 다시 시도해 주세요.';
}
