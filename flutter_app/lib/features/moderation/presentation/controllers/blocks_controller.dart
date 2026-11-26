import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../data/blocks_source.dart';
import '../../domain/blocked_user.dart';

export '../../domain/blocked_user.dart' show BlockedUser;

/// 차단 상태(DEV-20). 차단 목록은 [BlocksSource]에서만 받고, 실패해도 다른 자료로 채우지 않는다.
/// 차단하거나 풀면 [onChanged]를 불러 피드·팔레트를 다시 읽게 한다(서버가 거른 결과를 받기 위해).
class BlocksController extends ChangeNotifier {
  final BlocksSource source;
  final VoidCallback? onChanged;

  BlocksController(this.source, {this.onChanged});

  List<BlockedUser> _items = const [];
  String? _cursor;
  bool _loading = false, _loadingMore = false, _loaded = false;
  String? _error, _moreError;
  final Set<String> _busy = {};
  String? _ownerId;

  // 숫자 셋을 나눠 쓴다(친구 #44 리뷰와 같은 문제).
  // - _account: 계정이 바뀔 때만 올린다. 이전 계정의 응답은 무엇이든 버린다.
  // - _loadRequest: 목록을 다시 읽을 때 올린다. 늦게 온 이전 읽기 응답만 버린다.
  // - _moreRequest: 더 보기마다, 그리고 다시 읽기가 시작될 때 올린다.
  // 차단·풀기는 계정만 비교한다. 서버가 이미 처리했으므로 다시 읽기 중이어도 결과를 반영한다.
  int _account = 0, _loadRequest = 0, _moreRequest = 0;

  List<BlockedUser> get items => List.unmodifiable(_items);
  bool get isLoading => _loading;
  bool get isLoadingMore => _loadingMore;
  bool get hasLoaded => _loaded;
  bool get hasMore => _cursor != null;
  String? get errorMessage => _error;
  String? get moreError => _moreError;

  /// 차단·풀기를 처리 중인 사인. 그동안 같은 사람의 버튼을 막는다.
  bool isBusy(String masthead) => _busy.contains(masthead);

  /// 지금 계정. 바뀌면 이전 계정의 목록과 늦게 온 응답을 버린다. 알림은 보내지 않는다.
  void configure(String? ownerId) {
    if (ownerId == _ownerId) return;
    _reset();
    _ownerId = ownerId;
  }

  void clear() {
    _reset();
    notifyListeners();
  }

  void _reset() {
    _account++;
    _loadRequest++;
    _moreRequest++;
    _items = const [];
    _cursor = null;
    _loading = false;
    _loadingMore = false;
    _loaded = false;
    _error = null;
    _moreError = null;
    _busy.clear();
    _ownerId = null;
  }

  /// 차단 목록 첫 페이지를 다시 읽는다.
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
      final page = await source.page();
      if (!current()) return;
      _items = page.items;
      _cursor = page.nextCursor;
      _loaded = true;
    } catch (failure) {
      if (!current()) return;
      _error = failure is Failure
          ? failure.message
          : '차단한 사람을 불러오지 못했어요. 다시 시도해 주세요.';
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    final cursor = _cursor;
    if (_loading || _loadingMore || cursor == null) return;
    final more = ++_moreRequest;
    _loadingMore = true;
    _moreError = null;
    notifyListeners();
    // 계정 전환이나 다시 읽기가 끼어들면 응답을 버리되, _loadingMore는 끼어든 쪽이 이미 풀었다.
    bool current() => more == _moreRequest;
    try {
      final page = await source.page(cursor: cursor);
      if (!current()) return;
      _items = {
        for (final b in [..._items, ...page.items]) b.masthead: b,
      }.values.toList();
      _cursor = page.nextCursor;
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

  /// 차단하기. 성공하면 null, 실패하면 안내 문구. 서버가 답한 뒤에만 차단됐다고 본다.
  Future<String?> block(String masthead) => _act(masthead, blocking: true);

  /// 차단 풀기. 성공하면 null, 실패하면 안내 문구.
  Future<String?> unblock(String masthead) => _act(masthead, blocking: false);

  Future<String?> _act(String masthead, {required bool blocking}) async {
    if (_busy.contains(masthead)) return null;
    // 계정만 비교한다. 다시 읽기가 끼어들어도 서버는 이미 처리했으므로 결과를 반영한다.
    final account = _account;
    _busy.add(masthead);
    notifyListeners();
    String? message;
    var applied = false;
    try {
      if (blocking) {
        await source.block(masthead);
      } else {
        await source.unblock(masthead);
      }
      if (account == _account) {
        if (blocking) {
          _items = [
            BlockedUser(masthead: masthead, blockedAt: DateTime.now()),
            ..._items.where((b) => b.masthead != masthead),
          ];
        } else {
          _items = [..._items.where((b) => b.masthead != masthead)];
        }
        applied = true;
      }
    } catch (failure) {
      if (account == _account) {
        message = blockFailureMessage(failure, blocking: blocking);
      }
    } finally {
      // 계정이 바뀌었으면 _reset이 이미 비웠다.
      if (account == _account) {
        _busy.remove(masthead);
        notifyListeners();
      }
    }
    if (applied) onChanged?.call();
    return message;
  }
}
