import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../../issue/data/sources/issue_remote_source.dart';
import '../../../issue/domain/models/public_issue.dart';
import '../../data/sources/scraps_remote_source.dart';

/// 서버 모드 저장함 상태. 목록은 [ScrapsRemoteSource]에서만 받고, 실패해도 기기 예시로 채우지 않는다.
/// 처음 불러올 때만 빈 로딩을 쓰고, 다시 읽는 동안에는 받은 목록을 유지한다.
class ScrapsController extends ChangeNotifier {
  final ScrapsRemoteSource source;

  ScrapsController(this.source);

  List<PublicIssue> _items = const [];
  String? _nextCursor;
  bool _loading = false, _loadingMore = false, _loaded = false;
  String? _error, _moreError;
  String? _ownerId, _masthead;
  int _request = 0;

  List<PublicIssue> get items => _items;
  String? get nextCursor => _nextCursor;
  bool get isLoading => _loading;
  bool get isLoadingMore => _loadingMore;

  /// 한 번이라도 응답을 받았는지. 빈 저장함과 아직 모르는 상태를 구분한다.
  bool get hasLoaded => _loaded;
  String? get errorMessage => _error;
  String? get moreError => _moreError;

  /// 지금 계정. 바뀌면 이전 계정의 목록과 대기 중인 응답을 버린다.
  /// 화면을 그리는 중에도 부를 수 있도록 알림은 보내지 않는다(다음 [load]가 알린다).
  void configure({required String ownerId, required String masthead}) {
    if (ownerId == _ownerId && masthead == _masthead) return;
    _reset();
    _ownerId = ownerId;
    _masthead = masthead;
  }

  /// 로그아웃·계정 전환 때 부른다.
  void clear() {
    _reset();
    notifyListeners();
  }

  void _reset() {
    _request++;
    _items = const [];
    _nextCursor = null;
    _loading = false;
    _loadingMore = false;
    _loaded = false;
    _error = null;
    _moreError = null;
    _ownerId = null;
    _masthead = null;
  }

  Future<void> load({bool more = false}) async {
    if (_ownerId == null) return;
    if (more && (_loading || _loadingMore || _nextCursor == null)) return;
    final request = ++_request;
    _loading = !more;
    _loadingMore = more;
    _moreError = null;
    if (!more) _error = null;
    notifyListeners();
    try {
      final page = await source.page(cursor: more ? _nextCursor : null);
      if (request != _request) return;
      final received = [
        for (final value in page.items)
          serverIssueToPublic(
            value,
            // 남의 캔버스는 서버가 사용자 ID를 주지 않아 사인으로 스케치북을 연다.
            ownerId: value.masthead == _masthead ? _ownerId : null,
          ),
      ];
      _items = more
          ? {
              for (final v in [..._items, ...received]) v.id: v,
            }.values.toList()
          : received;
      _nextCursor = page.nextCursor;
      _loaded = true;
    } catch (failure) {
      if (request != _request) return;
      final message = failure is Failure
          ? failure.message
          : '저장함을 불러오지 못했어요. 다시 시도해 주세요.';
      if (more) {
        _moreError = message;
      } else {
        _error = message;
      }
    }
    _loading = false;
    _loadingMore = false;
    notifyListeners();
  }
}
