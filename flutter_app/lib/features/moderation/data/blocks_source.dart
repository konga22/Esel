import '../../../core/network/http_client.dart';
import '../domain/blocked_user.dart';

/// 차단하기·풀기·차단 목록(DEV-20). `ESEL_API_MODE`에 따라 [BlocksMemorySource] 또는
/// [BlocksRemoteSource]를 쓴다.
abstract interface class BlocksSource {
  Future<void> block(String masthead);
  Future<void> unblock(String masthead);
  Future<BlockedUsersPage> page({String? cursor});
}

/// mock(시연) 모드. 차단한 사람 목록만 앱 메모리에 담는다.
/// 시연 피드·팔레트는 이 목록으로 거르지 않으므로 화면은 그대로다.
class BlocksMemorySource implements BlocksSource {
  final List<BlockedUser> _items = [];

  @override
  Future<void> block(String masthead) async {
    _items.removeWhere((b) => b.masthead == masthead);
    _items.insert(
      0,
      BlockedUser(masthead: masthead, blockedAt: DateTime.now()),
    );
  }

  @override
  Future<void> unblock(String masthead) async {
    _items.removeWhere((b) => b.masthead == masthead);
  }

  @override
  Future<BlockedUsersPage> page({String? cursor}) async =>
      BlockedUsersPage(List.of(_items));
}

/// 서버 모드. 경로·오류는 `server/api-contract.json`의 moderation 묶음을 따른다.
/// 차단하면 서버가 그 사람의 캔버스·한 줄을 피드·팔레트·스케치북·저장함에서 뺀다.
class BlocksRemoteSource implements BlocksSource {
  final AppHttpClient http;

  BlocksRemoteSource(this.http);

  String _path(String masthead) =>
      '/users/${Uri.encodeComponent(masthead)}/block';

  @override
  Future<void> block(String masthead) async {
    await http.post(_path(masthead));
  }

  @override
  Future<void> unblock(String masthead) async {
    await http.delete(_path(masthead));
  }

  @override
  Future<BlockedUsersPage> page({String? cursor}) async {
    final data = await http.get('/me/blocks', queryParams: {'cursor': ?cursor});
    return BlockedUsersPage([
      for (final v in data['items'] as List)
        BlockedUser(
          masthead: (v as Map)['masthead'] as String,
          blockedAt: DateTime.tryParse(v['blockedAt'] as String? ?? ''),
        ),
    ], data['nextCursor'] as String?);
  }
}
