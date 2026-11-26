import '../../../core/errors/failures.dart';

/// 친구 한 사람. 서버(`FriendDto`)는 사인·친구 ID·친구가 된 때만 준다.
/// 소개와 사진은 mock 모드 예시에만 있어 비워 둘 수 있다.
class FriendItem {
  /// 서버의 `friendId`(트윈 초대에 쓰는 상대 사용자 ID). mock은 예시 ID.
  final String id;
  final String masthead;
  final String? bio;
  final String? photoAsset;
  final DateTime? friendsSince;

  const FriendItem({
    required this.id,
    required this.masthead,
    this.bio,
    this.photoAsset,
    this.friendsSince,
  });
}

/// 받은 친구 요청. 서버(`FriendRequestDto`)는 요청 ID와 보낸 사람 사인만 준다.
class FriendRequestItem {
  final String id;
  final String fromMasthead;
  final String? photoAsset;

  const FriendRequestItem({
    required this.id,
    required this.fromMasthead,
    this.photoAsset,
  });
}

/// cursor 페이지. [nextCursor]가 null이면 마지막 페이지다.
class FriendsPage<T> {
  final List<T> items;
  final String? nextCursor;

  const FriendsPage(this.items, [this.nextCursor]);
}

/// 서버 `FriendRequestCreateDto`와 같은 사인 규칙(P14, 영문 소문자 2~10자).
final _mastheadPattern = RegExp(r'^[a-z]{2,10}$');

/// 입력한 사인을 서버에 보낼 모양으로. 앞뒤 공백을 빼고 소문자로 바꾼다.
String normalizeFriendMasthead(String input) => input.trim().toLowerCase();

/// 요청을 보내기 전에 앱에서 거르는 것. null이면 보내도 된다.
/// [received]에 있는 사람은 이미 나에게 요청을 보냈으므로 새 요청 대신 수락을 안내한다
/// (서버는 두 사람 사이 요청을 하나만 두어 새 요청을 409로 막는다).
String? friendRequestError(
  String target, {
  String? selfMasthead,
  Iterable<String> friends = const [],
  Iterable<String> received = const [],
}) {
  if (target.isEmpty) return '친구의 사인을 입력해 주세요.';
  if (!_mastheadPattern.hasMatch(target)) {
    return '사인은 영문 소문자 2~10자예요. 철자를 확인해 주세요.';
  }
  if (target == selfMasthead) return '내 사인에는 친구 요청을 보낼 수 없어요.';
  if (friends.contains(target)) return '이미 친구예요.';
  if (received.contains(target)) {
    return '$target 님이 이미 요청을 보냈어요. 받은 친구 요청에서 수락해 주세요.';
  }
  return null;
}

/// 친구 요청 보내기(`POST /friends/requests`) 실패 문구.
String friendRequestFailureMessage(Object failure) {
  if (failure is Failure) {
    switch (failure.code) {
      case 'NOT_FOUND':
        return '찾지 못했어요. 사인 철자를 확인해 주세요.';
      case 'ALREADY_FRIENDS':
        return '이미 친구예요.';
      case 'REQUEST_EXISTS':
        // 서버는 보낸 요청과 받은 요청을 구분하지 않고 두 사람 사이 요청 하나만 둔다.
        return '두 사람 사이에 이미 요청이 있어요. 받은 친구 요청을 확인하거나 상대의 답을 기다려 주세요.';
      case 'VALIDATION':
        return '사인은 영문 소문자 2~10자예요. 철자를 확인해 주세요.';
    }
    return failure.message;
  }
  return '친구 요청을 보내지 못했어요. 다시 시도해 주세요.';
}

/// 받은 요청 수락·나중에 실패 문구.
String friendRequestActionFailureMessage(Object failure) {
  if (failure is Failure) {
    if (failure.code == 'NOT_FOUND') {
      return '이미 처리했거나 취소된 요청이에요.';
    }
    return failure.message;
  }
  return '요청을 처리하지 못했어요. 다시 시도해 주세요.';
}
