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

  // 숫자 셋을 나눠 쓴다(#44 리뷰).
  // - _account: 계정이 바뀔 때만 올린다. 이전 계정의 응답은 무엇이든 버린다.
  // - _loadRequest: 목록을 다시 읽을 때 올린다. 늦게 온 이전 읽기 응답만 버린다.
  // - _moreRequest: 더 보기마다, 그리고 다시 읽기가 시작될 때 올린다. 다시 읽기 전에
  //   시작한 더 보기 응답은 새 목록에 섞지 않는다.
  // 수락·나중에는 계정만 비교한다. 서버가 이미 처리했으므로 다시 읽기 중이어도 결과를 반영한다.
  int _account = 0, _loadRequest = 0, _moreRequest = 0;

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
    _account++;
    _loadRequest++;
    _moreRequest++;
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
    final account = _account;
    final request = ++_loadRequest;
    // 진행 중이던 더 보기는 무효로 한다. 그 응답은 새 목록에 섞지 않고, 버튼은 바로 풀린다.
    _moreRequest++;
    _loadingMore = false;
    _loading = true;
    _error = null;
    _moreError = null;
    notifyListeners();
    bool current() => account == _account && request == _loadRequest;
    try {
      final friends = await source.friends();
      final requests = await source.requests();
      if (!current()) return;
      _friends = friends.items;
      _friendsCursor = friends.nextCursor;
      _requests = requests.items;
      _requestsCursor = requests.nextCursor;
      _loaded = true;
    } catch (failure) {
      if (!current()) return;
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
    final more = ++_moreRequest;
    _loadingMore = true;
    _moreError = null;
    notifyListeners();
    // 계정 전환이나 다시 읽기가 끼어들면 _moreRequest가 바뀐다. 그때는 응답을 버리되,
    // _loadingMore는 끼어든 쪽이 이미 풀었으므로 건드리지 않는다(새 더 보기를 막지 않게).
    bool current() => more == _moreRequest;
    try {
      if (friends) {
        final page = await source.friends(cursor: cursor);
        if (!current()) return;
        _friends = {
          for (final f in [..._friends, ...page.items]) f.id: f,
        }.values.toList();
        _friendsCursor = page.nextCursor;
      } else {
        final page = await source.requests(cursor: cursor);
        if (!current()) return;
        _requests = {
          for (final r in [..._requests, ...page.items]) r.id: r,
        }.values.toList();
        _requestsCursor = page.nextCursor;
      }
    } catch (failure) {
      if (!current()) return;
      _moreError = failure is Failure
          ? failure.message
          : '더 불러오지 못했어요. 다시 시도해 주세요.';
    } finally {
      if (current()) {
        _loadingMore = false;
        notifyListeners();
      }
    }
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
    // 계정만 비교한다. 다시 읽기가 끼어들어도 서버는 이미 처리했으므로 결과를 반영한다.
    final account = _account;
    _busy.add(requestId);
    notifyListeners();
    String? message;
    try {
      final apply = await run();
      if (account == _account) apply();
    } catch (failure) {
      if (account == _account) {
        message = friendRequestActionFailureMessage(failure);
        // 이미 처리된 요청(404)은 목록에서 뺀다. 다른 기기에서 수락했을 수 있다.
        if (failure is Failure && failure.code == 'NOT_FOUND') {
          _requests = [..._requests.where((r) => r.id != requestId)];
        }
      }
    } finally {
      // 계정이 바뀌었으면 _reset이 이미 비웠다.
      if (account == _account) {
        _busy.remove(requestId);
        notifyListeners();
      }
    }
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
