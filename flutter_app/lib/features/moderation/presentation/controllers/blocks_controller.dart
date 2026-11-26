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
  int _request = 0;

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
    _request++;
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
    final request = ++_request;
    _loading = true;
    _error = null;
    _moreError = null;
    notifyListeners();
    try {
      final page = await source.page();
      if (request != _request) return;
      _items = page.items;
      _cursor = page.nextCursor;
      _loaded = true;
    } catch (failure) {
      if (request != _request) return;
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
    final request = _request;
    _loadingMore = true;
    _moreError = null;
    notifyListeners();
    try {
      final page = await source.page(cursor: cursor);
      if (request != _request) return;
      _items = {
        for (final b in [..._items, ...page.items]) b.masthead: b,
      }.values.toList();
      _cursor = page.nextCursor;
    } catch (failure) {
      if (request != _request) return;
      _moreError = failure is Failure
          ? failure.message
          : '더 불러오지 못했어요. 다시 시도해 주세요.';
    }
    _loadingMore = false;
    notifyListeners();
  }

  /// 차단하기. 성공하면 null, 실패하면 안내 문구. 서버가 답한 뒤에만 차단됐다고 본다.
  Future<String?> block(String masthead) => _act(masthead, blocking: true);

  /// 차단 풀기. 성공하면 null, 실패하면 안내 문구.
  Future<String?> unblock(String masthead) => _act(masthead, blocking: false);

  Future<String?> _act(String masthead, {required bool blocking}) async {
    if (_busy.contains(masthead)) return null;
    final request = _request;
    _busy.add(masthead);
    notifyListeners();
    String? message;
    try {
      if (blocking) {
        await source.block(masthead);
      } else {
        await source.unblock(masthead);
      }
      if (request != _request) return null;
      if (blocking) {
        _items = [
          BlockedUser(masthead: masthead, blockedAt: DateTime.now()),
          ..._items.where((b) => b.masthead != masthead),
        ];
      } else {
        _items = [..._items.where((b) => b.masthead != masthead)];
      }
    } catch (failure) {
      if (request != _request) return null;
      message = blockFailureMessage(failure, blocking: blocking);
    }
    _busy.remove(masthead);
    notifyListeners();
    if (message == null) onChanged?.call();
    return message;
  }
}
