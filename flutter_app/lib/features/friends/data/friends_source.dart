import '../../../core/network/http_client.dart';
import '../domain/friend.dart';

/// 친구 목록·받은 요청·요청 보내기·수락·나중에(DEV-16).
/// `ESEL_API_MODE`에 따라 [FriendsMockSource] 또는 [FriendsRemoteSource]를 쓴다.
abstract interface class FriendsSource {
  Future<FriendsPage<FriendItem>> friends({String? cursor});
  Future<FriendsPage<FriendRequestItem>> requests({String? cursor});
  Future<void> sendRequest(String masthead);
  Future<FriendItem> accept(FriendRequestItem request);
  Future<void> decline(String requestId);
}

/// mock(시연) 모드. 기존 친구 화면의 예시 친구·요청을 앱 메모리에 둔다.
class FriendsMockSource implements FriendsSource {
  final List<FriendItem> _friends = [
    const FriendItem(
      id: 'friend_1',
      masthead: 'elin',
      bio: '라탄 의자, 세이지 셋업. 일요일 오전.',
      photoAsset: 'assets/models/sage-01.jpg',
    ),
    const FriendItem(
      id: 'friend_2',
      masthead: 'ama',
      bio: '노란 셋업에 은색 가방 하나.',
      photoAsset: 'assets/models/butter-01.jpg',
    ),
  ];

  final List<FriendRequestItem> _requests = [
    const FriendRequestItem(
      id: 'req_1',
      fromMasthead: 'kofi',
      photoAsset: 'assets/models/olive-01.jpg',
    ),
  ];

  @override
  Future<FriendsPage<FriendItem>> friends({String? cursor}) async =>
      FriendsPage(List.of(_friends));

  @override
  Future<FriendsPage<FriendRequestItem>> requests({String? cursor}) async =>
      FriendsPage(List.of(_requests));

  /// 시연에는 상대가 없으므로 보낸 요청은 저장하지 않는다(기존 동작).
  @override
  Future<void> sendRequest(String masthead) async {}

  @override
  Future<FriendItem> accept(FriendRequestItem request) async {
    _requests.removeWhere((r) => r.id == request.id);
    final friend = FriendItem(
      id: 'friend_${request.fromMasthead}',
      masthead: request.fromMasthead,
      bio: '새로운 친구.',
      photoAsset: request.photoAsset,
    );
    _friends.insert(0, friend);
    return friend;
  }

  @override
  Future<void> decline(String requestId) async {
    _requests.removeWhere((r) => r.id == requestId);
  }
}

/// 서버 모드. 경로·오류는 `server/api-contract.json`의 friends 묶음을 따른다.
class FriendsRemoteSource implements FriendsSource {
  final AppHttpClient http;

  FriendsRemoteSource(this.http);

  @override
  Future<FriendsPage<FriendItem>> friends({String? cursor}) async {
    final data = await http.get('/friends', queryParams: {'cursor': ?cursor});
    return FriendsPage([
      for (final v in data['items'] as List)
        _friend(Map<String, dynamic>.from(v as Map)),
    ], data['nextCursor'] as String?);
  }

  @override
  Future<FriendsPage<FriendRequestItem>> requests({String? cursor}) async {
    final data = await http.get(
      '/friends/requests',
      queryParams: {'cursor': ?cursor},
    );
    return FriendsPage([
      for (final v in data['items'] as List)
        FriendRequestItem(
          id: (v as Map)['id'] as String,
          fromMasthead: v['masthead'] as String,
        ),
    ], data['nextCursor'] as String?);
  }

  @override
  Future<void> sendRequest(String masthead) async {
    await http.post('/friends/requests', body: {'masthead': masthead});
  }

  @override
  Future<FriendItem> accept(FriendRequestItem request) async =>
      _friend(await http.post('/friends/requests/${request.id}/accept'));

  @override
  Future<void> decline(String requestId) async {
    await http.post('/friends/requests/$requestId/decline');
  }

  FriendItem _friend(Map<String, dynamic> v) => FriendItem(
    id: v['friendId'] as String,
    masthead: v['masthead'] as String,
    friendsSince: DateTime.tryParse(v['friendsSince'] as String? ?? ''),
  );
}
