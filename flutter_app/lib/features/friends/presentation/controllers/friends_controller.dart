import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../data/friends_source.dart';
import '../../domain/friend.dart';

export '../../domain/friend.dart'
    show FriendItem, FriendRequestItem, normalizeFriendMasthead;

/// 친구 화면 상태(DEV-16). 목록은 [FriendsSource]에서만 받고, 서버가 실패해도 예시로 채우지 않는다.
/// 처음 불러올 때만 빈 로딩을 쓰고, 다시 읽는 동안에는 받은 목록을 유지한다.
/// 계정이 바뀌면 이전 계정 목록과 늦게 온 응답을 버린다.
class FriendsController extends ChangeNotifier {
  final FriendsSource source;

  FriendsController(this.source);

  List<FriendItem> _friends = const [];
  List<FriendRequestItem> _requests = const [];
  String? _friendsCursor, _requestsCursor;
  bool _loading = false, _loaded = false, _loadingMore = false;
  String? _error, _moreError;
  final Set<String> _busy = {};
  String? _ownerId;
  int _request = 0;

  List<FriendItem> get friends => List.unmodifiable(_friends);
  List<FriendRequestItem> get pendingRequests => List.unmodifiable(_requests);
  bool get isLoading => _loading;
  bool get isLoadingMore => _loadingMore;

  /// 한 번이라도 응답을 받았는지. 친구가 없는 것과 아직 모르는 것을 구분한다.
  bool get hasLoaded => _loaded;
  String? get errorMessage => _error;
  String? get moreError => _moreError;
  bool get hasMoreFriends => _friendsCursor != null;
  bool get hasMoreRequests => _requestsCursor != null;

  /// 전체 친구 수를 알 때만 숫자를 준다(마지막 페이지까지 받았을 때). 모르면 null.
  int? get knownFriendCount =>
      _loaded && _friendsCursor == null ? _friends.length : null;

  /// 수락·나중에를 처리 중인 요청. 그동안 같은 요청의 버튼을 막는다.
  bool isBusy(String requestId) => _busy.contains(requestId);

  /// 지금 계정. 바뀌면 이전 계정 상태를 버린다. 화면을 그리는 중에도 부를 수 있게 알리지 않는다.
  void configure(String? ownerId) {
    if (ownerId == _ownerId) return;
    _reset();
    _ownerId = ownerId;
  }

  /// 로그아웃·계정 전환 때 부른다.
  void clear() {
    _reset();
    notifyListeners();
  }

  void _reset() {
    _request++;
    _friends = const [];
    _requests = const [];
    _friendsCursor = null;
    _requestsCursor = null;
    _loading = false;
    _loaded = false;
    _loadingMore = false;
    _error = null;
    _moreError = null;
    _busy.clear();
    _ownerId = null;
  }

  /// 친구 목록과 받은 요청의 첫 페이지를 다시 읽는다.
  Future<void> load() async {
    final request = ++_request;
    _loading = true;
    _error = null;
    _moreError = null;
    notifyListeners();
    try {
      final friends = await source.friends();
      final requests = await source.requests();
      if (request != _request) return;
      _friends = friends.items;
      _friendsCursor = friends.nextCursor;
      _requests = requests.items;
      _requestsCursor = requests.nextCursor;
      _loaded = true;
    } catch (failure) {
      if (request != _request) return;
      _error = failure is Failure
          ? failure.message
          : '친구 목록을 불러오지 못했어요. 다시 시도해 주세요.';
    }
    _loading = false;
    notifyListeners();
  }

  /// 친구 목록 다음 페이지.
  Future<void> loadMoreFriends() => _loadMore(friends: true);

  /// 받은 요청 다음 페이지.
  Future<void> loadMoreRequests() => _loadMore(friends: false);

  Future<void> _loadMore({required bool friends}) async {
    final cursor = friends ? _friendsCursor : _requestsCursor;
    if (_loading || _loadingMore || cursor == null) return;
    final request = _request;
    _loadingMore = true;
    _moreError = null;
    notifyListeners();
    try {
      if (friends) {
        final page = await source.friends(cursor: cursor);
        if (request != _request) return;
        _friends = {
          for (final f in [..._friends, ...page.items]) f.id: f,
        }.values.toList();
        _friendsCursor = page.nextCursor;
      } else {
        final page = await source.requests(cursor: cursor);
        if (request != _request) return;
        _requests = {
          for (final r in [..._requests, ...page.items]) r.id: r,
        }.values.toList();
        _requestsCursor = page.nextCursor;
      }
    } catch (failure) {
      if (request != _request) return;
      _moreError = failure is Failure
          ? failure.message
          : '더 불러오지 못했어요. 다시 시도해 주세요.';
    }
    _loadingMore = false;
    notifyListeners();
  }

  /// 받은 요청 수락. 성공하면 null, 실패하면 안내 문구.
  /// 서버가 응답하기 전에는 친구가 됐다고 보이지 않는다.
  Future<String?> acceptRequest(FriendRequestItem request) =>
      _act(request.id, () async {
        final friend = await source.accept(request);
        return () {
          _requests = [..._requests.where((r) => r.id != request.id)];
          _friends = [friend, ..._friends.where((f) => f.id != friend.id)];
        };
      });

  /// 받은 요청 나중에(서버는 요청을 지운다). 성공하면 null, 실패하면 안내 문구.
  Future<String?> declineRequest(FriendRequestItem request) =>
      _act(request.id, () async {
        await source.decline(request.id);
        return () {
          _requests = [..._requests.where((r) => r.id != request.id)];
        };
      });

  Future<String?> _act(
    String requestId,
    Future<void Function()> Function() run,
  ) async {
    if (_busy.contains(requestId)) return null;
    final request = _request;
    _busy.add(requestId);
    notifyListeners();
    String? message;
    try {
      final apply = await run();
      if (request != _request) return null;
      apply();
    } catch (failure) {
      if (request != _request) return null;
      message = friendRequestActionFailureMessage(failure);
      // 이미 처리된 요청(404)은 목록에서 뺀다. 다른 기기에서 수락했을 수 있다.
      if (failure is Failure && failure.code == 'NOT_FOUND') {
        _requests = [..._requests.where((r) => r.id != requestId)];
      }
    }
    _busy.remove(requestId);
    notifyListeners();
    return message;
  }

  /// 사인으로 친구 요청 보내기. 성공하면 null, 실패하면 안내 문구.
  /// [selfMasthead]는 내 사인(나에게는 요청을 보낼 수 없다).
  Future<String?> sendRequest(String input, {String? selfMasthead}) async {
    final target = normalizeFriendMasthead(input);
    final local = friendRequestError(
      target,
      selfMasthead: selfMasthead,
      friends: _friends.map((f) => f.masthead),
      received: _requests.map((r) => r.fromMasthead),
    );
    if (local != null) return local;
    try {
      await source.sendRequest(target);
      return null;
    } catch (failure) {
      return friendRequestFailureMessage(failure);
    }
  }
}
